//
//  UserManager.swift
//  Proton Mail - Created on 8/15/19.
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
import PromiseKit
import ProtonCoreAuthentication
import ProtonCoreCrypto
@preconcurrency import ProtonCoreDataModel
@preconcurrency import ProtonCoreNetworking
import ProtonCoreTelemetry
#if !APP_EXTENSION
import ProtonCorePayments
#endif
import ProtonCoreServices
import ProtonCoreKeymaker
import ProtonMailAnalytics

/// TODO:: this is temp
protocol UserDataSource: AnyObject {
    var mailboxPassword: Passphrase { get }
    var userInfo: UserInfo { get }
    var authCredential: AuthCredential { get }
    var userID: UserID { get }
}

protocol UserManagerSave: AnyObject {
    func onSave()
}

// protocol created to be able to decouple UserManager from other entities
protocol UserManagerSaveAction: AnyObject {
    func save()
}

class UserManager: ObservableObject {
    private let authCredentialAccessQueue = DispatchQueue(label: "com.protonmail.user_manager.auth_access_queue", qos: .userInitiated)

    var userID: UserID {
        return UserID(rawValue: self.userInfo.userId)
    }

    func cleanUp() -> Promise<Void> {
        return Promise { [weak self] seal in
            guard let self = self else { return }
            self.eventsService.stop()
            self.localNotificationService.cleanUp()

            messageService.cleanUp()
            labelService.cleanUp()
            contactService.cleanUp()
            contactGroupService.cleanUp()
            container.lastUpdatedStore.cleanUp(userId: userID)
            container.featureFlagsRepository.resetFlags(for: userID.rawValue)
            try incomingDefaultService.cleanUp()
            self.deactivatePayments()
            #if !APP_EXTENSION
            switch self.payments.planService {
            case .left(let servicePlanDataService):
                servicePlanDataService.currentSubscription = nil
            case .right:
                break
            }
            #endif
            container.userCachedStatus.removeEncryptedMobileSignature(userID: self.userID.rawValue)
            container.userCachedStatus.removeMobileSignatureSwitchStatus(uid: self.userID.rawValue)
            container.userCachedStatus.removeDefaultSignatureSwitchStatus(uid: self.userID.rawValue)
            container.userCachedStatus.removeIsCheckSpaceDisabledStatus(uid: self.userID.rawValue)
            container.autoImportContactsFeature.disableSettingAndDeleteQueueForUser()
            self.authCredentialAccessQueue.async {
                seal.fulfill_()
            }
        }
    }

    var delegate: UserManagerSave?

    private(set) var apiService: APIService
    private(set) var userInfo: UserInfo {
        didSet {
            updateTelemetryAndCatchCrash()
            didSetUserInfo(oldValue: oldValue)
        }
    }

    @Published
    private(set) var isStorageExceeded: Bool = false
    
    @Published
    private(set) var userLockedFlagsChanged: Bool = false

    let authHelper: AuthHelper
    private(set) var authCredential: AuthCredential

    var isUserSelectedUnreadFilterInInbox = false

    // TODO: deprecate these wrappers

    var cacheService: CacheService {
        container.cacheService
    }

    var contactService: ContactDataService {
        container.contactService
    }

    var contactGroupService: ContactGroupsDataService {
        container.contactGroupService
    }

    var conversationService: ConversationDataServiceProxy {
        container.conversationService
    }

    var conversationStateService: ConversationStateService {
        container.conversationStateService
    }

    var eventsService: EventsFetching {
        container.eventsService
    }

    var featureFlagsDownloadService: FeatureFlagsDownloadService {
        container.featureFlagsDownloadService
    }

    var incomingDefaultService: IncomingDefaultService {
        container.incomingDefaultService
    }

    var labelService: LabelsDataService {
        container.labelService
    }

    var localNotificationService: LocalNotificationService {
        container.localNotificationService
    }

    var messageService: MessageDataService {
        container.messageService
    }

    var undoActionManager: UndoActionManagerProtocol {
        container.undoActionManager
    }

    var userService: UserDataService {
        container.userService
    }
#if !APP_EXTENSION
    var appRatingService: AppRatingService {
        container.appRatingService
    }

    var blockedSenderCacheUpdater: BlockedSenderCacheUpdater {
        container.blockedSenderCacheUpdater
    }

    var payments: Payments {
        container.payments
    }

    var reportService: BugReportService {
        container.reportService
    }
#endif

    // end of wrappers

    weak var parentManager: UsersManager?

    private let appTelemetry: AppTelemetry

    var hasTelemetryEnabled: Bool {
        #if DEBUG
        if !ProcessInfo.isRunningUnitTests {
            return true
        }
        #endif
        return userInfo.telemetry == 1
    }

    @Published var mailSettings: MailSettings

    var container: UserContainer {
        _container
    }

    private var _container: UserContainer!

    init(
        api: APIService,
        userInfo: UserInfo,
        authCredential: AuthCredential,
        mailSettings: MailSettings?,
        parent: UsersManager?,
        appTelemetry: AppTelemetry = MailAppTelemetry(),
        globalContainer: GlobalContainer
    ) {
        self.userInfo = userInfo
        self.apiService = api
        self.authCredential = authCredential
        self.mailSettings = mailSettings ?? .init()
        self.appTelemetry = appTelemetry
        self.authHelper = AuthHelper(authCredential: authCredential)
        self.authHelper.setUpDelegate(self, callingItOn: .asyncExecutor(dispatchQueue: authCredentialAccessQueue))
        self.apiService.authDelegate = authHelper
        self._container = .init(userManager: self, globalContainer: globalContainer)

        acquireSessionIfNeeded()
        self.parentManager = parent
        let handler = container.queueHandler
        let queueManager = globalContainer.queueManager
        queueManager.registerHandler(handler)
        self.messageService.signin()
    }

    private func acquireSessionIfNeeded() {
        self.apiService.acquireSessionIfNeeded { result in
            guard case .success(.sessionAlreadyPresent) = result else {
                assertionFailure("Lack of session just after the auth delegate being configured indicates the programmers error")
                return
            }
        }
    }
    
    private func didSetUserInfo(oldValue: UserInfo) {
        let maxSpace = self.userInfo.maxSpace
        let usedSpace = self.userInfo.usedSpace
        isStorageExceeded = usedSpace >= maxSpace
        userLockedFlagsChanged = self.userInfo.lockedFlags != oldValue.lockedFlags
    }

    func isMatch(sessionID uid: String) -> Bool {
        return authCredential.sessionID == uid
    }

    @MainActor
    func fetchUserInfo() async {
        try? await featureFlagsDownloadService.getFeatureFlags()
        let tuple = await self.userService.fetchUserInfo(auth: self.authCredential)
        guard let info = tuple.0 else { return }
        self.userInfo = info
        self.mailSettings = tuple.1
        self.save()
        #if !APP_EXTENSION
        guard let firstUser = self.parentManager?.firstUser,
              firstUser.userID == self.userID else { return }
        self.activatePayments()
        container.userCachedStatus.initialSwipeActionIfNeeded(leftToRight: info.swipeRight, rightToLeft: info.swipeLeft)
        #endif
    }

    func resignAsActiveUser() {
        deactivatePayments()
        appTelemetry.assignUser(userID: nil)
    }

    func becomeActiveUser() {
        updateTelemetryAndCatchCrash()
        refreshFeatureFlags()
        activatePayments()
        appTelemetry.assignUser(userID: userID)
    }

    func updateTelemetryAndCatchCrash() {
        guard parentManager?.firstUser?.userID == userID else {
            return
        }
        ProtonCoreTelemetry.TelemetryService.shared.setTelemetryEnabled(hasTelemetryEnabled)
        appTelemetry.configure(
            telemetry: hasTelemetryEnabled,
            reportCrashes: userInfo.hasCrashReportingEnabled
        )
    }

    func refreshFeatureFlags() {
        featureFlagsDownloadService.getFeatureFlags(completion: nil)

        configureFeatureFlagsRepository()

        Task {
            try? await self.container.featureFlagsRepository.fetchFlags()
        }
    }

    func configureFeatureFlagsRepository() {
        container.featureFlagsRepository.setUserId(userID.rawValue)
        container.featureFlagsRepository.setApiService(apiService)
    }

    func activatePayments() {
        #if !APP_EXTENSION
        payments.activate(delegate: container.storeKitManagerDelegate)
        #endif
    }

    func deactivatePayments() {
        #if !APP_EXTENSION
        payments.deactivate()
        #endif
    }

    func usedSpace(plus size: Int64) {
        self.userInfo.usedSpace += size
        self.save()
    }

    func usedSpace(minus size: Int64) {
        let usedSize = self.userInfo.usedSpace - size
        self.userInfo.usedSpace = max(usedSize, 0)
        self.save()
    }

    func update(userInfo: UserInfo) {
        self.userInfo = userInfo
    }

    func update(authCredential: AuthCredential) {
        self.authCredential = authCredential
    }
}

extension UserManager: UserManagerSaveAction {

    func save() {
        DispatchQueue.main.async {
            self.conversationStateService.userInfoHasChanged(viewMode: self.userInfo.viewMode)
        }
        self.delegate?.onSave()
    }
}

extension UserManager: UserDataSource {

    var hasPaidMailPlan: Bool {
        userInfo.hasPaidMailPlan
    }

    var mailboxPassword: Passphrase {
        Passphrase(value: authCredential.mailboxpassword)
    }

    var notificationEmail: String {
        return userInfo.notificationEmail
    }

    var notify: Bool {
        return userInfo.notify == 1
    }

    func updateFromEvents(userInfoRes: [String: Any]?) {
        if let userData = userInfoRes {
            let newUserInfo = UserInfo(response: userData)
            let oldUserInfo = self.userInfo
            userInfo.set(userinfo: newUserInfo)
            
            // Temporary fix, should be handled in User.set in Core
            userInfo.lockedFlags = newUserInfo.lockedFlags
            
            self.didSetUserInfo(oldValue: oldUserInfo)
            self.save()
        }
    }

    func updateFromEvents(userSettingsRes: [String: Any]?) {
        if let settings = userSettingsRes {
            userInfo.parse(userSettings: settings)
            updateTelemetryAndCatchCrash()
            self.save()
        }
    }

    func updateFromEvents(mailSettingsRes: [String: Any]?) {
        if let settings = mailSettingsRes {
            userInfo.parse(mailSettings: settings)
            if let mailSettings = try? MailSettings(dict: settings) {
                self.mailSettings = mailSettings
            }
            self.save()
        }
    }

    func update(usedSpace: Int64) {
        guard userInfo.usedSpace != usedSpace else {
            return
        }
        self.userInfo.usedSpace = usedSpace
        // trigger the didSet of userInfo
        self.userInfo = { self.userInfo }()
        self.save()
    }

    func setFromEvents(addressRes address: Address) {
        if let index = self.userInfo.userAddresses.firstIndex(where: { $0.addressID == address.addressID }) {
            self.userInfo.userAddresses.remove(at: index)
        }
        self.userInfo.userAddresses.append(address)
        self.userInfo.userAddresses.sort(by: { (v1, v2) -> Bool in
            return v1.order < v2.order
        })
        self.save()
    }

    func deleteFromEvents(addressIDRes addressID: String) {
        if let index = self.userInfo.userAddresses.firstIndex(where: { $0.addressID == addressID }) {
            self.userInfo.userAddresses.remove(at: index)
            self.save()
        }
    }

    func getUnReadCount(by labelID: String) -> Int {
        return self.labelService.unreadCount(by: LabelID(labelID))
    }
}

/// Get values
extension UserManager {
    var defaultDisplayName: String {
        if let addr = userInfo.userAddresses.defaultAddress() {
            return addr.displayName
        }
        return displayName
    }

    var defaultEmail: String {
        if let addr = userInfo.userAddresses.defaultAddress() {
            return addr.email
        }
        return ""
    }

    var displayName: String {
        return userInfo.displayName.decodeHtml()
    }

    var addresses: [Address] {
        get { userInfo.userAddresses }
        set { userInfo.userAddresses = newValue }
    }

    var userDefaultSignature: String {
        return userInfo.defaultSignature.ln2br()
    }

    var defaultSignatureStatus: Bool {
        get {
            if let status = container.userCachedStatus.getDefaultSignaureSwitchStatus(uid: userID.rawValue) {
                return status
            } else {
                let oldStatus = container.userCachedStatus.userDefaults.bool(
                    forKey: UserCachedStatus.LegacyKey.defaultSignatureStatus
                )
                container.userCachedStatus.setDefaultSignatureSwitchStatus(uid: userID.rawValue, value: oldStatus)
                return oldStatus
            }
        }
        set {
            container.userCachedStatus.setDefaultSignatureSwitchStatus(uid: userID.rawValue, value: newValue)
        }
    }

    var showMobileSignature: Bool {
        get {
            if userInfo.hasPaidMailPlan {
                return container.userCachedStatus.getMobileSignatureSwitchStatus(by: userID.rawValue) ?? false
            } else {
                container.userCachedStatus.setMobileSignatureSwitchStatus(uid: userID.rawValue, value: true)
                return true
            }
        }
        set {
            container.userCachedStatus.setMobileSignatureSwitchStatus(uid: userID.rawValue, value: newValue)
        }
    }

    var isEnableFolderColor: Bool {
        return userInfo.enableFolderColor == 1
    }

    var isInheritParentFolderColor: Bool {
        return userInfo.inheritParentFolderColor == 1
    }

    var hasAtLeastOneNonStandardToolbarAction: Bool {
        guard let users = parentManager else {
            return false
        }
        return users.users.contains(where: { user in
            user.userInfo.messageToolbarActions.isCustom ||
            user.userInfo.listToolbarActions.isCustom ||
            user.userInfo.conversationToolbarActions.isCustom
        })
    }

    var toolbarActionsIsStandard: Bool {
        return !userInfo.messageToolbarActions.isCustom &&
            !userInfo.listToolbarActions.isCustom &&
            !userInfo.conversationToolbarActions.isCustom
    }
}

extension UserManager: UserAddressUpdaterProtocol {
    func updateUserAddresses(completion: (() -> Void)?) {
        userService.fetchUserAddresses { [weak self] result in
            switch result {
            case .failure:
                completion?()
            case .success(let addressResponse):
                self?.userInfo.set(addresses: addressResponse.addresses)
                self?.save()
                completion?()
            }
        }
    }
}

extension UserManager: AuthHelperDelegate {
    func credentialsWereUpdated(authCredential: AuthCredential, credential: Credential, for sessionUID: String) {
        Breadcrumbs.shared.add(message: "UserManager.credentialsWereUpdated", to: .randomLogout)
        if authCredential.isForUnauthenticatedSession {
            let credentialsForDifferentSessions = self.authCredential.sessionID != authCredential.sessionID
            let data = "credentialsForDifferentSessions=\(credentialsForDifferentSessions) | receivedCredentialsSession = \(authCredential.sessionID.redacted)"
            Breadcrumbs.shared.add(message: "ERROR: UserManager.credentialsWereUpdated for unauthenticated session: \(data)", to: .randomLogout)

            assertionFailure("This should never happen — the UserManager should always operate within the authenticated session. Please investigate!")
        }
        self.authCredential = authCredential
        self.save()
    }

    func sessionWasInvalidated(for sessionUID: String, isAuthenticatedSession: Bool) {
        Breadcrumbs.shared.add(message: "UserManager.sessionWasInvalidated session=\(sessionUID.redacted)", to: .randomLogout)
        if !isAuthenticatedSession {
            Breadcrumbs.shared.add(message: "ERROR: UserManager.sessionWasInvalidated for unauthenticated session", to: .randomLogout)
            assertionFailure("This should never happen — the UserManager should always operate within the authenticated session. Please investigate!")
        }
        self.eventsService.stop()
        NotificationCenter.default.post(name: .didRevoke, object: nil, userInfo: ["uid": sessionUID])
    }
}

// Telemetry

extension UserManager {

    func sendLocalSettingsTelemetryHeartbeat() {
        Task {
            let event: TelemetryEvent = .localSettingsHeartbeat(
                isAppKeyOn: container.keyMaker.isAppKeyEnabled,
                isAutoImportContactsOn: container.autoImportContactsFeature.isFeatureEnabledTelemetryValue,
                hasPaidMailPlan: hasPaidMailPlan
            )
            await container.telemetryService.sendEvent(event)
        }
    }
}
