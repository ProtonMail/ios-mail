//
//  ChangePasswordViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

protocol ChangePWDViewModel {
    
    func getNavigationTitle() -> String;
    func getSectionTitle() -> String;
    func getLabelOne() -> String;
    func getLabelTwo() -> String;
    func getLabelThree() -> String;
    func setNewPassword(current: String, new_pwd: String, confirm_new_pwd: String, complete:(Bool, NSError?) -> Void)
}

class ChangeLoginPWDViewModel : ChangePWDViewModel{
    
    func getNavigationTitle() -> String {
        return "PASSWORD"
    }
    
    func getSectionTitle() -> String {
        return "Change Login Password"
    }
    
    func getLabelOne() -> String {
        return "Current login password"
    }
    
    func getLabelTwo() -> String {
        return "New login password"
    }
    
    func getLabelThree() -> String {
        return "Confirm new login password"
    }
    
    func setNewPassword(current: String, new_pwd: String, confirm_new_pwd: String, complete: (Bool, NSError?) -> Void) {
        let curr_pwd = current.trim();
        let newpwd = new_pwd.trim();
        let confirmpwd = confirm_new_pwd.trim();
        
        if curr_pwd != sharedUserDataService.password {
            complete(false, NSError.currentPwdWrong())
        }
        else if newpwd == "" || confirmpwd == "" {
            complete(false, NSError.pwdCantEmpty())
        }
        else if newpwd != confirmpwd {
            complete(false, NSError.newNotMatch())
        }
        else if curr_pwd == newpwd {
            complete(true, nil)
        }
        else {
            sharedUserDataService.updatePassword(curr_pwd, newPassword: newpwd) { _, _, error in
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
    func getNavigationTitle() -> String {
        return "PASSWORD"
    }
    func getSectionTitle() -> String {
        return "Change Mailbox Password"
    }
    
    func getLabelOne() -> String {
        return "Current mailbox password"
    }
    
    func getLabelTwo() -> String {
        return "New mailbox password"
    }
    
    func getLabelThree() -> String {
        return "Confirm new mailbox password"
    }
    
    func setNewPassword(current: String, new_pwd: String, confirm_new_pwd: String, complete: (Bool, NSError?) -> Void) {
        //remove space.
        let curr_pwd = current.trim();
        let newpwd = new_pwd.trim();
        let confirmpwd = confirm_new_pwd.trim();
        
        if curr_pwd != sharedUserDataService.mailboxPassword || !sharedOpenPGP.checkPassphrase(curr_pwd, forPrivateKey: sharedUserDataService.userInfo?.privateKey ?? "") {
            complete(false, NSError.currentPwdWrong())
        }
        else if newpwd == "" || confirmpwd == "" {
            complete(false, NSError.pwdCantEmpty())
        }
        else if newpwd != confirmpwd {
            complete(false, NSError.newNotMatch())
        }
        else if curr_pwd == newpwd {
            complete(true, nil)
        }
        else {
            sharedUserDataService.updateMailboxPassword(curr_pwd, newMailboxPassword: newpwd) { _, _, error in
                if let error = error {
                    complete(false, error)
                } else {
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
    
    func setNewPassword(current: String, new_pwd: String, confirm_new_pwd: String, complete: (Bool, NSError?) -> Void) {
        //add random test case and random
        //remove space.
        let curr_pwd = current.trim();
        let newpwd = new_pwd.trim();
        let confirmpwd = confirm_new_pwd.trim();
        
        if curr_pwd != sharedUserDataService.mailboxPassword || !sharedUserDataService.isMailboxPasswordValid(curr_pwd, privateKey: sharedUserDataService.userInfo?.privateKey ?? "") {
            complete(false, NSError.currentPwdWrong())
        }
        else if newpwd == "" || confirmpwd == "" {
            complete(false, NSError.pwdCantEmpty())
        }
        else if newpwd != confirmpwd {
            complete(false, NSError.newNotMatch())
        }
        else if curr_pwd == newpwd {
            complete(true, nil)
        }
        else {
            complete(true, nil)
        }
    }
}