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
    
    public lazy var messageService: MessageDataService = {
        let service = MessageDataService(api: self.apiService,
                                         userID: self.userinfo.userId,
                                         labelDataService: self.labelService,
                                         contactDataService: self.contactService,
                                         localNotificationService: self.localNotificationService)
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
    
    init(api: APIService, userinfo: UserInfo, auth: AuthCredential) {
        self.userinfo = userinfo
        self.auth = auth
        self.apiService = api
        self.apiService.sessionDeleaget = self
    }

    init(api: APIService) {
        self.userinfo = UserInfo.getDefault()
        self.auth = AuthCredential.getDefault()
        self.apiService = api
        self.apiService.sessionDeleaget = self
    }
    
    public func isMatch(sessionID uid : String) -> Bool {
        return auth.sessionID == uid
    }
    
    func isExist(_ userName: String) -> Bool {
        for addr in self.userinfo.userAddresses {
            return addr.email.starts(with: userName)
        }
        return false
    }
    
    func save() {
        self.delegate?.onSave(userManger: self)
    }
}

extension UserManager : SessionDelegate {
    func getToken(bySessionUID uid: String) -> String? {
        //TODO:: check session UID later
        return auth.token
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
            return self.auth.password
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
    
    var showMobileSignature : Bool {
        get {
            #if Enterprise
            let isEnterprise = true
            #else
            let isEnterprise = false
            #endif
            //TODO:: fix me
            let role = userInfo.role
            if role > 0 || isEnterprise {
                return self.userService.switchCacheOff == false
            } else {
                self.userService.switchCacheOff = false
                return true
            } }
        set {
            self.userService.switchCacheOff = (newValue == false)
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
                return userCachedStatus.mobileSignature
            } else {
                userCachedStatus.resetMobileSignature()
                return userCachedStatus.mobileSignature
            }
        }
        set {
            userCachedStatus.mobileSignature = newValue
        }
    }
    
    
    
}
