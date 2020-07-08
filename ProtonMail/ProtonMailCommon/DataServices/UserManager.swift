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
import PMAuthentication

/// TODO:: this is temp
protocol UserDataSource : class {
    var mailboxPassword : String { get }
    var newSchema : Bool {get}
    var addressKeys : [Key] { get }
    var userPrivateKeys : Data { get }
    var userInfo : UserInfo { get }
    var addressPrivateKeys : Data { get }
    var authCredential : AuthCredential { get }
    func getAddressKey(address_id : String) -> Key?
    func getAddressPrivKey(address_id : String) -> String
    
    func updateFromEvents(userInfoRes: [String : Any]?)
    func updateFromEvents(userSettingsRes: [String : Any]?)
    func updateFromEvents(mailSettingsRes: [String : Any]?)
    func update(usedSpace: Int64)
    func setFromEvents(addressRes: Address)
    func deleteFromEvents(addressIDRes: String)
}

protocol UserManagerSave : class {
    func onSave(userManger: UserManager)
}

///
class UserManager : Service, HasLocalStorage {
    func cleanUp() {
        self.messageService.cleanUp()
        self.labelService.cleanUp()
        self.contactService.cleanUp()
        self.contactGroupService.cleanUp()
        self.localNotificationService.cleanUp()
        self.userService.cleanUp()
        userCachedStatus.removeMobileSignature(uid: userInfo.userId)
        userCachedStatus.removeMobileSignatureSwitchStatus(uid: userInfo.userId)
        userCachedStatus.removeDefaultSignatureSwitchStatus(uid: userInfo.userId)
        #if !APP_EXTENSION
        self.sevicePlanService.cleanUp()
        #endif
    }
    
    static func cleanUpAll() {
        MessageDataService.cleanUpAll()
        LabelsDataService.cleanUpAll()
        ContactDataService.cleanUpAll()
        ContactGroupsDataService.cleanUpAll()
        LocalNotificationService.cleanUpAll()
        UserDataService.cleanUpAll()
        LastUpdatedStore.cleanUpAll()
        #if !APP_EXTENSION
        ServicePlanDataService.cleanUpAll()
        #endif
    }
    
    func launchCleanUpIfNeeded() {
        self.messageService.launchCleanUpIfNeeded()
    }
    
    var delegate : UserManagerSave?
    
    
    //weak var delegate : UsersManagerDelegate?
    
    public let apiService : APIService
    public var userinfo : UserInfo
    public var auth : AuthCredential
    
    //TODO:: add a user status. logging in, expired, no key etc...

    //public let user
    public lazy var reportService: BugDataService = {
        let service = BugDataService(api: self.apiService)
        return service
    }()
    public lazy var contactService: ContactDataService = {
        let service = ContactDataService(api: self.apiService,
                                         labelDataService: self.labelService,
                                         userID: self.userinfo.userId)
        return service
    }()
    
    public lazy var contactGroupService: ContactGroupsDataService = {
        let service = ContactGroupsDataService(api: self.apiService,
                                               labelDataService: self.labelService)
        return service
    }()
    
    weak var parentManager: UsersManager?
    
    public lazy var messageService: MessageDataService = {
        let service = MessageDataService(api: self.apiService,
                                         userID: self.userinfo.userId,
                                         labelDataService: self.labelService,
                                         contactDataService: self.contactService,
                                         localNotificationService: self.localNotificationService,
                                         usersManager: self.parentManager)
        service.userDataSource = self
        return service
    }()
    
    public lazy var labelService: LabelsDataService = {
        let service = LabelsDataService(api: self.apiService, userID: self.userinfo.userId)
        return service
    }()
    
    public lazy var userService: UserDataService = {
        let service = UserDataService(check: false, api: self.apiService)
        return service
    }()
    
    
    public lazy var localNotificationService: LocalNotificationService = {
        let service = LocalNotificationService(userID: self.userinfo.userId)
        return service
    }()
   
    
    #if !APP_EXTENSION
    public lazy var sevicePlanService: ServicePlanDataService = {
        let service = ServicePlanDataService(localStorage: userCachedStatus, apiService: self.apiService) // FIXME: SHOULD NOT BE ONE STORAGE FOR ALL
        return service
    }()
    #endif
    
    init(api: APIService, userinfo: UserInfo, auth: AuthCredential, parent: UsersManager) {
        self.userinfo = userinfo
        self.auth = auth
        self.apiService = api
        self.apiService.sessionDeleaget = self
        self.parentManager = parent
    }

    init(api: APIService) {
        self.userinfo = UserInfo.getDefault()
        self.auth = AuthCredential.none
        self.apiService = api
        self.apiService.sessionDeleaget = self
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
        self.delegate?.onSave(userManger: self)
    }
}

extension UserManager : SessionDelegate {
    func getToken(bySessionUID uid: String) -> AuthCredential? {
        guard auth.sessionID == uid else {
            assert(false, "Inadequate crerential requested")
            return nil
        }
        return auth
    }
    
    func updateAuthCredential(_ credential: PMAuthentication.Credential) {
        self.auth.udpate(sessionID: credential.UID, accessToken: credential.accessToken, refreshToken: credential.refreshToken, expiration: credential.expiration)
        self.save()
    }
    
    func updateAuth(_ credential: AuthCredential) {
        self.auth.udpate(sessionID: credential.sessionID, accessToken: credential.accessToken, refreshToken: credential.refreshToken, expiration: credential.expiration)
        self.save()
    }
}


extension UserManager : UserDataSource {
    func getAddressPrivKey(address_id: String) -> String {
         return ""
    }
    
    func getAddressKey(address_id: String) -> Key? {
        return self.userInfo.getAddressKey(address_id: address_id)
    }
    
    var userPrivateKeys: Data {
        get {
            self.userinfo.userPrivateKeys
        }
    }
    
    var addressKeys: [Key] {
        get {
            return self.userinfo.addressKeys
        }
    }
    
    var newSchema: Bool {
        get {
            return self.userinfo.newSchema
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
    
    var addressPrivateKeys : Data {
        get {
            return self.userinfo.addressPrivateKeys
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
        if let index = self.userInfo.userAddresses.firstIndex(where: { $0.address_id == address.address_id }) {
            self.userInfo.userAddresses.remove(at: index)
        }
        self.userInfo.userAddresses.append(address)
        self.userInfo.userAddresses.sort(by: { (v1, v2) -> Bool in
            return v1.order < v2.order
        })
        self.save()
    }
    
    func deleteFromEvents(addressIDRes addressID: String) {
        if let index = self.userInfo.userAddresses.firstIndex(where: { $0.address_id == addressID }) {
            self.userInfo.userAddresses.remove(at: index)
            self.save()
        }
    }
    
    func getUnReadCount(by labelID: String) -> Int {
        self.labelService.unreadCount(by: labelID)
    }
}


/// Get values
extension UserManager {
    var defaultDisplayName : String {
        if let addr = userinfo.userAddresses.defaultAddress() {
            return addr.display_name
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
        return userinfo.userAddresses
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
    
    
    
}
