//
//  SignInManager.swift
//  Proton Mail - Created on 18/10/2018.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Services

class SignInManager: Service {
    let usersManager: UsersManager
    let queueHandlerRegister: QueueHandlerRegister
    private var contactCacheStatus: ContactCacheStatusProtocol
    private let updateSwipeAction: UpdateSwipeActionDuringLoginUseCase

    init(usersManager: UsersManager,
         contactCacheStatus: ContactCacheStatusProtocol,
         queueHandlerRegister: QueueHandlerRegister,
         updateSwipeActionUseCase: UpdateSwipeActionDuringLoginUseCase)
    {
        self.usersManager = usersManager
        self.contactCacheStatus = contactCacheStatus
        self.queueHandlerRegister = queueHandlerRegister
        self.updateSwipeAction = updateSwipeActionUseCase
    }

    internal func mailboxPassword(from cleartextPassword: Passphrase, auth: AuthCredential) -> Passphrase {
        var mailboxPassword = cleartextPassword
        if let keysalt = auth.passwordKeySalt, !keysalt.isEmpty {
            let keysalt_byte: Data = keysalt.decodeBase64()
            mailboxPassword = PasswordUtils.getMailboxPassword(cleartextPassword, salt: keysalt_byte)
        }
        return mailboxPassword
    }

    func saveLoginData(loginData: LoginData) -> LoginDataSavingResult {
        let userInfo: UserInfo
        let auth: AuthCredential
        switch loginData {
        case .userData(let userData):
            auth = userData.credential
            userInfo = userData.toUserInfo
        case .credential(let credential):
            assertionFailure("Signin was misconfigured — you should always get full user data. Check minimumAccountType parameter value in LoginAndSignup initializer")
            auth = AuthCredential(credential)
            userInfo = .init(response: [:])
        }

        if self.usersManager.isExist(userID: UserID(rawValue: userInfo.userId)) {
            return .errorOccurred
        }

        guard self.usersManager.isAllowedNewUser(userInfo: userInfo) else {
            return .freeAccountsLimitReached
        }

        if usersManager.count == 0 {
            userCachedStatus.initialUserLoggedInVersion = Bundle.main.majorVersion
            // the schedule intro view is only shown when user updates from old version.
            // Set true here to prevent the intro view is shown after fresh install.
            userCachedStatus.isScheduledSendIntroViewShown = true
        }
        self.usersManager.add(auth: auth, user: userInfo)

        self.usersManager.loggedIn()
        self.usersManager.active(by: auth.sessionID)
        self.contactCacheStatus.contactsCached = 0

        return .success
    }

    func finalizeSignIn(loginData: LoginData,
                        onError: @escaping (NSError) -> Void,
                        reachLimit: () -> Void,
                        existError: () -> Void,
                        showSkeleton: () -> Void,
                        tryUnlock: @escaping () -> Void)
    {
        let userInfo: UserInfo
        let auth: AuthCredential
        switch loginData {
        case .userData(let userData):
            auth = userData.credential
            userInfo = userData.toUserInfo
        case .credential(let credential):
            assertionFailure("Signin was misconfigured — you should always get full user data. Check minimumAccountType parameter value in LoginAndSignup initializer")
            auth = AuthCredential(credential)
            userInfo = .init(response: [:])
        }

        guard let user = usersManager.getUser(by: auth.sessionID),
              let activeUser = usersManager.firstUser else {
            assertionFailure("Signin flow was misconfigured - you should be able to find a user.")
            return
        }

        self.queueHandlerRegister.registerHandler(user.mainQueueHandler)

        showSkeleton()

        let userDataService = user.userService
        userDataService.fetchSettings(userInfo: userInfo, auth: auth).done(on: .main) { [weak self] userInfo in
            guard let self = self else { return }
            self.updateSwipeAction.execute(
                activeUserInfo: activeUser.userInfo,
                newUserInfo: user.userInfo,
                newUserApiService: user.apiService
            ) { [weak self] in
                guard let self = self else { return }
                self.usersManager.update(auth: auth, user: userInfo)

                guard userInfo.delinquentParsed.isAvailable else {
                    self.queueHandlerRegister.unregisterHandler(user.mainQueueHandler)
                    self.usersManager.logout(user: user, shouldShowAccountSwitchAlert: false) {
                        onError(NSError(domain: "", code: 0, localizedDescription: LocalString._general_account_disabled_non_payment))
                    }
                    return
                }

                tryUnlock()

                if UserInfo.isEncryptedSearchEnabled {
                    if let userID = self.usersManager.firstUser?.userinfo.userId {
                        // Automatically build search index for accounts with less than 150 messages
                        EncryptedSearchService.shared.getTotalMessages(userID: userID) {
                            if userCachedStatus.encryptedSearchTotalMessages <= 150 {
                                EncryptedSearchService.shared.forceBuildSearchIndex(userID: userID)
                            }
                        }

                        // Check if previous state was low storage
                        if EncryptedSearchService.shared.getESState(userID: userID) == .lowstorage {
                            // check if there is already enough disk space and restart indexing
                            if EncryptedSearchService.shared.getFreeDiskSpace() > EncryptedSearchService.shared.lowStorageLimit { // 100 MB
                                EncryptedSearchService.shared.restartIndexBuilding(userID: userID)
                            }
                        }
                    }
                }

                NotificationCenter.default.post(name: .fetchPrimaryUserSettings, object: nil)
            }
        }.catch(on: .main) { [weak self] error in
            self?.queueHandlerRegister.unregisterHandler(user.mainQueueHandler)
            _ = self?.usersManager.logout(user: user, completion: {
                onError(error as NSError)
            })
            // this will happen if fetchUserInfo fails - maybe because of connectivity issues
        }
    }
}

extension SignInManager {
    enum LoginDataSavingResult {
        case success
        case freeAccountsLimitReached
        case errorOccurred
    }
}
