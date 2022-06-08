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
import ProtonCore_Authentication
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_Networking
#if !APP_EXTENSION
import ProtonCore_Payments
#endif
import ProtonCore_Services

/// TODO:: this is temp
protocol UserDataSource: AnyObject {
    var mailboxPassword: Passphrase { get }
    var newSchema: Bool { get }
    var addressKeys: [Key] { get }
    var userPrivateKeys: [Data] { get }
    var userInfo: UserInfo { get }
    var addressPrivateKeys: [Data] { get }
    var authCredential: AuthCredential { get }
    var userID: UserID { get }

    func getAddressKey(address_id: String) -> Key?
    func getAllAddressKey(address_id: String) -> [Key]?
    func getAddressPrivKey(address_id: String) -> String
}

protocol UserManagerSave: AnyObject {
    func onSave()
}

// protocol created to be able to decouple UserManager from other entities
protocol UserManagerSaveAction: AnyObject {
    func save()
}

class UserManager: Service, HasLocalStorage {
    private let authCredentialAccessQueue = DispatchQueue(label: "com.protonmail.user_manager.auth_access_queue", qos: .userInitiated)

    var userID: UserID {
        return UserID(rawValue: self.userInfo.userId)
    }

    func cleanUp() -> Promise<Void> {
        return Promise { [weak self] seal in
            guard let self = self else { return }
            self.eventsService.stop()
            self.localNotificationService.cleanUp()

            var wait = Promise<Void>()
            let promises = [
                self.messageService.cleanUp(),
                self.labelService.cleanUp(),
                self.contactService.cleanUp(),
                self.contactGroupService.cleanUp(),
                lastUpdatedStore.cleanUp(userId: self.userID)
            ]
            self.deactivatePayments()
            #if !APP_EXTENSION
            self.payments.planService.currentSubscription = nil
            #endif
            for p in promises {
                wait = wait.then({ (_) -> Promise<Void> in
                    return p
                })
            }
            wait.done {
                userCachedStatus.removeMobileSignature(uid: self.userID.rawValue)
                userCachedStatus.removeMobileSignatureSwitchStatus(uid: self.userID.rawValue)
                userCachedStatus.removeDefaultSignatureSwitchStatus(uid: self.userID.rawValue)
                userCachedStatus.removeIsCheckSpaceDisabledStatus(uid: self.userID.rawValue)
                self.authCredentialAccessQueue.sync { [weak self] in
                    self?.isLoggedOut = true
                }
                seal.fulfill_()
            }.catch { (_) in
                seal.fulfill_()
            }
        }
    }

    static func cleanUpAll() -> Promise<Void> {
        LocalNotificationService.cleanUpAll()

        var wait = Promise<Void>()
        let promises = [
            MessageDataService.cleanUpAll(),
            LabelsDataService.cleanUpAll(),
            ContactDataService.cleanUpAll(),
            ContactGroupsDataService.cleanUpAll(),
            UserDataService.cleanUpAll(),
            LastUpdatedStore.cleanUpAll()
        ]
        for p in promises {
            wait = wait.then({ (_) -> Promise<Void> in
                return p
            })
        }
        return wait
    }

    var delegate: UserManagerSave?

    var apiService: APIService
    var userInfo: UserInfo
    private(set) var authCredential: AuthCredential
    private var isLoggedOut = false

    var isUserSelectedUnreadFilterInInbox = false
    private let contextProvider: CoreDataContextProviderProtocol

    lazy var conversationStateService: ConversationStateService = { [unowned self] in
        return ConversationStateService(
            userDefaults: SharedCacheBase.getDefault(),
            viewMode: self.userInfo.viewMode
        )
    }()

    lazy var reportService: BugDataService = { [unowned self] in
        let service = BugDataService(api: self.apiService)
        return service
    }()

    lazy var contactService: ContactDataService = { [unowned self] in
        let service = ContactDataService(api: self.apiService,
                                         labelDataService: self.labelService,
                                         userInfo: self.userInfo,
                                         coreDataService: sharedServices.get(by: CoreDataService.self),
                                         contactCacheStatus: userCachedStatus,
                                         cacheService: self.cacheService,
                                         queueManager: sharedServices.get(by: QueueManager.self))
        return service
    }()

    lazy var contactGroupService: ContactGroupsDataService = { [unowned self] in
        let service = ContactGroupsDataService(api: self.apiService,
                                               labelDataService: self.labelService,
                                               coreDataService: sharedServices.get(by: CoreDataService.self),
                                               queueManager: sharedServices.get(by: QueueManager.self),
                                               userID: self.userID)
        return service
    }()

    weak var parentManager: UsersManager?

    lazy var messageService: MessageDataService = { [unowned self] in
        let service = MessageDataService(
            api: self.apiService,
            userID: self.userID,
            labelDataService: self.labelService,
            contactDataService: self.contactService,
            localNotificationService: self.localNotificationService,
            queueManager: sharedServices.get(by: QueueManager.self),
            contextProvider: contextProvider,
            lastUpdatedStore: sharedServices.get(by: LastUpdatedStore.self),
            user: self,
            cacheService: self.cacheService,
            undoActionManager: self.undoActionManager,
            contactCacheStatus: userCachedStatus)
        service.viewModeDataSource = self
        service.userDataSource = self
        return service
    }()

    lazy var mainQueueHandler: MainQueueHandler = { [unowned self] in
        let service = MainQueueHandler(coreDataService: sharedServices.get(by: CoreDataService.self),
                                       apiService: self.apiService,
                                       messageDataService: self.messageService,
                                       conversationDataService: self.conversationService.conversationDataService,
                                       labelDataService: self.labelService,
                                       localNotificationService: self.localNotificationService,
                                       undoActionManager: self.undoActionManager,
                                       user: self)
        let shareQueueManager = sharedServices.get(by: QueueManager.self)
        shareQueueManager.registerHandler(service)
        return service
    }()

    lazy var conversationService: ConversationDataServiceProxy = { [unowned self] in
        let service = ConversationDataServiceProxy(api: apiService,
                                                   userID: userID,
                                                   contextProvider: sharedServices.get(by: CoreDataService.self),
                                                   lastUpdatedStore: sharedServices.get(by: LastUpdatedStore.self),
                                                   messageDataService: messageService,
                                                   eventsService: eventsService,
                                                   undoActionManager: undoActionManager,
                                                   queueManager: sharedServices.get(by: QueueManager.self),
                                                   contactCacheStatus: userCachedStatus)
        return service
    }()

    lazy var labelService: LabelsDataService = { [unowned self] in
        let service = LabelsDataService(api: self.apiService, userID: self.userID, contextProvider: sharedServices.get(by: CoreDataService.self), lastUpdatedStore: sharedServices.get(by: LastUpdatedStore.self), cacheService: self.cacheService)
        service.viewModeDataSource = self
        return service
    }()

    lazy var userService: UserDataService = { [unowned self] in
        let service = UserDataService(check: false, api: self.apiService)
        return service
    }()

    lazy var localNotificationService: LocalNotificationService = { [unowned self] in
        let service = LocalNotificationService(userID: self.userID)
        return service
    }()

    lazy var cacheService: CacheService = { [unowned self] in
        let service = CacheService(userID: self.userID)
        return service
    }()

    lazy var eventsService: EventsFetching = { [unowned self] in
        let service = EventsService(userManager: self, contactCacheStatus: userCachedStatus)
        return service
    }()

    lazy var undoActionManager: UndoActionManagerProtocol = { [unowned self] in
        let manager = UndoActionManager(
            apiService: self.apiService,
            contextProvider: contextProvider,
            getEventFetching: { [weak self] in
                self?.eventsService
            },
            getUserManager: { [weak self] in
                self
            }
        )
        return manager
    }()

	lazy var featureFlagsDownloadService: FeatureFlagsDownloadService = { [unowned self] in
        let service = FeatureFlagsDownloadService(apiService: self.apiService, sessionID: self.authCredential.sessionID)
        service.register(newSubscriber: conversationStateService)
        service.register(newSubscriber: inAppFeedbackStateService)
        return service
    }()

    private var lastUpdatedStore: LastUpdatedStoreProtocol {
        return sharedServices.get(by: LastUpdatedStore.self)
    }

    lazy var inAppFeedbackStateService: InAppFeedbackStateServiceProtocol = {
        let service = InAppFeedbackStateService()
        return service
    }()

    #if !APP_EXTENSION
    lazy var payments = Payments(inAppPurchaseIdentifiers: Constants.mailPlanIDs,
                                 apiService: self.apiService,
                                 localStorage: userCachedStatus,
                                 canExtendSubscription: true,
                                 reportBugAlertHandler: { _ in
                                     let link = DeepLink("toBugPop", sender: nil)
                                     NotificationCenter.default.post(name: .switchView, object: link)
                                 })
    #endif

    init(api: APIService,
         userInfo: UserInfo,
         authCredential: AuthCredential,
         parent: UsersManager?,
         contextProvider: CoreDataContextProviderProtocol = sharedServices.get(by: CoreDataService.self)) {
        self.userInfo = userInfo
        self.authCredential = authCredential
        self.apiService = api
        self.contextProvider = contextProvider
        self.apiService.authDelegate = self
        self.parentManager = parent
        _ = self.mainQueueHandler.userID
        self.messageService.signin()
    }

    /// A mock function only for unit test
    init(api: APIService,
         role: UserInfo.OrganizationRole,
         userInfo: UserInfo = UserInfo.getDefault(),
         contextProvider: CoreDataContextProviderProtocol = sharedServices.get(by: CoreDataService.self)) {
        userInfo.role = role.rawValue
        self.userInfo = userInfo
        self.authCredential = AuthCredential.none
        self.apiService = api
        self.contextProvider = contextProvider
        self.apiService.authDelegate = self
    }

    func isMatch(sessionID uid: String) -> Bool {
        return authCredential.sessionID == uid
    }

    func fetchUserInfo() {
        featureFlagsDownloadService.getFeatureFlags(completion: nil)
        _ = self.userService.fetchUserInfo(auth: self.authCredential).done { [weak self] info in
            guard let info = info else { return }
            self?.userInfo = info
            self?.save()
            #if !APP_EXTENSION
            guard let self = self,
                  let firstUser = self.parentManager?.firstUser,
                  firstUser.userID == self.userID else { return }
            self.activatePayments()
            userCachedStatus.initialSwipeActionIfNeeded(leftToRight: info.swipeRight, rightToLeft: info.swipeLeft)
            // When app launch, the app will show a skeleton view
            // After getting setting data, show inbox
            NotificationCenter.default.post(name: .fetchPrimaryUserSettings, object: nil)
            #endif
        }
    }

    func refreshFeatureFlags() {
        featureFlagsDownloadService.getFeatureFlags(completion: nil)
    }

    func activatePayments() {
        #if !APP_EXTENSION
        self.payments.storeKitManager.delegate = sharedServices.get(by: StoreKitManagerImpl.self)
        self.payments.storeKitManager.subscribeToPaymentQueue()
        self.payments.storeKitManager.updateAvailableProductsList { _ in }
        #endif
    }

    func deactivatePayments() {
        #if !APP_EXTENSION
        self.payments.storeKitManager.unsubscribeFromPaymentQueue()
        // this will ensure no unnecessary screen refresh happens, which was the source of crash previously
        self.payments.storeKitManager.refreshHandler = { _ in }
        // this will ensure no unnecessary communication with proton backend happens
        self.payments.storeKitManager.delegate = nil
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

    func update(credential: AuthCredential, userInfo: UserInfo) {
        self.authCredentialAccessQueue.sync { [weak self] in
            self?.isLoggedOut = false
            self?.authCredential = credential
            self?.userInfo = userInfo
        }
    }
}

extension UserManager: AuthDelegate {

    func authCredential(sessionUID: String) -> AuthCredential? {
        self.authCredentialAccessQueue.sync { [weak self] in
            guard let self = self else { return nil }
            if self.isLoggedOut {
                print("Request credential after logging out")
            } else if self.authCredential.sessionID == sessionUID {
                return self.authCredential
            } else {
                assert(false, "Inadequate credential requested")
            }
            return nil
        }
    }

    func credential(sessionUID: String) -> Credential? {
        authCredential(sessionUID: sessionUID).map(Credential.init)
    }

    func onLogout(sessionUID uid: String) {
        // TODO:: Since the user manager can directly catch the onLogOut event. we can improve this logic to not use the NotificationCenter.
        self.authCredentialAccessQueue.sync { [weak self] in
            self?.isLoggedOut = true
        }
        self.eventsService.stop()
        NotificationCenter.default.post(name: .didRevoke, object: nil, userInfo: ["uid": uid])
    }

    func onUpdate(credential: Credential, sessionUID: String) {
        guard credential.UID == sessionUID else {
            assertionFailure("Credential.UID \(credential.UID) does not match sessionUID \(sessionUID)")
            return
        }

        self.authCredentialAccessQueue.sync { [weak self] in
            self?.isLoggedOut = false
            self?.authCredential.udpate(
                sessionID: sessionUID,
                accessToken: credential.accessToken,
                refreshToken: credential.refreshToken,
                expiration: credential.expiration)

        }
        self.save()
    }

    func onRefresh(sessionUID: String, service: APIService, complete: @escaping AuthRefreshResultCompletion) {
        let credential = self.credential(sessionUID: sessionUID) ?? Credential(.none)
        let authenticator = Authenticator(api: service)
        authenticator.refreshCredential(credential) { result in
            let processedResult: Swift.Result<Credential, AuthErrors> = result.map {
                switch $0 {
                case .ask2FA((let credential, _)),
                        .newCredential(let credential, _),
                        .updatedCredential(let credential):
                    return credential
                }
                complete(updatedCredential, nil)
            case .failure(let error):
                complete(nil, error)
            }
            complete(processedResult)
        }
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
        userInfo.role > 0 && userInfo.subscribed != 4
    }

    func getAddressPrivKey(address_id: String) -> String {
        return ""
    }

    func getAddressKey(address_id: String) -> Key? {
        return self.userInfo.getAddressKey(address_id: address_id)
    }

    func getAllAddressKey(address_id: String) -> [Key]? {
        return self.userInfo.getAllAddressKey(address_id: address_id)
    }

    var userPrivateKeys: [Data] {
        get {
            self.userInfo.userPrivateKeysArray
        }
    }

    var addressKeys: [Key] {
        get {
            return self.userInfo.userAddresses.toKeys()
        }
    }

    var newSchema: Bool {
        get {
            return self.userInfo.isKeyV2
        }
    }

    var mailboxPassword: Passphrase {
        Passphrase(value: authCredential.mailboxpassword)
    }

    var addressPrivateKeys: [Data] {
        get {
            return self.userInfo.addressPrivateKeysArray
        }
    }

    var notificationEmail: String {
        return userInfo.notificationEmail
    }

    var notify: Bool {
        return userInfo.notify == 1
    }

    var isPaid: Bool {
        return self.userInfo.role > 0 ? true : false
    }

    func updateFromEvents(userInfoRes: [String: Any]?) {
        if let userData = userInfoRes {
            let newUserInfo = UserInfo(response: userData)
            userInfo.set(userinfo: newUserInfo)
            self.save()
        }
    }

    func updateFromEvents(userSettingsRes: [String: Any]?) {
        if let settings = userSettingsRes {
            userInfo.parse(userSettings: settings)
            self.save()
        }
    }
    func updateFromEvents(mailSettingsRes: [String: Any]?) {
        if let settings = mailSettingsRes {
            userInfo.parse(mailSettings: settings)
            self.save()
        }
    }

    func update(usedSpace: Int64) {
        self.userInfo.usedSpace = usedSpace
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

    var autoLoadRemoteImages: Bool {
        return userInfo.autoShowRemote
    }

    var userDefaultSignature: String {
        return userInfo.defaultSignature.ln2br()
    }

    var defaultSignatureStatus: Bool {
        get {
            if let status = userCachedStatus.getDefaultSignaureSwitchStatus(uid: userID.rawValue) {
                return status
            } else {
                let oldStatus = userService.defaultSignatureStauts
                userCachedStatus.setDefaultSignatureSwitchStatus(uid: userID.rawValue, value: oldStatus)
                return oldStatus
            }
        }
        set {
            userCachedStatus.setDefaultSignatureSwitchStatus(uid: userID.rawValue, value: newValue)
        }
    }

    var showMobileSignature: Bool {
        get {
            #if Enterprise
            let isEnterprise = true
            #else
            let isEnterprise = false
            #endif
            let role = userInfo.role
            if role > 0 || isEnterprise {
                if let status = userCachedStatus.getMobileSignatureSwitchStatus(by: userID.rawValue) {
                    return status
                } else {
                    // Migrate from local cache
                    let status = self.userService.switchCacheOff == false
                    userCachedStatus.setMobileSignatureSwitchStatus(uid: userID.rawValue, value: status)
                    return status
                }
            } else {
                userCachedStatus.setMobileSignatureSwitchStatus(uid: userID.rawValue, value: true)
                return true
            } }
        set {
            userCachedStatus.setMobileSignatureSwitchStatus(uid: userID.rawValue, value: newValue)
        }
    }

    var mobileSignature: String {
        get {
            #if Enterprise
            let isEnterprise = true
            #else
            let isEnterprise = false
            #endif
            let role = userInfo.role
            if role > 0 || isEnterprise {
                return userCachedStatus.getMobileSignature(by: userID.rawValue)
            } else {
                userCachedStatus.removeMobileSignature(uid: userID.rawValue)
                return userCachedStatus.getMobileSignature(by: userID.rawValue)
            }
        }
        set {
            userCachedStatus.setMobileSignature(uid: userID.rawValue, signature: newValue)
        }
    }

    var isEnableFolderColor: Bool {
        return userInfo.enableFolderColor == 1
    }

    var isInheritParentFolderColor: Bool {
        return userInfo.inheritParentFolderColor == 1
    }

    var isStorageExceeded: Bool {
        let maxSpace = self.userInfo.maxSpace
        let usedSpace = self.userInfo.usedSpace
        return usedSpace >= maxSpace
    }
}

extension UserManager: ViewModeDataSource {
    func getCurrentViewMode() -> ViewMode {
        return conversationStateService.viewMode
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
