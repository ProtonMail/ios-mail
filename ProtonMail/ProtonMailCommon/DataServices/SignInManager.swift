//
//  SignInManager.swift
//  ProtonMail - Created on 18/10/2018.
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
import Keymaker

class SignInManager: Service {
    
    static var shared = SignInManager(usersManager: UsersManager(server: Server.live, delegate: nil))
    
    let usersManager: UsersManager
    init(usersManager: UsersManager) {
        self.usersManager = usersManager
    }
    
    //Clean up should put in to usermanager
    internal func clean() { //TODO:: fix later
        UserTempCachedStatus.backup()
        sharedUserDataService.signOut(true)
        userCachedStatus.signOut()
        //sharedMessageDataService.launchCleanUpIfNeeded()
    }
    
    internal func isSignedIn() -> Bool {
        return self.usersManager.isMailboxPasswordStored
        //return sharedUserDataService.isUserCredentialStored && sharedUserDataService.isMailboxPasswordStored
    }
    
    internal func signIn(username: String,
                         password: String,
                         cachedTwoCode: String?,
                         ask2fa: @escaping ()->Void,
                         onError: @escaping (NSError)->Void,
                         afterSignIn: @escaping ()->Void,
                         requestMailboxPassword: @escaping ()->Void,
                         tryUnlock:@escaping ()->Void )
    {
        let success: (String?, AuthCredential?, UserInfo?)->Void = { mailboxpwd, auth, userinfo in
            guard let auth = auth, let user = userinfo else {
                onError(NSError.init(domain: "", code: 0, localizedDescription: LocalString._the_mailbox_password_is_incorrect))
                return
            }
            self.usersManager.add(auth: auth, user: user)//TODO:: fix me
            guard let mailboxPassword = mailboxpwd else {//OK but need mailbox pwd
                UserTempCachedStatus.restore()
                afterSignIn()
                return
            }
            self.proceedWithMailboxPassword(mailboxPassword, auth: auth, onError: onError, tryUnlock: tryUnlock)
        }
        
        // one time api and service
        let service = APIService(config: usersManager.serverConfig, sessionUID: "", userID: "")
        let userService = UserDataService(check: false, api: service)
        userService.sign(in: username,
                         password: password,
                         twoFACode: cachedTwoCode,
                         ask2fa: ask2fa,
                         onError: onError,
                         onSuccess: success)
    }
    
    internal func mailboxPassword(from cleartextPassword: String) -> String {
        var mailboxPassword = cleartextPassword
        if let keysalt = AuthCredential.getKeySalt(), !keysalt.isEmpty {
            let keysalt_byte: Data = keysalt.decodeBase64()
            mailboxPassword = PasswordUtils.getMailboxPassword(cleartextPassword, salt: keysalt_byte)
        }
        return mailboxPassword
    }
    
    internal func proceedWithMailboxPassword(_ mailboxPassword: String, auth: AuthCredential?, onError: @escaping (NSError)->Void, tryUnlock:@escaping ()->Void ) {
        guard let auth = auth, let privateKey = auth.privateKey, privateKey.check(passphrase: mailboxPassword) else {
            onError(NSError.init(domain: "", code: 0, localizedDescription: LocalString._the_mailbox_password_is_incorrect))
            return
        }
        auth.udpate(password: mailboxPassword)
        
        let user = self.usersManager.getUser(bySessionID: auth.sessionID)!
        let labelService = user.labelService
        let userDataService = user.userService
        labelService.fetchLabels()
        userDataService.fetchUserInfo().done(on: .main) { info in
            guard let info = info else {
                onError(NSError.unknowError())
                return
            }
            guard info.delinquent < 3 else {
                onError(NSError.init(domain: "", code: 0, localizedDescription: LocalString._general_account_disabled_non_payment))
                return
            }
            
            self.usersManager.loggedIn()
            
            self.usersManager.update(auth: auth, user: info )
            //usersDataService.setMailboxPassword(mailboxPassword, keysalt: nil)
            UserTempCachedStatus.restore()
            NotificationCenter.default.post(name: .didSignIn, object: nil)
            
            tryUnlock()
        }.catch(on: .main) { (error) in
            onError(error as NSError)
            self.clean() // this will happen if fetchUserInfo fails - maybe because of connectivity issues
        }
    }

}
