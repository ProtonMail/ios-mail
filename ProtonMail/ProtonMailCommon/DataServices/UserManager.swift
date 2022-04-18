//
//  UserManager.swift
//  ProtonMail - Created on 8/15/19.
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

import Foundation
import PromiseKit
import ProtonCore_Authentication
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_Payments
import ProtonCore_Services

/// TODO:: this is temp
protocol UserDataSource: AnyObject {
    var mailboxPassword: String { get }
    var newSchema: Bool { get }
    var addresses: [Address] { get }
    var addressKeys: [Key] { get }
    var userPrivateKeys: [Data] { get }
    var userInfo: UserInfo { get }
    var addressPrivateKeys: [Data] { get }
    var authCredential: AuthCredential { get }
    var userID: UserID { get }

    func getAddressKey(address_id: String) -> Key?
    func getAllAddressKey(address_id: String) -> [Key]?
    func getAddressPrivKey(address_id: String) -> String

    func updateFromEvents(userInfoRes: [String: Any]?)
    func updateFromEvents(userSettingsRes: [String: Any]?)
    func updateFromEvents(mailSettingsRes: [String: Any]?)
    func update(usedSpace: Int64)
    func setFromEvents(addressRes: Address)
    func deleteFromEvents(addressIDRes: String)
}

protocol UserManagerSave: AnyObject {
    func onSave(userManger: UserManager)
}

class UserManager: Service, HasLocalStorage {
    var userID: UserID {
        return UserID(rawValue: self.userinfo.userId)
    }

    func cleanUp() -> Promise<Void> {
        return Promise { seal in
            self.eventsService.stop()
            self.localNotificationService.cleanUp()

            var wait = Promise<Void>()
            let promises = [
                self.messageService.cleanUp(),
                self.labelService.cleanUp(),
                self.contactService.cleanUp(),
                self.contactGroupService.cleanUp(),
                self.userService.cleanUp(),
                lastUpdatedStore.cleanUp(userId: self.userID.rawValue)
            ]
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
    var userinfo: UserInfo
    var auth: AuthCredential

    var isUserSelectedUnreadFilterInInbox = false

    lazy var conversationStateService: ConversationStateService = { [unowned self] in
        return ConversationStateService(
            userDefaults: SharedCacheBase.getDefault(),
            viewMode: self.userinfo.viewMode
        )
    }()

    lazy var reportService: BugDataService = { [unowned self] in
        let service = BugDataService(api: self.apiService)
        return service
    }()

    lazy var contactService: ContactDataService = { [unowned self] in
        let service = ContactDataService(api: self.apiService,
                                         labelDataService: self.labelService,
                                         userID: self.userID,
                                         coreDataService: sharedServices.get(by: CoreDataService.self),
                                         lastUpdatedStore: sharedServices.get(by: LastUpdatedStore.self),
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
        let service = MessageDataService(api: self.apiService,
                                         userID: self.userID,
                                         labelDataService: self.labelService,
                                         contactDataService: self.contactService,
                                         localNotificationService: self.localNotificationService,
                                         queueManager: sharedServices.get(by: QueueManager.self),
                                         coreDataService: sharedServices.get(by: CoreDataService.self),
                                         lastUpdatedStore: sharedServices.get(by: LastUpdatedStore.self),
                                         user: self,
                                         cacheService: self.cacheService)
        service.viewModeDataSource = self
        service.userDataSource = self
        return service
    }()

    lazy var mainQueueHandler: MainQueueHandler = { [unowned self] in
        let service = MainQueueHandler(cacheService: self.cacheService,
                                       coreDataService: sharedServices.get(by: CoreDataService.self),
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
                                                   coreDataService: sharedServices.get(by: CoreDataService.self),
                                                   labelDataService: labelService,
                                                   lastUpdatedStore: sharedServices.get(by: LastUpdatedStore.self), eventsService: eventsService,
                                                   undoActionManager: undoActionManager,
                                                   viewModeDataSource: self,
                                                   queueManager: sharedServices.get(by: QueueManager.self))
        return service
    }()

    lazy var labelService: LabelsDataService = { [unowned self] in
        let service = LabelsDataService(api: self.apiService, userID: self.userID, coreDataService: sharedServices.get(by: CoreDataService.self), lastUpdatedStore: sharedServices.get(by: LastUpdatedStore.self), cacheService: self.cacheService)
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
        let service = CacheService(userID: self.userID, lastUpdatedStore: self.lastUpdatedStore, coreDataService: sharedServices.get(by: CoreDataService.self))
        return service
    }()

    lazy var eventsService: EventsFetching = { [unowned self] in
        let service = EventsService(userManager: self)
        return service
    }()

    lazy var undoActionManager: UndoActionManagerProtocol = { [unowned self] in
        let manager = UndoActionManager(apiService: self.apiService) { [weak self] in
            self?.eventsService.fetchEvents(labelID: Message.Location.allmail.rawValue)
        }
        return manager
    }()

	lazy var featureFlagsDownloadService: FeatureFlagsDownloadService = { [unowned self] in
        let service = FeatureFlagsDownloadService(apiService: self.apiService, sessionID: self.auth.sessionID)
        service.register(newSubscriber: conversationStateService)
        service.register(newSubscriber: inAppFeedbackStateService)
        service.getFeatureFlags(completion: nil)
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
                                        reportBugAlertHandler: { receipt in
        let link = DeepLink("toBugPop", sender: nil)
        NotificationCenter.default.post(name: .switchView, object: link)
    })
    #endif

    init(api: APIService, userinfo: UserInfo, auth: AuthCredential, parent: UsersManager?) {
        self.userinfo = userinfo
        self.auth = auth
        self.apiService = api
        self.apiService.authDelegate = self
        self.parentManager = parent
        _ = self.mainQueueHandler.userID
        self.messageService.signin()
    }

    /// A mock function only for unit test
    init(api: APIService, role: UserInfo.OrganizationRole) {
        let userinfo = UserInfo.getDefault()
        userinfo.role = role.rawValue
        self.userinfo = userinfo
        self.auth = AuthCredential.none
        self.apiService = api
        self.apiService.authDelegate = self
    }

    func isMatch(sessionID uid: String) -> Bool {
        return auth.sessionID == uid
    }

    func save() {
        DispatchQueue.main.async {
            self.conversationStateService.userInfoHasChanged(viewMode: self.userinfo.viewMode)
        }
        self.delegate?.onSave(userManger: self)
    }

    func fetchUserInfo() {
        featureFlagsDownloadService.getFeatureFlags(completion: nil)
        _ = self.userService.fetchUserInfo(auth: self.auth).done { [weak self] info in
            guard let info = info else { return }
            self?.userinfo = info
            self?.save()
            #if !APP_EXTENSION
            guard let self = self,
                  let firstUser = self.parentManager?.firstUser,
                  firstUser.userID == self.userID else { return }
            self.activatePayments()
            userCachedStatus.initialSwipeActionIfNeeded(leftToRight: info.swipeLeft, rightToLeft: info.swipeRight)
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

    func usedSpace(plus size: Int64) {
        self.userinfo.usedSpace += size
        self.save()
    }

    func usedSpace(minus size: Int64) {
        let usedSize = self.userinfo.usedSpace - size
        self.userInfo.usedSpace = max(usedSize, 0)
        self.save()
    }
}

extension UserManager: AuthDelegate {
    func getToken(bySessionUID uid: String) -> AuthCredential? {
        guard auth.sessionID == uid else {
            assert(false, "Inadequate crerential requested")
            return nil
        }
        return auth
    }

    func onLogout(sessionUID uid: String) {
        // TODO:: Since the user manager can directly catch the onLogOut event. we can improve this logic to not use the NotificationCenter.
        eventsService.stop()
        NotificationCenter.default.post(name: .didRevoke, object: nil, userInfo: ["uid": uid])
    }

    func onUpdate(auth: Credential) {
        self.auth.udpate(sessionID: auth.UID, accessToken: auth.accessToken, refreshToken: auth.refreshToken, expiration: auth.expiration)
        self.save()
    }

    func onRefresh(bySessionUID uid: String, complete: @escaping AuthRefreshComplete) {
        let authenticator = Authenticator(api: apiService)
        let auth = authCredential
        authenticator.refreshCredential(Credential(auth)) { result in
            switch result {
            case .success(let stage):
                guard case Authenticator.Status.updatedCredential(let updatedCredential) = stage else {
                    return complete(nil, nil)
                }
                complete(updatedCredential, nil)
            case .failure(let error):
                complete(nil, error)
            }
        }
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
        return self.userinfo.getAllAddressKey(address_id: address_id)
    }

    var userPrivateKeys: [Data] {
        get {
            self.userinfo.userPrivateKeysArray
        }
    }

    var addressKeys: [Key] {
        get {
            return self.userinfo.userAddresses.toKeys()
        }
    }

    var newSchema: Bool {
        get {
            return self.userinfo.isKeyV2
        }
    }

    var mailboxPassword: String {
        get {
            return self.auth.mailboxpassword
        }
    }

    var userInfo: UserInfo {
        get {
            return self.userinfo
        }

    }

    var addressPrivateKeys: [Data] {
        get {
            return self.userinfo.addressPrivateKeysArray
        }
    }

    var authCredential: AuthCredential {
        get {
            return self.auth
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
        return self.labelService.unreadCount(by: labelID)
    }
}

/// Get values
extension UserManager {
    var defaultDisplayName: String {
        if let addr = userinfo.userAddresses.defaultAddress() {
            return addr.displayName
        }
        return displayName
    }

    var defaultEmail: String {
        if let addr = userinfo.userAddresses.defaultAddress() {
            return addr.email
        }
        return ""
    }

    var displayName: String {
        return userinfo.displayName.decodeHtml()
    }

    var addresses: [Address] {
        get { userinfo.userAddresses }
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
        return userinfo.enableFolderColor == 1
    }

    var isInheritParentFolderColor: Bool {
        return userinfo.inheritParentFolderColor == 1
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
                self?.userinfo.set(addresses: addressResponse.addresses)
                self?.save()
                completion?()
            }
        }
    }
}
