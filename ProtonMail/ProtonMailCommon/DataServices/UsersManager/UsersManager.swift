//
//  UsersManager.swift
//  ProtonMail - Created on 8/14/19.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Crypto
import Foundation
import PromiseKit
import ProtonCore_DataModel
import ProtonCore_Doh
import ProtonCore_Keymaker
import ProtonCore_Networking
import ProtonCore_Services
import ProtonMailAnalytics

protocol UsersManagerDelegate: AnyObject {}

/// manager all the users and there services
class UsersManager: Service {
    enum Version: Int {
        static let version: Int = 1 // this is app cache version

        case ver0 = 0
        case ver1 = 1
    }

    // For Migrate protocol
    var latestVersion: Int

    /// saver for versioning
    let versionSaver: Saver<Int>

    enum CoderKey {
        // tracking the cache version added 1.12.0
        static let Version = "Last.Users.Manager.Version"

        // old
        static let keychainStore = "keychainStoreKeyProtectedWithMainKey"
        // new
        static let authKeychainStore = "authKeychainStoreKeyProtectedWithMainKey"
        // old
        static let userInfo = "userInfoKeyProtectedWithMainKey"
        // new
        static let usersInfo = "usersInfoKeyProtectedWithMainKey"

        // new one, check if user logged in already
        static let atLeastOneLoggedIn = "UsersManager.AtLeastoneLoggedIn"

        // set at least one password set
        static let mailboxPassword = "mailboxPasswordKeyProtectedWithMainKey"
        static let username = "usernameKeyProtectedWithMainKey"

        static let twoFAStatus = "twofaKey"
        static let userPasswordMode = "userPasswordModeKey"

        static let disconnectedUsers = "disconnectedUsers"
    }

    /// Server's config like url port path etc..
    var doh: DoH & ServerConfig
    /// the interface for talking to UI
    weak var delegate: UsersManagerDelegate?

    var users: [UserManager] = [] {
        didSet {
            userCachedStatus.primaryUserSessionId = self.users.first?.auth.sessionID
        }
    }

    var firstUser: UserManager? {
        return self.users.first
    }

    var count: Int {
        return self.users.count
    }

    let internetConnectionStatusProvider: InternetConnectionStatusProvider

    // Used to check if the account is already being deleted.
    private(set) var loggingOutUserIDs: Set<UserID> = Set()

    init(doh: DoH & ServerConfig,
         delegate: UsersManagerDelegate?,
         internetConnectionStatusProvider: InternetConnectionStatusProvider = InternetConnectionStatusProvider()) {
        self.doh = doh
        self.doh.status = userCachedStatus.isDohOn ? .on : .off
        self.delegate = delegate
        /// for migrate
        self.latestVersion = Version.version
        self.versionSaver = UserDefaultsSaver<Int>(key: CoderKey.Version)
        self.internetConnectionStatusProvider = internetConnectionStatusProvider
        setupValueTransforms()
    }

    /**
     add a new user after login

     - Parameter auth: auth credential
     - Parameter user: user information
     **/
    func add(auth: AuthCredential, user: UserInfo) {
        self.cleanRandomKeyIfNeeded()
        let session = auth.sessionID
        let apiService = PMAPIService(doh: self.doh, sessionUID: session)
        apiService.serviceDelegate = self
        #if !APP_EXTENSION
        apiService.humanDelegate = HumanVerificationManager.shared.humanCheckHelper(apiService: apiService)
        apiService.forceUpgradeDelegate = ForceUpgradeManager.shared.forceUpgradeHelper
        #endif
        let newUser = UserManager(api: apiService, userinfo: user, auth: auth, parent: self)
        self.add(newUser: newUser)
    }

    func add(newUser: UserManager) {
        newUser.delegate = self
        self.removeDisconnectedUser(.init(defaultDisplayName: newUser.defaultDisplayName,
                                          defaultEmail: newUser.defaultEmail,
                                          userID: newUser.userID.rawValue))
        self.users.append(newUser)

        self.save()
    }

    func isAllowedNewUser(userInfo: UserInfo) -> Bool {
        if numberOfFreeAccounts > 0, !userInfo.isPaid {
            return false
        }
        return true
    }

    func update(auth: AuthCredential, user: UserInfo) {
        for index in 0 ..< self.users.count {
            let usr = self.users[index]
            if usr.isMatch(sessionID: auth.sessionID) {
                usr.update(credential: auth, userInfo: user)
            }
        }

        self.save()
    }

    func user(at index: Int) -> UserManager? {
        return users[safe: index]
    }

    func active(by sessionID: String) {
        guard let index = self.users.firstIndex(where: { $0.isMatch(sessionID: sessionID) }) else {
            return
        }
        let user = self.users.remove(at: index)
        self.users.insert(user, at: 0)
        self.save()
        self.firstUser?.refreshFeatureFlags()
        self.firstUser?.activatePayments()
    }

    func getUser(by sessionID: String) -> UserManager? {
        let found = self.users.filter { user -> Bool in
            user.isMatch(sessionID: sessionID)
        }
        guard let user = found.first else {
            return nil
        }
        return user
    }

    func getUser(by userId: UserID) -> UserManager? {
        let found = self.users.filter { user -> Bool in
            user.userID == userId
        }
        guard let user = found.first else {
            return nil
        }
        return user
    }

    func isExist(userID: UserID) -> Bool {
        return getUser(by: userID) != nil
    }

    // tempery mirgration. will change this to version check
    func hasUserName() -> Bool {
        return SharedCacheBase.getDefault()?.data(forKey: CoderKey.username) != nil
    }

    private func oldUserInfo() -> UserInfo? {
        guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
              let cypherData = SharedCacheBase.getDefault()?.data(forKey: CoderKey.userInfo)
        else {
            return nil
        }

        let locked = Locked<UserInfo>(encryptedValue: cypherData)
        return try? locked.unlock(with: mainKey)
    }

    private func oldAuthFetch() -> AuthCredential? {
        guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
              let encryptedData = KeychainWrapper.keychain.data(forKey: CoderKey.keychainStore),
              case let locked = Locked<Data>(encryptedValue: encryptedData),
              let data = try? locked.unlock(with: mainKey),
              let authCredential = AuthCredential.unarchive(data: data as NSData)
        else {
            return nil
        }
        return authCredential
    }

    private func oldMailboxPassword() -> String? {
        guard let cypherBits = KeychainWrapper.keychain.data(forKey: CoderKey.mailboxPassword),
              let key = keymaker.mainKey(by: RandomPinProtection.randomPin)
        else {
            return nil
        }
        let locked = Locked<String>(encryptedValue: cypherBits)
        return try? locked.unlock(with: key)
    }

    // swiftlint:disable function_body_length
    func tryRestore() {
        // try new version first
        guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin) else {
            return
        }

        if let oldAuth = oldAuthFetch(), let user = oldUserInfo() {
            let session = oldAuth.sessionID

            let apiService = PMAPIService(doh: self.doh, sessionUID: session)
            apiService.serviceDelegate = self
            #if !APP_EXTENSION
            apiService.humanDelegate = HumanVerificationManager.shared.humanCheckHelper(apiService: apiService)
            apiService.forceUpgradeDelegate = ForceUpgradeManager.shared.forceUpgradeHelper
            #endif
            let newUser = UserManager(api: apiService, userinfo: user, auth: oldAuth, parent: self)
            newUser.delegate = self
            if let pwd = oldMailboxPassword() {
                oldAuth.udpate(password: pwd)
            }

            user.twoFactor = SharedCacheBase.getDefault().integer(forKey: CoderKey.twoFAStatus)
            user.passwordMode = SharedCacheBase.getDefault().integer(forKey: CoderKey.userPasswordMode)
            self.users.append(newUser)
            self.save()
            // Then clear lagcy
            SharedCacheBase.getDefault()?.remove(forKey: CoderKey.username)
            KeychainWrapper.keychain.remove(forKey: CoderKey.keychainStore)

        } else {
            let dataInUserDefault = SharedCacheBase.getDefault()?.data(forKey: CoderKey.authKeychainStore)
            let dataInKeychain = KeychainWrapper.keychain.data(forKey: CoderKey.authKeychainStore)
            guard let encryptedAuthData = dataInUserDefault ?? dataInKeychain  else {
                return
            }
            let authlocked = Locked<[AuthCredential]>(encryptedValue: encryptedAuthData)
            let auths: [AuthCredential]
            do {
                auths = try authlocked.unlock(with: mainKey)
            } catch {
                SharedCacheBase.getDefault().setValue(nil, forKey: CoderKey.authKeychainStore)
                KeychainWrapper.keychain.remove(forKey: CoderKey.authKeychainStore)
                return
            }

            guard let encryptedUsersData = SharedCacheBase.getDefault()?.data(forKey: CoderKey.usersInfo) else {
                return
            }

            let userslocked = Locked<[UserInfo]>(encryptedValue: encryptedUsersData)
            guard let userinfos = try? userslocked.unlock(with: mainKey)  else {
                return
            }

            guard userinfos.count == auths.count else {
                return
            }

            // Check if the existing users is the same as the users stored on the device
            let userIds = userinfos.map { $0.userId }
            let existUserIds = self.users.map { $0.userinfo.userId }
            if !self.users.isEmpty,
               existUserIds.count == userIds.count,
               existUserIds.map({ userIds.contains($0) }).filter({ $0 }).count == userIds.count {
                return
            }

            self.users.removeAll()

            for (auth, user) in zip(auths, userinfos) {
                let session = auth.sessionID
                let apiService = PMAPIService(doh: self.doh, sessionUID: session)
                apiService.serviceDelegate = self
                #if !APP_EXTENSION
                apiService.humanDelegate = HumanVerificationManager.shared.humanCheckHelper(apiService: apiService)
                apiService.forceUpgradeDelegate = ForceUpgradeManager.shared.forceUpgradeHelper
                #endif
                let newUser = UserManager(api: apiService, userinfo: user, auth: auth, parent: self)
                newUser.delegate = self
                self.users.append(newUser)
            }
        }

        self.users.forEach { $0.fetchUserInfo() }
        self.users.first?.cacheService.cleanSoftDeletedMessagesAndConversation()
        self.loggedIn()
    }

    func save() {
        guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin) else {
            return
        }

        let authList = self.users.compactMap { $0.auth }
        userCachedStatus.isForcedLogout = false
        guard let lockedAuth = try? Locked<[AuthCredential]>(clearValue: authList, with: mainKey)
        else {
            return
        }
        SharedCacheBase.getDefault()?.setValue(lockedAuth.encryptedValue, forKey: CoderKey.authKeychainStore)

        let userList = self.users.compactMap { $0.userinfo }
        guard let lockedUsers = try? Locked<[UserInfo]>(clearValue: userList, with: mainKey) else {
            return
        }
        // Check MAILIOS-854, MAILIOS-1208
        SharedCacheBase.getDefault()?.set(lockedUsers.encryptedValue, forKey: CoderKey.usersInfo)
        SharedCacheBase.getDefault().synchronize()
        KeychainWrapper.keychain.remove(forKey: CoderKey.authKeychainStore)
    }
}

extension UsersManager: UserManagerSave {
    func onSave(userManger: UserManager) {
        DispatchQueue.main.async {
            self.save()
        }
    }
}

/// cache login check
extension UsersManager {
    func launchCleanUpIfNeeded() {}

    func logout(user: UserManager,
                shouldShowAccountSwitchAlert: Bool = false,
                completion: (() -> Void)?) {
        var isPrimaryAccountLogout = false
        loggingOutUserIDs.insert(user.userID)
        user.cleanUp().ensure {
            defer {
                self.loggingOutUserIDs.remove(user.userID)
            }
            guard let userToDelete = self.users.first(where: { $0.userID == user.userID }) else {
                self.addDisconnectedUserIfNeeded(user: user)
                completion?()
                return
            }

            if let primary = self.users.first, primary.isMatch(sessionID: userToDelete.auth.sessionID) {
                self.remove(user: userToDelete)
                isPrimaryAccountLogout = true
            } else {
                self.remove(user: userToDelete)
            }

            if self.users.isEmpty {
                _ = self.clean().cauterize()
            } else if shouldShowAccountSwitchAlert {
                String(format: LocalString._signout_account_switched_when_token_revoked,
                       arguments: [userToDelete.defaultEmail,
                                   self.users.first?.defaultEmail ?? ""]).alertToast()
            }

            if isPrimaryAccountLogout {
                NotificationCenter.default.post(name: Notification.Name.didPrimaryAccountLogout, object: nil)
            }
            completion?()
        }.cauterize()
    }

    @discardableResult
    func addDisconnectedUserIfNeeded(user: UserManager) -> Bool {
        if !self.disconnectedUsers.contains(where: { $0.userID == user.userinfo.userId }) {
            let logoutUser = DisconnectedUserHandle(defaultDisplayName: user.defaultDisplayName,
                                                    defaultEmail: user.defaultEmail,
                                                    userID: user.userinfo.userId)
            self.disconnectedUsers.insert(logoutUser, at: 0)
            self.save()
            return true
        }
        return false
    }

    func remove(user: UserManager) {
        if let nextFirst = self.users.first(where: { !$0.isMatch(sessionID: user.auth.sessionID) })?.auth.sessionID {
            self.active(by: nextFirst)
        }
        if !disconnectedUsers.contains(where: { $0.userID == user.userinfo.userId }) {
            let logoutUser = DisconnectedUserHandle(defaultDisplayName: user.defaultDisplayName,
                                                    defaultEmail: user.defaultEmail,
                                                    userID: user.userinfo.userId)
            self.disconnectedUsers.insert(logoutUser, at: 0)
        }
        self.users.removeAll(where: { $0.isMatch(sessionID: user.auth.sessionID) })
        self.save()
    }

    func clean() -> Promise<Void> {
        return UserManager.cleanUpAll().ensure {
            SharedCacheBase.getDefault()?.remove(forKey: CoderKey.usersInfo)
            SharedCacheBase.getDefault()?.remove(forKey: CoderKey.authKeychainStore)
            KeychainWrapper.keychain.remove(forKey: CoderKey.keychainStore)
            KeychainWrapper.keychain.remove(forKey: CoderKey.authKeychainStore)
            KeychainWrapper.keychain.remove(forKey: CoderKey.atLeastOneLoggedIn)
            KeychainWrapper.keychain.remove(forKey: CoderKey.disconnectedUsers)

            self.currentVersion = self.latestVersion

            UserTempCachedStatus.backup()

            sharedUserDataService.signOut(true)

            userCachedStatus.signOut()
            userCachedStatus.cleanGlobal()
            self.users.forEach { user in
                user.userService.signOut(true)
            }
            self.users = []
            self.save()

            if !ProcessInfo.isRunningUnitTests {
                keymaker.wipeMainKey()
            }
            // good opportunity to remove all temp folders
            FileManager.default.cleanTemporaryDirectory()
            // some tests are messed up without tmp folder, so let's keep it for consistency
            #if targetEnvironment(simulator)
            try? FileManager.default
                .createDirectory(at: FileManager.default.temporaryDirectoryUrl,
                                 withIntermediateDirectories: true,
                                 attributes:
                                    nil)
            #endif
        }
    }

    func hasUsers() -> Bool {
        // Have this value after 1.12.0
        let hasUsersInfo = SharedCacheBase.getDefault()?.value(forKey: CoderKey.usersInfo) != nil

        // Workaround to fix MAILIOS-150
        // Method that checks signin or not before 1.11.17
        let isMailboxPasswordStored = KeychainWrapper.keychain.data(forKey: CoderKey.mailboxPassword) != nil
        let isSignIn = hasUserName() && isMailboxPasswordStored

        let authKeychainStore = KeychainWrapper.keychain.data(forKey: CoderKey.authKeychainStore)
        let authUserDefaultStore = SharedCacheBase.getDefault()?.data(forKey: CoderKey.authKeychainStore)

        let hasUsers = (authKeychainStore != nil || authUserDefaultStore != nil) && (hasUsersInfo || isSignIn)

        let message = """
        UsersManager.hasUsers \(hasUsers) - \
        authKeychainStore: \(authKeychainStore != nil); authUserDefaultStore: \(authUserDefaultStore != nil); \
        hasUsersInfo: \(hasUsersInfo); isSignIn: \(isSignIn)
        """
        Breadcrumbs.shared.add(message: message, to: .randomLogout)

        return hasUsers
    }

    var isPasswordStored: Bool {
        return KeychainWrapper.keychain.data(forKey: CoderKey.mailboxPassword) != nil ||
            KeychainWrapper.keychain.string(forKey: CoderKey.atLeastOneLoggedIn) != nil
    }

    var isMailboxPasswordStored: Bool {
        return KeychainWrapper.keychain.string(forKey: CoderKey.atLeastOneLoggedIn) != nil
    }

    func loggedIn() {
        KeychainWrapper.keychain.set("LoggedIn", forKey: CoderKey.atLeastOneLoggedIn)
    }
}

extension UsersManager {
    struct DisconnectedUserHandle: Codable, Equatable {
        var defaultDisplayName: String
        var defaultEmail: String
        var userID: String

        static func == (lhv: DisconnectedUserHandle, rhv: DisconnectedUserHandle) -> Bool {
            return lhv.userID == rhv.userID
        }
    }

    func removeDisconnectedUser(_ handle: DisconnectedUserHandle) {
        self.disconnectedUsers.removeAll(where: { $0 == handle })
    }

    /* logged out users that should be visible in the Account Manager screen for faster log in.
     Persisted until logout of last user, protected with MainKey. */
    var disconnectedUsers: [DisconnectedUserHandle] {
        get {
            // this locking/unlocking can be refactored to be @propertyWrapper on Swift 5.1
            guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
                  let encryptedData = KeychainWrapper.keychain.data(forKey: CoderKey.disconnectedUsers),
                  case let locked = Locked<Data>(encryptedValue: encryptedData),
                  let data = try? locked.unlock(with: mainKey),
                  let loggedOutUserHandles = try? JSONDecoder().decode([DisconnectedUserHandle].self, from: data)
            else {
                return []
            }
            return loggedOutUserHandles
        }
        set {
            guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
                let data = try? JSONEncoder().encode(newValue),
                let locked = try? Locked(clearValue: data, with: mainKey) else {
                return
            }
            KeychainWrapper.keychain.set(locked.encryptedValue, forKey: CoderKey.disconnectedUsers)
        }
    }

    var numberOfFreeAccounts: Int {
        self.users.filter { !$0.isPaid }.count
    }
}

extension UsersManager {
    // swiftlint:disable cyclomatic_complexity function_body_length
    func migrate_0_1() -> Bool {
        guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin) else {
            return false
        }

        if let lagcyPwd = self.oldMailboxPasswordLagcy(),
           let locked = try? Locked(clearValue: lagcyPwd, with: mainKey) {
            KeychainWrapper.keychain.set(locked.encryptedValue, forKey: CoderKey.mailboxPassword)
        }
        if let lagcyName = oldUserNameLagcy(), let locked = try? Locked(clearValue: lagcyName, with: mainKey) {
            KeychainWrapper.keychain.set(locked.encryptedValue, forKey: CoderKey.username)
        }
        userCachedStatus.migrateLagcy()

        // check the older auth and older user format first
        if let oldAuth = oldAuthFetchLagcy(), let user = oldUserInfoLagcy() {
            let session = oldAuth.sessionID
            let apiService = PMAPIService(doh: self.doh, sessionUID: session)
            apiService.serviceDelegate = self
            #if !APP_EXTENSION
            apiService.humanDelegate = HumanVerificationManager.shared.humanCheckHelper(apiService: apiService)
            apiService.forceUpgradeDelegate = ForceUpgradeManager.shared.forceUpgradeHelper
            #endif
            let newUser = UserManager(api: apiService, userinfo: user, auth: oldAuth, parent: self)
            newUser.delegate = self
            if let pwd = oldMailboxPassword() {
                oldAuth.udpate(password: pwd)
            }
            user.twoFactor = SharedCacheBase.getDefault().integer(forKey: CoderKey.twoFAStatus)
            user.passwordMode = SharedCacheBase.getDefault().integer(forKey: CoderKey.userPasswordMode)
            self.users.append(newUser)
            self.save()
            // Then clear lagcy
            SharedCacheBase.getDefault()?.remove(forKey: CoderKey.username)
            KeychainWrapper.keychain.remove(forKey: CoderKey.keychainStore)
            // save to newer version.
            return true
        } else {
            guard let encryptedAuthData = KeychainWrapper.keychain.data(forKey: CoderKey.authKeychainStore) else {
                return false
            }
            let authlocked = Locked<[AuthCredential]>(encryptedValue: encryptedAuthData)
            guard let auths = try? authlocked.lagcyUnlock(with: mainKey) else {
                return false
            }

            guard let encryptedUsersData = SharedCacheBase.getDefault()?.data(forKey: CoderKey.usersInfo) else {
                return false
            }

            let userslocked = Locked<[UserInfo]>(encryptedValue: encryptedUsersData)
            guard let userinfos = try? userslocked.lagcyUnlock(with: mainKey) else {
                return false
            }

            guard userinfos.count == auths.count else {
                return false
            }

            if !self.users.isEmpty {
                return false
            }

            for (auth, user) in zip(auths, userinfos) {
                let session = auth.sessionID
                let apiService = PMAPIService(doh: self.doh, sessionUID: session)
                apiService.serviceDelegate = self
                #if !APP_EXTENSION
                apiService.humanDelegate = HumanVerificationManager.shared.humanCheckHelper(apiService: apiService)
                apiService.forceUpgradeDelegate = ForceUpgradeManager.shared.forceUpgradeHelper
                #endif
                let newUser = UserManager(api: apiService, userinfo: user, auth: auth, parent: self)
                newUser.delegate = self
                self.users.append(newUser)
            }

            // save to the newer version
            self.save()

            let disconnectedUsers = self.disconnedUsersLagcy()
            if let data = try? JSONEncoder().encode(disconnectedUsers),
               let locked = try? Locked(clearValue: data, with: mainKey)
            {
                KeychainWrapper.keychain.set(locked.encryptedValue, forKey: CoderKey.disconnectedUsers)
            }
            return true
        }
    }

    func oldAuthFetchLagcy() -> AuthCredential? {
        guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
              let encryptedData = KeychainWrapper.keychain.data(forKey: CoderKey.keychainStore),
              case let locked = Locked<Data>(encryptedValue: encryptedData),
              let data = try? locked.lagcyUnlock(with: mainKey),
              let authCredential = AuthCredential.unarchive(data: data as NSData)
        else {
            return nil
        }
        return authCredential
    }

    func oldUserInfoLagcy() -> UserInfo? {
        guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
              let cypherData = SharedCacheBase.getDefault()?.data(forKey: CoderKey.userInfo)
        else {
            return nil
        }
        let locked = Locked<UserInfo>(encryptedValue: cypherData)
        return try? locked.lagcyUnlock(with: mainKey)
    }

    func oldMailboxPasswordLagcy() -> String? {
        guard let cypherBits = KeychainWrapper.keychain.data(forKey: CoderKey.mailboxPassword),
              let key = keymaker.mainKey(by: RandomPinProtection.randomPin)
        else {
            return nil
        }
        let locked = Locked<String>(encryptedValue: cypherBits)
        return try? locked.lagcyUnlock(with: key)
    }

    func oldUserNameLagcy() -> String? {
        guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
              let cypherData = SharedCacheBase.getDefault()?.data(forKey: CoderKey.username)
        else {
            return nil
        }

        let locked = Locked<String>(encryptedValue: cypherData)
        return try? locked.lagcyUnlock(with: mainKey)
    }

    func disconnedUsersLagcy() -> [DisconnectedUserHandle] {
        // this locking/unlocking can be refactored to be @propertyWrapper on Swift 5.1
        guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
              let encryptedData = KeychainWrapper.keychain.data(forKey: CoderKey.disconnectedUsers),
              case let locked = Locked<Data>(encryptedValue: encryptedData),
              let data = try? locked.lagcyUnlock(with: mainKey),
              let loggedOutUserHandles = try? JSONDecoder().decode([DisconnectedUserHandle].self, from: data)
        else {
            return []
        }
        return loggedOutUserHandles
    }

    func cleanRandomKeyIfNeeded() {
        // Random key status is in the key chain
        // That means if the users delete the app
        // The key chain could keep the old data
        // If there is not user data, remove the random protection
        let dataInUserDefault = SharedCacheBase.getDefault()?.data(forKey: CoderKey.authKeychainStore)
        let dataInKeyChain = KeychainWrapper.keychain.data(forKey: CoderKey.authKeychainStore)
        guard dataInUserDefault != nil || dataInKeyChain != nil,
              !self.users.isEmpty
        else {
            if let randomProtection = RandomPinProtection.randomPin {
                keymaker.deactivate(randomProtection)
            }
            userCachedStatus.keymakerRandomkey = nil
            RandomPinProtection.removeCyphertext(from: KeychainWrapper.keychain)
            return
        }
    }
}

extension UsersManager: APIServiceDelegate {
    var additionalHeaders: [String: String]? { nil }

    var locale: String {
        return LanguageManager.currentLanguageCode()
    }

    func isReachable() -> Bool {
        return internetConnectionStatusProvider.currentStatus != .notConnected
    }

    func onUpdate(serverTime: Int64) {
        #if !APP_EXTENSION
        let processInfo = userCachedStatus
        #else
        let processInfo = userCachedStatus as? SystemUpTimeProtocol
        #endif
        MailCrypto.updateTime(serverTime, processInfo: processInfo)
    }

    var appVersion: String {
        return "iOS_\(Bundle.main.majorVersion)"
    }

    var userAgent: String? {
        UserAgent.default.ua
    }

    func onDohTroubleshot() {}
}
