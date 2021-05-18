//
//  ChangePasswordViewModel.swift
//  ProtonMail - Created on 3/18/15.
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

public typealias ChangePasswordComplete = (Bool, NSError?) -> Void

public protocol ChangePWDViewModel {
    
    func getNavigationTitle() -> String
    func getSectionTitle() -> String
    func getLabelOne() -> String
    func getLabelTwo() -> String
    func getLabelThree() -> String
    func needAsk2FA() -> Bool
    func setNewPassword(_ current: String, new_pwd: String, confirm_new_pwd: String, tfaCode : String?, complete:@escaping ChangePasswordComplete)
}

public class ChangeLoginPWDViewModel : ChangePWDViewModel{
    
    let userManager: UserManager
    init(user: UserManager) {
        self.userManager = user
    }
    
    public func getNavigationTitle() -> String {
        return LocalString._password
    }
    
    public func getSectionTitle() -> String {
        return LocalString._change_login_password
    }
    
    public func getLabelOne() -> String {
        return LocalString._current_login_password
    }
    
    public func getLabelTwo() -> String {
        return LocalString._new_login_password
    }
    
    public func getLabelThree() -> String {
        return LocalString._confirm_new_login_password
    }
    
    public func needAsk2FA() -> Bool {
        return self.userManager.userInfo.twoFactor > 0
    }
    
    public func setNewPassword(_ current: String, new_pwd: String, confirm_new_pwd: String, tfaCode : String?, complete: @escaping ChangePasswordComplete) {
        let curr_pwd = current //.trim();
        let newpwd = new_pwd //.trim();
        let confirmpwd = confirm_new_pwd //.trim();
        
        if newpwd == "" || confirmpwd == "" {
            complete(false, UpdatePasswordError.passwordEmpty.error)
        } else if newpwd.count < 8 {
            complete(false, UpdatePasswordError.minimumLengthError.error)
        }
        else if newpwd != confirmpwd {
            complete(false, UpdatePasswordError.newNotMatch.error);
        }
        else {
            self.userManager.userService.updatePassword(auth: userManager.auth,
                                                        user: userManager.userInfo,
                                                        login_password: curr_pwd,
                                                        new_password: newpwd,
                                                        twoFACode: tfaCode) { (_, _, error) in
                if let error = error {
                    complete(false, error)
                } else {
                    complete(true, nil)
                }
            }
        }
    }
}

class ChangeMailboxPWDViewModel : ChangePWDViewModel{
    let userManager: UserManager
    init(user: UserManager) {
        self.userManager = user
    }
    
    func getNavigationTitle() -> String {
        return LocalString._password
    }
    func getSectionTitle() -> String {
        return LocalString._change_mailbox_password
    }
    
    func getLabelOne() -> String {
        return LocalString._current_login_password
    }
    
    func getLabelTwo() -> String {
        return LocalString._new_mailbox_password
    }
    
    func getLabelThree() -> String {
        return LocalString._confirm_new_mailbox_password
    }
    
    func needAsk2FA() -> Bool {
        return self.userManager.userInfo.twoFactor > 0
    }
    
    func setNewPassword(_ current: String, new_pwd: String, confirm_new_pwd: String, tfaCode : String?, complete: @escaping ChangePasswordComplete) {
        //passwords support empty spaces like " 1 1 "
        let curr_pwd = current
        let newpwd = new_pwd
        let confirmpwd = confirm_new_pwd
        

        if newpwd == "" || confirmpwd == "" {
            complete(false, UpdatePasswordError.passwordEmpty.error)
        }
        else if newpwd != confirmpwd {
            complete(false, UpdatePasswordError.newNotMatch.error)
        }
        else {
            self.userManager.userService.updateMailboxPassword(auth: userManager.auth,
                                                               user: userManager.userInfo,
                                                               loginPassword: curr_pwd,
                                                               newPassword: newpwd,
                                                               twoFACode: tfaCode,
                                                               buildAuth: false) { (_, _, error) in
                if let error = error {
                    complete(false, error)
                } else {
                    complete(true, nil)
                }
            }
        }
    }
}


class ChangeSinglePasswordViewModel : ChangePWDViewModel {
    
    let userManager : UserManager
    init(user: UserManager) {
        self.userManager = user
    }

    func getNavigationTitle() -> String {
        return LocalString._password
    }
    func getSectionTitle() -> String {
        return LocalString._change_single_password
    }
    
    func getLabelOne() -> String {
        return LocalString._settings_current_password
    }
    
    func getLabelTwo() -> String {
        return LocalString._settings_new_password
    }
    
    func getLabelThree() -> String {
        return LocalString._settings_confirm_new_password
    }
    
    func needAsk2FA() -> Bool {
        return userManager.userInfo.twoFactor > 0
    }
    
    func setNewPassword(_ current: String, new_pwd: String, confirm_new_pwd: String, tfaCode : String?, complete: @escaping ChangePasswordComplete) {
        //passwords support empty spaces like " * * "
        let curr_pwd = current
        let newpwd = new_pwd
        let confirmpwd = confirm_new_pwd
        if newpwd == "" || confirmpwd == "" {
            complete(false, UpdatePasswordError.passwordEmpty.error)
        } else if newpwd.count < 8 {
            complete(false, UpdatePasswordError.minimumLengthError.error)
        }
        else if newpwd != confirmpwd {
            complete(false, UpdatePasswordError.newNotMatch.error)
        } else {
            let service = self.userManager.userService
            service.updateMailboxPassword(auth: userManager.auth, user: userManager.userInfo, loginPassword: curr_pwd, newPassword: newpwd, twoFACode: tfaCode, buildAuth: true) { (_, _, error) in
                if let error = error {
                    complete(false, error)
                } else {
                    self.userManager.save()
                    complete(true, nil)
                }
            }
        }
    }
}

class ChangePWDViewModelTest : ChangePWDViewModel{
    func getNavigationTitle() -> String {
        return "PASSWORD - Test"
    }
    func getSectionTitle() -> String {
        return "Change Mailbox Password - Test"
    }
    
    func getLabelOne() -> String {
        return "Current mailbox password - Test"
    }
    
    func getLabelTwo() -> String {
        return "New mailbox password - Test"
    }
    
    func getLabelThree() -> String {
        return "Confirm new mailbox password - Test"
    }
    
    func needAsk2FA() -> Bool {
        return false
    }
    
    func setNewPassword(_ current: String, new_pwd: String, confirm_new_pwd: String, tfaCode : String?, complete:@escaping (Bool, NSError?) -> Void) {
        //add random test case and random
        //remove space.
//        let curr_pwd = current//.trim();
//        let newpwd = new_pwd//.trim();
//        let confirmpwd = confirm_new_pwd//.trim();
        
//        if curr_pwd != sharedUserDataService.mailboxPassword {
//            complete(false, UpdatePasswordError.currentPasswordWrong.error)
//        }
//        else if newpwd == "" || confirmpwd == "" {
//            complete(false, UpdatePasswordError.passwordEmpty.error)
//        }
//        else if newpwd != confirmpwd {
//            complete(false, UpdatePasswordError.newNotMatch.error)
//        }
//        else if curr_pwd == newpwd {
//            complete(true, nil)
//        }
//        else {
//            complete(true, nil)
//        }
    }
}
