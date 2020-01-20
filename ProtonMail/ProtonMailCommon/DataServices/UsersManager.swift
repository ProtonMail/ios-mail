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


import Foundation
import AwaitKit
import PromiseKit
import Keymaker
import Crypto

protocol UsersManagerDelegate: class {
    func migrating()
    func session()
}

/// manager all the users and there services
class UsersManager : Service {
    
    struct CoderKey {
           
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
        
        static let roleSwitchCache = "roleSwitchCache"
        static let defaultSignatureStatus = "defaultSignatureStatus"
        
        static let firstRunKey = "FirstRunKey"
    }
   
    /// Server's config like url port path etc..
    var serverConfig : APIServerConfig
    /// the interface for talking to UI
    weak var delegate : UsersManagerDelegate?
    
    /// Credential
//    var userCredentials : [AuthCredential] = []
    /// users
    var users : [UserManager] = []
//    var apiServices : [APIService] = []
    
    /// global services
    
    /// device level service
    
    /// user list
    
    /// signIn manager application level
    
    init(server: APIServerConfig, delegate : UsersManagerDelegate?) {
        self.serverConfig = server
        self.delegate = delegate
    }
    
    /**
     add a new user after login
     
     - Parameter auth: auth credential
     - Parameter user: user information
     **/
    func add(auth: AuthCredential, user: UserInfo) {
        let session = auth.sessionID
        let userID = user.userId
        let apiConfig = serverConfig
        let apiService = APIService(config: apiConfig, sessionUID: session, userID: userID)
        let newUser = UserManager(api: apiService, userinfo: user, auth: auth)
        users.append(newUser)
        
        self.save()
    }
    
    func update(auth: AuthCredential, user: UserInfo) {
        for i in 0 ..< users.count {
            let usr = users[i]
            if usr.isMatch(sessionID: auth.sessionID) {
                usr.auth = auth
                usr.userinfo = user
            }
        }
        
//        let session = auth.sessionID
//        //        if session != user.userId {
//        //            //error  //TODO::
//        //        }
//        let apiConfig = serverConfig
//        let apiService = APIService(config: apiConfig, sessionUID: session)
//        let newUser = UserManager(api: apiService, userinfo: user, auth: auth)
//        users.append(newUser)
//
        self.save()
    }
    
    func get(byID : String) {
        
    }
    
    func user(at index: Int) -> UserManager? {
        if users.count > index {
            return users[index]
        }
        return nil
    }
    
    var count: Int {
        return users.count
    }
    
    func active(uid: String) {
        if let index = self.users.enumerated().first(where: { $1.isMatch(sessionID: uid) })?.offset {
            self.users.swapAt(0, index)
        }
        self.save()
    }
    
    func active(index: Int) {
        guard self.users.count > 0, index < users.count, index != 0 else {
            return
        }
        
        self.users.swapAt(0, index)
        self.save()
//        uers.swap(at)
//
//        swap(&cellOrder[0], &cellOrder[1])
    }
    //TODO:: referance could try to use weak.
    var firstUser : UserManager? {
        return users.first
    }
    
    
//    lazy var apiService: APIService = {
//        let service = APIService(config: usersManager.serverConfig, userID: "")
//        return service
//    }()
    
    func getAPIService (bySessionID uid : String)  -> APIService? {
        let found = users.filter { (user) -> Bool in
            return user.isMatch(sessionID: uid)
        }
        guard let user = found.first else {
            return nil
        }
        return user.apiService
    }
    
    func getUser (bySessionID uid : String)  -> UserManager? {
         let found = users.filter { (user) -> Bool in
             return user.isMatch(sessionID: uid)
         }
         guard let user = found.first else {
             return nil
         }
         return user
     }
    
    func isExist(_ userName: String) -> Bool {
        var check = userName
        
        if !userName.contains(check: "@") {
            check = check + "@"
        }
        
        for user in users {
            if user.isExist(check) {
                return true
            }
        }
        return false
    }
    
    
    private func oldFetch() -> AuthCredential? {
//        class func fetchFromKeychain() -> AuthCredential? {
//                       guard let mainKey = keymaker.mainKey,
//                           let encryptedData = KeychainWrapper.keychain.data(forKey: Key.keychainStore),
//                           case let locked = Locked<Data>(encryptedValue: encryptedData),
//                           let data = try? locked.unlock(with: mainKey),
//                           let authCredential = AuthCredential.unarchive(data: data as NSData) else
//                       {
//                           return nil
//                       }
//
//                       return authCredential
//                   }
        return nil
    }
    
    func tryRestore() {
        // try new version first
        guard let mainKey = keymaker.mainKey else {
            return
        }
        
        guard let encryptedAuthData = KeychainWrapper.keychain.data(forKey: CoderKey.authKeychainStore) else {
            return
        }
        let authlocked = Locked<[AuthCredential]>(encryptedValue: encryptedAuthData)
        guard let auths = try? authlocked.unlock(with: mainKey) else {
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
        
        //TODO:: temp
        if users.count > 0 {
            return
        }
        
        for (auth, user) in zip(auths, userinfos) {
            let session = auth.sessionID
            let userID = user.userId
            let apiConfig = serverConfig
            let apiService = APIService(config: apiConfig, sessionUID: session, userID: userID)
            let newUser = UserManager(api: apiService, userinfo: user, auth: auth)
            users.append(newUser)
        }
        
//        let authList = self.users.compactMap{ $0.auth }
//        userCachedStatus.isForcedLogout = false
//        guard let lockedAuth = try? Locked<[AuthCredential]>.init(encryptedValue: T##Data: authList, with: mainKey) else
//        {
//            return
//        }
//        KeychainWrapper.keychain.set(lockedAuth.encryptedValue, forKey: CoderKey.authKeychainStore)
//
//        let userList = self.users.compactMap{ $0.userinfo }
//        guard let lockedUsers = try? Locked<[UserInfo]>(clearValue: userList, with: mainKey) else {
//            return
//        }
//        SharedCacheBase.getDefault()?.set(lockedUsers.encryptedValue, forKey: CoderKey.usersInfo)
//        SharedCacheBase.getDefault().synchronize()
        
        
        // then try the older version
        
        
        
        // clean up
        
        
//        // MARK: - Private variables
//
//        guard let mainKey = keymaker.mainKey,
//            let cypherData = SharedCacheBase.getDefault()?.data(forKey: CoderKey.userInfo) else
//        {
//            return nil
//        }
//
//                let locked = Locked<UserInfo>(encryptedValue: cypherData)
//                return try? locked.unlock(with: mainKey)
//            }
//            set {
//                self.saveUserInfo(newValue)
//            }
//        }
//        guard let userInfo = sharedUserDataService.userInfo,
//            let auth = AuthCredential.fetchFromKeychain() else {
//                return
//        }
//        self.add(auth: auth, user: userInfo)
    }
    
    func save() {
        guard let mainKey = keymaker.mainKey else {
            return
        }
        
        let authList = self.users.compactMap{ $0.auth }
        userCachedStatus.isForcedLogout = false
        guard let lockedAuth = try? Locked<[AuthCredential]>.init(clearValue: authList, with: mainKey) else
        {
            return
        }
        KeychainWrapper.keychain.set(lockedAuth.encryptedValue, forKey: CoderKey.authKeychainStore)
        
        let userList = self.users.compactMap{ $0.userinfo }
        guard let lockedUsers = try? Locked<[UserInfo]>(clearValue: userList, with: mainKey) else {
            return
        }
        SharedCacheBase.getDefault()?.set(lockedUsers.encryptedValue, forKey: CoderKey.usersInfo)
        SharedCacheBase.getDefault().synchronize()
    }
}




/// cache login check
extension UsersManager {
    func launchCleanUpIfNeeded() {
        self.users.forEach { user in
            user.messageService.launchCleanUpIfNeeded()
        }
    }
    
    func logout(user: UserManager) {
        user.messageService.cleanUp()
        user.labelService.cleanUp()
        user.contactService.clean()
        user.localNotificationService.unscheduleAllPendingNotifications()
        user.userService.signOutFromServer() // TODO: make it work
        self.remove(user: user)
    }
    
    func remove(user: UserManager) {
        if let nextFirst = self.users.first(where: { !$0.isMatch(sessionID: user.auth.sessionID) })?.auth.sessionID {
            self.active(uid: nextFirst)
        }
        self.users.removeAll(where: { $0.isMatch(sessionID: user.auth.sessionID) })
        self.save()
    }
    
    internal func clean() { //TODO:: fix later
        SharedCacheBase.getDefault()?.remove(forKey: CoderKey.usersInfo)
        KeychainWrapper.keychain.remove(forKey: CoderKey.authKeychainStore)
        KeychainWrapper.keychain.remove(forKey: CoderKey.atLeastOneLoggedIn)
        
        UserTempCachedStatus.backup()
        
        
        sharedUserDataService.signOut(true)
                
        userCachedStatus.signOut()
        sharedServices.get(by: UsersManager.self).users.forEach { user in
            user.userService.signOut(true)
            user.messageService.launchCleanUpIfNeeded()
        }

        
        // device level service
        keymaker.wipeMainKey()
        // good opportunity to remove all temp folders
        FileManager.default.cleanTemporaryDirectory()
        // some tests are messed up without tmp folder, so let's keep it for consistency
        #if targetEnvironment(simulator)
        try? FileManager.default.createDirectory(at: FileManager.default.temporaryDirectoryUrl, withIntermediateDirectories: true, attributes:
                nil)
        #endif
    }
    
    func hasUsers() -> Bool {
        return KeychainWrapper.keychain.data(forKey: CoderKey.authKeychainStore) != nil &&
            SharedCacheBase.getDefault()?.value(forKey: CoderKey.usersInfo) != nil
    }
    
    var isMailboxPasswordStored : Bool {
        return KeychainWrapper.keychain.string(forKey: CoderKey.atLeastOneLoggedIn) != nil
    }
    
    func loggedIn() {
        KeychainWrapper.keychain.set("LoggedIn", forKey: CoderKey.atLeastOneLoggedIn)
    }
    
    func loggedOutAll() {
        for user in users {
            lastUpdatedStore.removeUpdateTime(by: user.userinfo.userId)
        }
        KeychainWrapper.keychain.remove(forKey: CoderKey.atLeastOneLoggedIn)
        
        self.users.removeAll()
    }
}
