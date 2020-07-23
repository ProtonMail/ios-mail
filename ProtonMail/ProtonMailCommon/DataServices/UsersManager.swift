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
import PMKeymaker
import Crypto

protocol UsersManagerDelegate: class {
    func migrating()
    func session()
}

/// manager all the users and there services
class UsersManager : Service, Migrate {
    
    enum Version : Int {
        static let version : Int = 1 // this is app cache version
        case v0 = 0
        case v1 = 1
    }
    
    /// saver for versioning
    private let versionSaver: Saver<Int>
    internal var latestVersion: Int
    internal var currentVersion: Int {
        get {
            return self.versionSaver.get() ?? 0
        }
        set {
            self.versionSaver.set(newValue: newValue)
        }
    }
        
    internal var supportedVersions: [Int] = [Version.v0.rawValue,
                                             Version.v1.rawValue]
    internal var initalRun: Bool {
        get {
            return currentVersion == 0 &&
                KeychainWrapper.keychain.data(forKey: CoderKey.keychainStore) == nil &&
                KeychainWrapper.keychain.data(forKey: CoderKey.authKeychainStore) == nil &&
                KeychainWrapper.keychain.data(forKey: CoderKey.userInfo) == nil &&
                KeychainWrapper.keychain.data(forKey: CoderKey.usersInfo) == nil
        }
    }
    
    func rebuild(reason: RebuildReason) {
        self.cleanLagacy()
        self.currentVersion = self.latestVersion
    }
    
    func cleanLagacy() {
        // Clear up the old stuff on fresh installs also
    }
    
    func logout() {
        self.versionSaver.set(newValue: nil)
    }
    
    func migrate(from verfrom: Int, to verto: Int) -> Bool {
        switch (verfrom, verto) {
        case (0, 1):
            return self.migrate_0_1()
        default:
            return false
        }
    }
    
    struct CoderKey {
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
        
        static let roleSwitchCache = "roleSwitchCache"
        static let defaultSignatureStatus = "defaultSignatureStatus"
        
        static let firstRunKey = "FirstRunKey"
        static let disconnectedUsers = "disconnectedUsers"
    }
   
    /// Server's config like url port path etc..
    var serverConfig : APIServerConfig
    /// the interface for talking to UI
    weak var delegate : UsersManagerDelegate?
    
    /// Credential
//    var userCredentials : [AuthCredential] = []
    /// users
    var users : [UserManager] = [] {
        didSet {
            userCachedStatus.primaryUserSessionId = users.first?.auth.sessionID
        }
    }
//    var apiServices : [APIService] = []
    
    /// global services
    
    /// device level service
    
    /// user list
    
    /// signIn manager application level
    
    init(server: APIServerConfig, delegate : UsersManagerDelegate?) {
        self.serverConfig = server
        self.delegate = delegate
        
        /// for migrate
        self.latestVersion = Version.version
        
        self.versionSaver = UserDefaultsSaver<Int>(key: CoderKey.Version)
    }
    
    /**
     add a new user after login
     
     - Parameter auth: auth credential
     - Parameter user: user information
     **/
    func add(auth: AuthCredential, user: UserInfo) {
        let session = auth.sessionID
        let userID = user.userId
//        auth.userID = userID
        let apiConfig = serverConfig
        let apiService = APIService(config: apiConfig, sessionUID: session, userID: userID)
        let newUser = UserManager(api: apiService, userinfo: user, auth: auth, parent: self)
        self.removeDisconnectedUser(.init(defaultDisplayName: newUser.defaultDisplayName,
                          defaultEmail: newUser.defaultEmail,
                          userID: user.userId))
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
    
    func get(not userID: String) -> UserManager?  {
        for user in users {
            if user.userInfo.userId != userID {
                return user
            }
        }
        return nil
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
    
    func getUser(byUserId userId: String) -> UserManager? {
        let found = users.filter { user -> Bool in
            return user.userInfo.userId == userId
        }
        guard let user = found.first else {
            return nil
        }
        return user
    }
    
    func isExist(userName: String) -> Bool {
        var check = userName
        
        if !userName.contains(check: "@") {
            check = check + "@"
        }
        
        for user in users {
            if user.isExist(userID: check) {
                return true
            }
        }
        return false
    }
    
    func isExist(userID: String) -> Bool {
        for user in users {
            if user.isExist(userID: userID) {
                return true
            }
        }
        return false
    }
    
    //tempery mirgration. will change this to version check
    func hasUserName() -> Bool {
        return SharedCacheBase.getDefault()?.data(forKey: CoderKey.username) != nil
    }
    
    private func oldUserInfo() -> UserInfo? {
        guard let mainKey = keymaker.mainKey,
            let cypherData = SharedCacheBase.getDefault()?.data(forKey: CoderKey.userInfo) else
        {
            return nil
        }
        
        let locked = Locked<UserInfo>(encryptedValue: cypherData)
        return try? locked.unlock(with: mainKey)
    }
    
    private func oldAuthFetch() -> AuthCredential? {
        guard let mainKey = keymaker.mainKey,
            let encryptedData = KeychainWrapper.keychain.data(forKey: CoderKey.keychainStore),
            case let locked = Locked<Data>(encryptedValue: encryptedData),
            let data = try? locked.unlock(with: mainKey),
            let authCredential = AuthCredential.unarchive(data: data as NSData) else
        {
            return nil
        }
        return authCredential
    }
    
    private func oldMailboxPassword() -> String? {
        guard let cypherBits = KeychainWrapper.keychain.data(forKey: CoderKey.mailboxPassword),
            let key = keymaker.mainKey else
        {
            return nil
        }
        let locked = Locked<String>(encryptedValue: cypherBits)
        return try? locked.unlock(with: key)
    }
    
    private func oldUserName() -> String? {
        guard let mainKey = keymaker.mainKey,
            let cypherData = SharedCacheBase.getDefault()?.data(forKey: CoderKey.username) else
        {
            return nil
        }
        
        let locked = Locked<String>(encryptedValue: cypherData)
        return try? locked.unlock(with: mainKey)
    }
    
    func tryRestore() {
        // try new version first
        guard let mainKey = keymaker.mainKey else {
            return
        }
        
        if let oldAuth = oldAuthFetch(),  let user = oldUserInfo() {
            let session = oldAuth.sessionID
            let userID = user.userId
            let apiConfig = serverConfig
            let apiService = APIService(config: apiConfig, sessionUID: session, userID: userID)
            let newUser = UserManager(api: apiService, userinfo: user, auth: oldAuth, parent: self)
            newUser.delegate = self
            if let pwd = oldMailboxPassword() {
                oldAuth.udpate(password: pwd)
            }
            
            user.twoFactor = SharedCacheBase.getDefault().integer(forKey: CoderKey.twoFAStatus)
            user.passwordMode = SharedCacheBase.getDefault().integer(forKey: CoderKey.userPasswordMode)
            users.append(newUser)
            self.save()
            //Then clear lagcy
            SharedCacheBase.getDefault()?.remove(forKey: CoderKey.username)
            KeychainWrapper.keychain.remove(forKey: CoderKey.keychainStore)
            
        } else {
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
                let newUser = UserManager(api: apiService, userinfo: user, auth: auth, parent: self)
                newUser.delegate = self
                users.append(newUser)
            }
        }
        self.loggedIn()
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
//    }
    
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

extension UsersManager : UserManagerSave {
    func onSave(userManger: UserManager) {
        self.save()
    }
}

/// cache login check
extension UsersManager {
    func launchCleanUpIfNeeded() {
        self.users.forEach { $0.launchCleanUpIfNeeded() }
    }
    
    func logout(user: UserManager, shouldAlert: Bool = false) {
        user.cleanUp()
        
        if let primary = self.users.first, primary.isMatch(sessionID: user.auth.sessionID) {
            self.remove(user: user)
            NotificationCenter.default.post(name: Notification.Name.didPrimaryAccountLogout, object: nil)
            NSError.alertBadTokenToast()
        } else {
            self.remove(user: user)
        }
        
        if self.users.isEmpty {
            self.clean()
        } else if shouldAlert {
            String(format: LocalString._logout_account_switched_when_token_revoked,
                   arguments: [user.defaultEmail,
                               self.users.first!.defaultEmail]).alertToast()
        }
    }
    
    func remove(user: UserManager) {
        if let nextFirst = self.users.first(where: { !$0.isMatch(sessionID: user.auth.sessionID) })?.auth.sessionID {
            self.active(uid: nextFirst)
        }
        self.disconnectedUsers.append(.init(defaultDisplayName: user.defaultDisplayName,
                                         defaultEmail: user.defaultEmail,
                                         userID: user.userInfo.userId))
        self.users.removeAll(where: { $0.isMatch(sessionID: user.auth.sessionID) })
        self.save()
    }
    
    internal func clean() { 
        UserManager.cleanUpAll()
        
        SharedCacheBase.getDefault()?.remove(forKey: CoderKey.usersInfo)
        KeychainWrapper.keychain.remove(forKey: CoderKey.keychainStore)
        KeychainWrapper.keychain.remove(forKey: CoderKey.authKeychainStore)
        KeychainWrapper.keychain.remove(forKey: CoderKey.atLeastOneLoggedIn)
        KeychainWrapper.keychain.remove(forKey: CoderKey.disconnectedUsers)
        
        self.currentVersion = latestVersion
        
        UserTempCachedStatus.backup()
        
        
        sharedUserDataService.signOut(true)
                
        userCachedStatus.signOut()
        self.users.forEach { user in
            user.userService.signOut(true)
            user.messageService.launchCleanUpIfNeeded()
        }
        self.users = []
        self.save()
        
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
        // Have this value after 1.12.0
        let hasUsersInfo = SharedCacheBase.getDefault()?.value(forKey: CoderKey.usersInfo) != nil
        
        // Workaround to fix MAILIOS-150
        // Method that checks signin or not before 1.11.17
        let users = sharedServices.get(by: UsersManager.self) //TODO:: improve this line
        let isMailboxPasswordStored = KeychainWrapper.keychain.data(forKey: CoderKey.mailboxPassword) != nil
        let isSignIn = users.hasUserName() && isMailboxPasswordStored
        
        return KeychainWrapper.keychain.data(forKey: CoderKey.authKeychainStore) != nil && (hasUsersInfo || isSignIn)
    }
    
    var isPasswordStored : Bool {
        return KeychainWrapper.keychain.data(forKey: CoderKey.mailboxPassword) != nil ||
            KeychainWrapper.keychain.string(forKey: CoderKey.atLeastOneLoggedIn) != nil
    }
    
    var isMailboxPasswordStored : Bool {
        return KeychainWrapper.keychain.string(forKey: CoderKey.atLeastOneLoggedIn) != nil
    }
    
    func loggedIn() {
        KeychainWrapper.keychain.set("LoggedIn", forKey: CoderKey.atLeastOneLoggedIn)
    }
    
    func loggedOutAll() {
        for user in users {
            self.logout(user: user)
        }
    }
    
    func freeAccountNum() -> Int {
        var count = 0
        for user in users {
            if !user.isPaid {
                count = count + 1
            }
        }
        return count
    }
}

extension UsersManager {
    struct DisconnectedUserHandle: Codable, Equatable {
        var defaultDisplayName: String
        var defaultEmail: String
        var userID: String
        
        static func ==(lhv: DisconnectedUserHandle, rhv: DisconnectedUserHandle) -> Bool {
            return lhv.userID == rhv.userID
        }
    }
    
    func removeDisconnectedUser(_ handle: DisconnectedUserHandle) {
        self.disconnectedUsers.removeAll(where: { $0 == handle })
    }
    
    func disconnectedUser(at: Int) -> DisconnectedUserHandle? {
        let all = self.disconnectedUsers
        return at < all.count ? all[at] : nil
    }
    
    /// logged out users that should be visible in the Account Manager screen for faster log in. Persisted until logout of last user, protected with MainKey.
    var disconnectedUsers: Array<DisconnectedUserHandle> {
        get {
            // TODO: this locking/unlocking can be refactored to be @propertyWrapper on iOS 5.1
            guard let mainKey = keymaker.mainKey,
                let encryptedData = KeychainWrapper.keychain.data(forKey: CoderKey.disconnectedUsers),
                case let locked = Locked<Data>(encryptedValue: encryptedData),
                let data = try? locked.unlock(with: mainKey),
                let loggedOutUserHandles = try? JSONDecoder().decode(Array<DisconnectedUserHandle>.self, from: data) else
            {
                return []
            }
            return loggedOutUserHandles
        }
        set {
            guard let mainKey = keymaker.mainKey,
                let data = try? JSONEncoder().encode(newValue),
                let locked = try? Locked(clearValue: data, with: mainKey) else
            {
                PMLog.D("Failed to save disconnectedUsers to keychain")
                return
            }
            KeychainWrapper.keychain.set(locked.encryptedValue, forKey: CoderKey.disconnectedUsers)
        }
    }
}



extension UsersManager {
    func migrate_0_1() -> Bool {
        guard let mainKey = keymaker.mainKey else {
            return false
        }
        
        if let lagcyPwd = self.oldMailboxPasswordLagcy(), let locked = try? Locked(clearValue: lagcyPwd, with: mainKey) {
            KeychainWrapper.keychain.set(locked.encryptedValue, forKey: CoderKey.mailboxPassword)
        }
        if let lagcyName = oldUserNameLagcy(), let locked = try? Locked(clearValue: lagcyName, with: mainKey)  {
            KeychainWrapper.keychain.set(locked.encryptedValue, forKey: CoderKey.username)
        }
        userCachedStatus.migrateLagcy()
        
        // check the older auth and older user format first
        if let oldAuth = oldAuthFetchLagcy(),  let user = oldUserInfoLagcy() {
            let session = oldAuth.sessionID
            let userID = user.userId
            let apiConfig = serverConfig
            let apiService = APIService(config: apiConfig, sessionUID: session, userID: userID)
            let newUser = UserManager(api: apiService, userinfo: user, auth: oldAuth, parent: self)
            newUser.delegate = self
            if let pwd = oldMailboxPassword() {
                oldAuth.udpate(password: pwd)
            }
            user.twoFactor = SharedCacheBase.getDefault().integer(forKey: CoderKey.twoFAStatus)
            user.passwordMode = SharedCacheBase.getDefault().integer(forKey: CoderKey.userPasswordMode)
            users.append(newUser)
            self.save()
            //Then clear lagcy
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
            guard let userinfos = try? userslocked.lagcyUnlock(with: mainKey)  else {
                return false
            }
            
            guard userinfos.count == auths.count else {
                return false
            }
            
            //TODO:: temp
            if users.count > 0 {
                return false
            }
            
            for (auth, user) in zip(auths, userinfos) {
                let session = auth.sessionID
                let userID = user.userId
                let apiConfig = serverConfig
                let apiService = APIService(config: apiConfig, sessionUID: session, userID: userID)
                let newUser = UserManager(api: apiService, userinfo: user, auth: auth, parent: self)
                newUser.delegate = self
                users.append(newUser)
            }
            
            //save to the newer version
            self.save()
            
            
            let disconnectedUsers = self.disconnedUsersLagcy()
            if let data = try? JSONEncoder().encode(disconnectedUsers),
                let locked = try? Locked(clearValue: data, with: mainKey) {
                KeychainWrapper.keychain.set(locked.encryptedValue, forKey: CoderKey.disconnectedUsers)
            }
            return true
        }
        return false
    }
    
    func oldAuthFetchLagcy() -> AuthCredential? {
        guard let mainKey = keymaker.mainKey,
            let encryptedData = KeychainWrapper.keychain.data(forKey: CoderKey.keychainStore),
            case let locked = Locked<Data>(encryptedValue: encryptedData),
            let data = try? locked.lagcyUnlock(with: mainKey),
            let authCredential = AuthCredential.unarchive(data: data as NSData) else
        {
            return nil
        }
        return authCredential
    }
    
    func oldUserInfoLagcy() -> UserInfo? {
        guard let mainKey = keymaker.mainKey,
            let cypherData = SharedCacheBase.getDefault()?.data(forKey: CoderKey.userInfo) else
        {
            return nil
        }
        let locked = Locked<UserInfo>(encryptedValue: cypherData)
        return try? locked.lagcyUnlock(with: mainKey)
    }
    
    func oldMailboxPasswordLagcy() -> String? {
        guard let cypherBits = KeychainWrapper.keychain.data(forKey: CoderKey.mailboxPassword),
            let key = keymaker.mainKey else
        {
            return nil
        }
        let locked = Locked<String>(encryptedValue: cypherBits)
        return try? locked.lagcyUnlock(with: key)
    }
    
    func oldUserNameLagcy() -> String? {
        guard let mainKey = keymaker.mainKey,
            let cypherData = SharedCacheBase.getDefault()?.data(forKey: CoderKey.username) else
        {
            return nil
        }
        
        let locked = Locked<String>(encryptedValue: cypherData)
        return try? locked.lagcyUnlock(with: mainKey)
    }
    
    
    func disconnedUsersLagcy() -> Array<DisconnectedUserHandle> {
        // TODO: this locking/unlocking can be refactored to be @propertyWrapper on iOS 5.1
        guard let mainKey = keymaker.mainKey,
            let encryptedData = KeychainWrapper.keychain.data(forKey: CoderKey.disconnectedUsers),
            case let locked = Locked<Data>(encryptedValue: encryptedData),
            let data = try? locked.lagcyUnlock(with: mainKey),
            let loggedOutUserHandles = try? JSONDecoder().decode(Array<DisconnectedUserHandle>.self, from: data) else
        {
            return []
        }
        return loggedOutUserHandles
        
        
//        var disconnectedUsers: Array<DisconnectedUserHandle> {
//            get {
//                // TODO: this locking/unlocking can be refactored to be @propertyWrapper on iOS 5.1
//                guard let mainKey = keymaker.mainKey,
//                    let encryptedData = KeychainWrapper.keychain.data(forKey: CoderKey.disconnectedUsers),
//                    case let locked = Locked<Data>(encryptedValue: encryptedData),
//                    let data = try? locked.unlock(with: mainKey, new: true),
//                    let loggedOutUserHandles = try? JSONDecoder().decode(Array<DisconnectedUserHandle>.self, from: data) else
//                {
//                    return []
//                }
//                return loggedOutUserHandles
//            }
//            set {
//                guard let mainKey = keymaker.mainKey,
//                    let data = try? JSONEncoder().encode(newValue),
//                    let locked = try? Locked(clearValue: data, with: mainKey) else
//                {
//                    PMLog.D("Failed to save disconnectedUsers to keychain")
//                    return
//                }
//                KeychainWrapper.keychain.set(locked.encryptedValue, forKey: CoderKey.disconnectedUsers)
//            }
//        }
    }
    
}
