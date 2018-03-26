//
//  ChangePasswordViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

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
    
    public func getNavigationTitle() -> String {
        return NSLocalizedString("PASSWORD", comment: "change login password navigation title")
    }
    
    public func getSectionTitle() -> String {
        return NSLocalizedString("Change Login Password", comment: "change password input label")
    }
    
    public func getLabelOne() -> String {
        return NSLocalizedString("Current login password", comment: "Title")
    }
    
    public func getLabelTwo() -> String {
        return NSLocalizedString("New login password", comment: "Title")
    }
    
    public func getLabelThree() -> String {
        return NSLocalizedString("Confirm new login password", comment: "Title")
    }
    
    public func needAsk2FA() -> Bool {
        return sharedUserDataService.twoFactorStatus == 1
    }
    
    public func setNewPassword(_ current: String, new_pwd: String, confirm_new_pwd: String, tfaCode : String?, complete: @escaping ChangePasswordComplete) {
        let curr_pwd = current //.trim();
        let newpwd = new_pwd //.trim();
        let confirmpwd = confirm_new_pwd //.trim();
        
        if curr_pwd != sharedUserDataService.password {
            complete(false, UpdatePasswordError.currentPasswordWrong.error)
        }
        else if newpwd == "" || confirmpwd == "" {
            complete(false, UpdatePasswordError.passwordEmpty.error)
        }
        else if newpwd != confirmpwd {
            complete(false, UpdatePasswordError.newNotMatch.error);
        }
        else if curr_pwd == newpwd {
            complete(true, nil)
        }
        else {
            sharedUserDataService.updatePassword(curr_pwd, new_password: newpwd, twoFACode: tfaCode) { _, _, error in
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
        return NSLocalizedString("PASSWORD", comment: "change mailbox password navigation title")
    }
    func getSectionTitle() -> String {
        return NSLocalizedString("Change Mailbox Password", comment: "Title")
    }
    
    func getLabelOne() -> String {
        return NSLocalizedString("Current login password", comment: "Title")
    }
    
    func getLabelTwo() -> String {
        return NSLocalizedString("New mailbox password", comment: "Title")
    }
    
    func getLabelThree() -> String {
        return NSLocalizedString("Confirm new mailbox password", comment: "Title")
    }
    
    func needAsk2FA() -> Bool {
        return sharedUserDataService.twoFactorStatus == 1
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
//        else if curr_pwd == newpwd {
//            complete(true, nil)
//        }
        else {
            sharedUserDataService.updateMailboxPassword(curr_pwd, new_password: newpwd, twoFACode: tfaCode, buildAuth: false) { _, _, error in
                if let error = error {
                    complete(false, error)
                } else {
                    complete(true, nil)
                }
            }
        }
    }
}


class ChangeSinglePasswordViewModel : ChangePWDViewModel{
    func getNavigationTitle() -> String {
        return NSLocalizedString("PASSWORD", comment: "change signle password navigation title")
    }
    func getSectionTitle() -> String {
        return NSLocalizedString("Change Single Password", comment: "Title")
    }
    
    func getLabelOne() -> String {
        return NSLocalizedString("Current password", comment: "Title")
    }
    
    func getLabelTwo() -> String {
        return NSLocalizedString("New password", comment: "Title")
    }
    
    func getLabelThree() -> String {
        return NSLocalizedString("Confirm new password", comment: "Title")
    }
    
    func needAsk2FA() -> Bool {
        return sharedUserDataService.twoFactorStatus == 1
    }
    
    func setNewPassword(_ current: String, new_pwd: String, confirm_new_pwd: String, tfaCode : String?, complete: @escaping ChangePasswordComplete) {
        //passwords support empty spaces like " * * "
        let curr_pwd = current
        let newpwd = new_pwd
        let confirmpwd = confirm_new_pwd
        
        
        if newpwd == "" || confirmpwd == "" {
            complete(false, UpdatePasswordError.passwordEmpty.error)
        }
        else if newpwd != confirmpwd {
            complete(false, UpdatePasswordError.newNotMatch.error)
        }
            //        else if curr_pwd == newpwd {
            //            complete(true, nil)
            //        }
        else {
            sharedUserDataService.updateMailboxPassword(curr_pwd, new_password: newpwd, twoFACode: tfaCode, buildAuth: true) { _, _, error in
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
    
    func needAsk2FA() -> Bool {
        return false
    }
    
    func setNewPassword(_ current: String, new_pwd: String, confirm_new_pwd: String, tfaCode : String?, complete:@escaping (Bool, NSError?) -> Void) {
        //add random test case and random
        //remove space.
        let curr_pwd = current//.trim();
        let newpwd = new_pwd//.trim();
        let confirmpwd = confirm_new_pwd//.trim();
        
        if curr_pwd != sharedUserDataService.mailboxPassword || !sharedUserDataService.isMailboxPasswordValid(curr_pwd, privateKey: sharedUserDataService.userInfo?.privateKey ?? "") {
            complete(false, UpdatePasswordError.currentPasswordWrong.error)
        }
        else if newpwd == "" || confirmpwd == "" {
            complete(false, UpdatePasswordError.passwordEmpty.error)
        }
        else if newpwd != confirmpwd {
            complete(false, UpdatePasswordError.newNotMatch.error)
        }
        else if curr_pwd == newpwd {
            complete(true, nil)
        }
        else {
            complete(true, nil)
        }
    }
}
