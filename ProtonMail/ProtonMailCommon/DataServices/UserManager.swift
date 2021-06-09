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
protocol UserDataSource : AnyObject {
    var mailboxPassword : String { get }
    var newSchema : Bool { get }
    var addresses: [Address] { get }
    var addressKeys : [Key] { get }
    var userPrivateKeys : [Data] { get }
    var userInfo : UserInfo { get }
    var addressPrivateKeys : [Data] { get }
    var authCredential : AuthCredential { get }
    func getAddressKey(address_id : String) -> Key?
    func getAllAddressKey(address_id: String) -> [Key]?
    func getAddressPrivKey(address_id : String) -> String
    
    func updateFromEvents(userInfoRes: [String : Any]?)
    func updateFromEvents(userSettingsRes: [String : Any]?)
    func updateFromEvents(mailSettingsRes: [String : Any]?)
    func update(usedSpace: Int64)
    func setFromEvents(addressRes: Address)
    func deleteFromEvents(addressIDRes: String)
}

protocol UserManagerSave: AnyObject {
    func onSave(userManger: UserManager)
}

///
class UserManager : Service, HasLocalStorage {
    func cleanUp() -> Promise<Void> {
        return Promise { seal in
            self.eventsService.stop()
            var wait = Promise<Void>()
            var promises = [
                self.messageService.cleanUp(),
                self.labelService.cleanUp(),
                self.contactService.cleanUp(),
                self.contactGroupService.cleanUp(),
                self.localNotificationService.cleanUp(),
                //                self.userService.cleanUp(),
                lastUpdatedStore.cleanUp(userId: self.userinfo.userId),
            ]
            #if !APP_EXTENSION
            promises.append(self.sevicePlanService.cleanUp())
            #endif
            for p in promises {
                wait = wait.then({ (_) -> Promise<Void> in
                    return p
                })
            }
            wait.done {
                userCachedStatus.removeMobileSignature(uid: self.userInfo.userId)
                userCachedStatus.removeMobileSignatureSwitchStatus(uid: self.userInfo.userId)
                userCachedStatus.removeDefaultSignatureSwitchStatus(uid: self.userInfo.userId)
                userCachedStatus.removeIsCheckSpaceDisabledStatus(uid: self.userInfo.userId)
                seal.fulfill_()
            }.catch { (_) in
                seal.fulfill_()
            }
        }
    }
    
    static func cleanUpAll() -> Promise<Void> {
        var wait = Promise<Void>()
        var promises = [
            MessageDataService.cleanUpAll(),
            LabelsDataService.cleanUpAll(),
            ContactDataService.cleanUpAll(),
            ContactGroupsDataService.cleanUpAll(),
            LocalNotificationService.cleanUpAll(),
            UserDataService.cleanUpAll(),
            LastUpdatedStore.cleanUpAll()
        ]
        #if !APP_EXTENSION
        promises.append(ServicePlanDataService.cleanUpAll())
        #endif
        for p in promises {
            wait = wait.then({ (_) -> Promise<Void> in
                return p
            })
        }
        return wait
    }
    
    var delegate : UserManagerSave?
    
    
    //weak var delegate : UsersManagerDelegate?
    
    public var apiService : APIService
    public var userinfo : UserInfo
    public var auth : AuthCredential

    var isUserSelectedUnreadFilterInInbox = false
    //TODO:: add a user status. logging in, expired, no key etc...

    //public let user

    public lazy var conversationStateService: ConversationStateService = { [unowned self] in
        let conversationFeatureFlagService = ConversationFeatureFlagService(apiService: self.apiService)
        return ConversationStateService(
            conversationFeatureFlagService: conversationFeatureFlagService,
            userDefaults: SharedCacheBase.getDefault(),
            viewMode: self.userinfo.viewMode
        )
    }()

    public lazy var reportService: BugDataService = { [unowned self] in
        let service = BugDataService(api: self.apiService)
        return service
    }()

    public lazy var contactService: ContactDataService = { [unowned self] in
        let service = ContactDataService(api: self.apiService,
                                         labelDataService: self.labelService,
                                         userID: self.userinfo.userId,
                                         coreDataService: sharedServices.get(by: CoreDataService.self),
                                         lastUpdatedStore: sharedServices.get(by: LastUpdatedStore.self), cacheService: self.cacheService)
        return service
    }()
    
    public lazy var contactGroupService: ContactGroupsDataService = { [unowned self] in
        let service = ContactGroupsDataService(api: self.apiService,
                                               labelDataService: self.labelService,
                                               coreDataServie: sharedServices.get(by: CoreDataService.self))
        return service
    }()
    
    weak var parentManager: UsersManager?
    
    public lazy var messageService: MessageDataService = { [unowned self] in
        let service = MessageDataService(api: self.apiService,
                                         userID: self.userinfo.userId,
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
        let shareQueueManager = sharedServices.get(by: QueueManager.self)
        shareQueueManager.registerHandler(service)
        return service
    }()
    
    public lazy var conversationService: ConversationProvider = { [unowned self] in
        let service = ConversationDataService(api: apiService,
                                              userID: userinfo.userId,
                                              coreDataService: sharedServices.get(by: CoreDataService.self),
                                              labelDataService: labelService,
                                              lastUpdatedStore: sharedServices.get(by: LastUpdatedStore.self), eventsService: eventsService,
                                              viewModeDataSource: self,
                                              queueManager: sharedServices.get(by: QueueManager.self))
        return service
    }()

    public lazy var labelService: LabelsDataService = { [unowned self] in
        let service = LabelsDataService(api: self.apiService, userID: self.userinfo.userId, coreDataService: sharedServices.get(by: CoreDataService.self), lastUpdatedStore: sharedServices.get(by: LastUpdatedStore.self), cacheService: self.cacheService)
        service.viewModeDataSource = self
        return service
    }()
    
    public lazy var userService: UserDataService = { [unowned self] in
        let service = UserDataService(check: false, api: self.apiService)
        return service
    }()
    
    
    public lazy var localNotificationService: LocalNotificationService = { [unowned self] in
        let service = LocalNotificationService(userID: self.userinfo.userId)
        return service
    }()
    
    public lazy var cacheService: CacheService = { [unowned self] in
        let service = CacheService(userID: self.userinfo.userId, lastUpdatedStore: self.lastUpdatedStore, coreDataService: sharedServices.get(by: CoreDataService.self))
        return service
    }()
    
    public lazy var eventsService: EventsFetching = { [unowned self] in
        let service = EventsService(userManager: self)
        return service
    }()
    
    private var lastUpdatedStore: LastUpdatedStoreProtocol {
        return sharedServices.get(by: LastUpdatedStore.self)
    }
    
    #if !APP_EXTENSION
    public lazy var sevicePlanService: ServicePlanDataService = { [unowned self] in
        let service = ServicePlanDataService(localStorage: userCachedStatus, apiService: self.apiService) // FIXME: SHOULD NOT BE ONE STORAGE FOR ALL
        return service
    }()
    #endif
    
    init(api: APIService, userinfo: UserInfo, auth: AuthCredential, parent: UsersManager) {
        self.userinfo = userinfo
        self.auth = auth
        self.apiService = api
        self.apiService.authDelegate = self
        self.parentManager = parent
        self.messageService.signin()
    }

    init(api: APIService) {
        self.userinfo = UserInfo.getDefault()
        self.auth = AuthCredential.none
        self.apiService = api
        self.apiService.authDelegate = self
    }
    
    public func isMatch(sessionID uid : String) -> Bool {
        return auth.sessionID == uid
    }
    
    func isExist(userName: String) -> Bool {
        for addr in self.userinfo.userAddresses {
            return addr.email.starts(with: userName)
        }
        return false
    }
    
    func isExist(userID: String) -> Bool {
        if userInfo.userId == userID {
            return true
        }
        return false
    }
    
    func save() {
        self.conversationStateService.userInfoHasChanged(viewMode: self.userinfo.viewMode)
        self.delegate?.onSave(userManger: self)
    }

    func fetchUserInfo() {
        _ = self.userService.fetchUserInfo(auth: self.auth).done { [weak self] info in
            guard let info = info else { return }
            self?.userinfo = info
            self?.save()
            #if !APP_EXTENSION
            guard let firstUser = self?.parentManager?.firstUser,
                  let self = self else { return }
            if firstUser.userInfo.userId == self.userInfo.userId {
                userCachedStatus.initialSwipeActionIfNeeded(leftToRight: info.swipeLeft, rightToLeft: info.swipeRight)
                
            }
            #endif
        }
    }

    func refreshFeatureFlags() {
        conversationStateService.refreshFlag()
    }

}

extension UserManager : AuthDelegate {
    func getToken(bySessionUID uid: String) -> AuthCredential? {
        guard auth.sessionID == uid else {
            assert(false, "Inadequate crerential requested")
            return nil
        }
        return auth
    }
    
    func onLogout(sessionUID uid: String) {
        //TODO:: Since the user manager can directly catch the onLogOut event. we can improve this logic to not use the NotificationCenter.
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
    
    func onForceUpgrade() {
        //TODO::
    }
}

extension UserManager : UserDataSource {
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
    
    
    var userInfo : UserInfo {
        get {
            return self.userinfo
        }
        
    }
    
    var addressPrivateKeys : [Data] {
        get {
            return self.userinfo.addressPrivateKeysArray
        }        
    }
    
    var authCredential : AuthCredential {
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
    
    func updateFromEvents(userInfoRes: [String : Any]?) {
        if let userData = userInfoRes {
            let newUserInfo = UserInfo(response: userData)
            userInfo.set(userinfo: newUserInfo)
            self.save()
        }
    }
    
    func updateFromEvents(userSettingsRes: [String : Any]?) {
        if let settings = userSettingsRes {
            userInfo.parse(userSettings: settings)
            self.save()
        }
    }
    func updateFromEvents(mailSettingsRes: [String : Any]?) {
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
    
    func getUnReadCount(by labelID: String) -> Promise<Int> {
        return self.labelService.unreadCount(by: labelID)
    }
}

/// Get values
extension UserManager {
    var defaultDisplayName : String {
        if let addr = userinfo.userAddresses.defaultAddress() {
            return addr.displayName
        }
        return displayName
    }
    
    var defaultEmail : String {
        if let addr = userinfo.userAddresses.defaultAddress() {
            return addr.email
        }
        return ""
    }
    
    var displayName: String {
        return userinfo.displayName.decodeHtml()
    }

    var addresses : [Address] {
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
            if let status = userCachedStatus.getDefaultSignaureSwitchStatus(uid: userInfo.userId) {
                return status
            } else {
                let oldStatus = userService.defaultSignatureStauts
                userCachedStatus.setDefaultSignatureSwitchStatus(uid: userInfo.userId, value: oldStatus)
                return oldStatus
            }
        }
        set {
            userCachedStatus.setDefaultSignatureSwitchStatus(uid: userInfo.userId, value: newValue)
        }
    }
    
    var showMobileSignature : Bool {
        get {
            #if Enterprise
            let isEnterprise = true
            #else
            let isEnterprise = false
            #endif
            let role = userInfo.role
            if role > 0 || isEnterprise {
                if let status = userCachedStatus.getMobileSignatureSwitchStatus(by: userInfo.userId) {
                    return status
                } else {
                    //Migrate from local cache
                    let status = self.userService.switchCacheOff == false
                    userCachedStatus.setMobileSignatureSwitchStatus(uid: userInfo.userId, value: status)
                    return status
                }
            } else {
                userCachedStatus.setMobileSignatureSwitchStatus(uid: userInfo.userId, value: true)
                return true
            } }
        set {
            userCachedStatus.setMobileSignatureSwitchStatus(uid: userInfo.userId, value: newValue)
        }
    }
    
    var mobileSignature : String {
        get {
            #if Enterprise
            let isEnterprise = true
            #else
            let isEnterprise = false
            #endif
            let role = userInfo.role
            if role > 0 || isEnterprise {
                return userCachedStatus.getMobileSignature(by: userInfo.userId)
            } else {
                userCachedStatus.removeMobileSignature(uid: userInfo.userId)
                return userCachedStatus.getMobileSignature(by: userInfo.userId)
            }
        }
        set {
            userCachedStatus.setMobileSignature(uid: userInfo.userId, signature: newValue)
        }
    }

    var isEnableFolderColor: Bool {
        return userinfo.enableFolderColor == 1
    }

    var isInheritParentFolderColor: Bool {
        return userinfo.inheritParentFolderColor == 1
    }
}

extension UserManager: ViewModeDataSource {
    func getCurrentViewMode() -> ViewMode {
        return conversationStateService.viewMode
    }
}
