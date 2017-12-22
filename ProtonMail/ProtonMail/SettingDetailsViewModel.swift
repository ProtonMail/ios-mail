//
//  GeneralSettingViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/19/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

protocol SettingDetailsViewModel {
    
    func getNavigationTitle() -> String
    func getTopHelpText() ->String
    func getSectionTitle() -> String
    func isDisplaySwitch() -> Bool
    func getSwitchText() -> String
    func getSwitchStatus() -> Bool
    func isShowTextView() -> Bool
    func isRequireLoginPassword() -> Bool
    func getPlaceholdText() -> String
    
    func getCurrentValue() -> String
    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete:@escaping (Bool, NSError?) -> Void)
    func updateNotification(_ isOn : Bool, complete:@escaping(Bool, NSError?) -> Void)
    
    func isSwitchEnabled() -> Bool
    func isTextEnabled() -> Bool
    
    func getNotes() -> String
    
    func needAsk2FA() -> Bool
}


class SettingDetailsViewModelTest : SettingDetailsViewModel{
    func getNavigationTitle() -> String {
        return NSLocalizedString("Navigation Title - Test", comment: "Test")
    }
    
    func getTopHelpText() -> String {
        return NSLocalizedString("this is description - Test", comment: "Test")
    }
    
    func isRequireLoginPassword() -> Bool {
        return false
    }
    
    func getSectionTitle() -> String {
        return NSLocalizedString("Section Title - Test", comment: "Test")
    }
    
    func isDisplaySwitch() -> Bool {
        return true
    }
    
    func getSwitchText() -> String {
        return NSLocalizedString("Enable - Test", comment: "Test")
    }
    
    func getSwitchStatus() -> Bool {
        return true
    }
    
    func isShowTextView() -> Bool {
        return true
    }
    
    func getPlaceholdText() -> String {
        return NSLocalizedString("Please input ... - Test", comment: "Test")
    }
    
    func getCurrentValue() -> String {
        return NSLocalizedString("test value", comment: "Test")
    }
    
    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping(Bool, NSError?) -> Void) {
        complete(true, nil)
    }
    
    func updateNotification(_ isOn : Bool, complete:@escaping(Bool, NSError?) -> Void) {
        complete(true, nil)
    }
    
    func isSwitchEnabled() -> Bool {
        return true
    }
    func isTextEnabled() -> Bool{
        return true
    }
    
    func getNotes() -> String {
        return ""
    }
    
    func needAsk2FA() -> Bool {
        return false
    }
}



class ChangeDisplayNameViewModel : SettingDetailsViewModel{
    func getNavigationTitle() -> String {
        return NSLocalizedString("DisplayName", comment: "Title")
    }
    
    func getTopHelpText() -> String {
        return NSLocalizedString("What people see in the \"From\" field.", comment: "Description")
    }
    
    func getSectionTitle() -> String {
        return NSLocalizedString("DISPLAY NAME", comment: "Title")
    }
    
    func isDisplaySwitch() -> Bool {
        return false
    }
    
    func getSwitchText() -> String {
        return ""
    }
    
    func getSwitchStatus() -> Bool {
        return true
    }

    func isShowTextView() -> Bool {
        return false
    }
    
    func isRequireLoginPassword() -> Bool {
        return false
    }
    
    func getPlaceholdText() -> String {
        return NSLocalizedString("Input Display Name ...", comment: "place holder")
    }
    
    func getCurrentValue() -> String {
        if let addr = sharedUserDataService.userAddresses.defaultAddress() {
            return addr.display_name
        }
        return sharedUserDataService.displayName
    }
    
    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void) {
        if let addr = sharedUserDataService.userAddresses.defaultAddress() {
            sharedUserDataService.updateAddress(addr.address_id, displayName: new_value, signature: addr.signature, completion: { (_, _, error) in
                if let error = error {
                    complete(false, error)
                } else {
                    complete(true, nil)
                }
            })
        } else {
            sharedUserDataService.updateDisplayName(new_value) { _, _, error in
                if let error = error {
                    complete(false, error)
                } else {
                    complete(true, nil)
                }
            }
        }
    }
    
    func updateNotification(_ isOn : Bool, complete:@escaping(Bool, NSError?) -> Void) {
        complete(true, nil)
    }
    func isSwitchEnabled() -> Bool {
        return true
    }
    func isTextEnabled() -> Bool {
        return true
    }
    
    func getNotes() -> String {
        return ""
    }
    
    func needAsk2FA() -> Bool {
        return false
    }
}


class ChangeSignatureViewModel : SettingDetailsViewModel{
    func getNavigationTitle() -> String {
        return NSLocalizedString("Signature", comment: "Title")
    }
    
    func getTopHelpText() -> String {
        return NSLocalizedString("Email default signature", comment: "place holder")
    }
    
    func getSectionTitle() -> String {
        return NSLocalizedString("SIGNATURE", comment: "Title")
    }
    
    func isDisplaySwitch() -> Bool {
        return true
    }
    
    func getSwitchText() -> String {
        return NSLocalizedString("Enable Default Signature", comment: "Title")
    }
    
    func getSwitchStatus() -> Bool {
        return sharedUserDataService.showDefaultSignature
    }

    func isShowTextView() -> Bool {
        return true
    }
    
    func isRequireLoginPassword() -> Bool {
        return false
    }
    
    func getPlaceholdText() -> String {
        return ""
    }
    
    func getCurrentValue() -> String {
        if let addr = sharedUserDataService.userAddresses.defaultAddress() {
            return addr.signature
        }
        return sharedUserDataService.signature
    }
    
    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void) {
        if let addr = sharedUserDataService.userAddresses.defaultAddress() {
            sharedUserDataService.updateAddress(addr.address_id, displayName: addr.display_name, signature: new_value.ln2br(), completion: { (_, _, error) in
                if let error = error {
                    complete(false, error)
                } else {
                    complete(true, nil)
                }
            })
        } else {
            sharedUserDataService.updateSignature(new_value.ln2br()) { _, _, error in
                if let error = error {
                    complete(false, error)
                } else {
                    complete(true, nil)
                }
            }
        }
    }
    
    func updateNotification(_ isOn : Bool, complete:@escaping(Bool, NSError?) -> Void) {
        sharedUserDataService.showDefaultSignature = isOn
        complete(true, nil)
    }
    
    func isSwitchEnabled() -> Bool {
        return true
    }
    func isTextEnabled() -> Bool {
        return true
    }
    
    func getNotes() -> String {
        return ""
    }
    
    func needAsk2FA() -> Bool {
        return false
    }
}

class ChangeMobileSignatureViewModel : SettingDetailsViewModel{
    func getNavigationTitle() -> String {
        return NSLocalizedString("Mobile Signature", comment: "Title")
    }
    
    func getTopHelpText() -> String {
        let _ = NSLocalizedString("Only a paid user can modify default mobile signature or turn it off!", comment: "Description")
        return NSLocalizedString("Only plus user could modify default mobile signature or turn it off!", comment: "Description")
    }
    
    func getSectionTitle() -> String {
        return NSLocalizedString("Mobile Signature", comment: "Title")
    }
    
    func isDisplaySwitch() -> Bool {
        return true
    }
    
    func getSwitchText() -> String {
        return NSLocalizedString("Enable Mobile Signature", comment: "Title")
    }
    
    func getSwitchStatus() -> Bool {
        return sharedUserDataService.showMobileSignature
    }
    
    func isShowTextView() -> Bool {
        return true
    }
    
    func isRequireLoginPassword() -> Bool {
        return false
    }
    
    func getPlaceholdText() -> String {
        return ""
    }
    
    func getCurrentValue() -> String {
        return sharedUserDataService.mobileSignature
    }
    
    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete:@escaping (Bool, NSError?) -> Void) {
        if new_value == getCurrentValue() {
            complete(true, nil)
        } else {
            sharedUserDataService.mobileSignature = new_value.ln2br()
            complete(true, nil)
        }
    }
    
    func updateNotification(_ isOn : Bool, complete:@escaping(Bool, NSError?) -> Void) {
        if isOn == getSwitchStatus() {
            complete(true, nil)
        } else {
            sharedUserDataService.showMobileSignature = isOn
            complete(true, nil)
        }
    }
    func isSwitchEnabled() -> Bool {
        return self.getRole()
    }
    func isTextEnabled() -> Bool {
        return self.getRole()
    }
    
    func getNotes() -> String {
        return self.getRole() ? "" : NSLocalizedString("ProtonMail Plus is required to customize your mobile signature", comment: "Description")
    }
    
    internal func getRole() -> Bool {
        #if Enterprise
            let isEnterprise = true
        #else
            let isEnterprise = false
        #endif
        
        return sharedUserDataService.userInfo?.role > 0 || isEnterprise
    }
    
    func needAsk2FA() -> Bool {
        return false
    }
}


class ChangeNotificationEmailViewModel : SettingDetailsViewModel{
    func getNavigationTitle() -> String {
        return NSLocalizedString("Notification Email", comment: "Title")
    }
    
    func getTopHelpText() -> String {
        return NSLocalizedString("Also used to reset a forgotten password.", comment: "Description")
    }
    
    func getSectionTitle() -> String {
        return NSLocalizedString("Notification / Recovery Email", comment: "Title")
    }
    
    func isRequireLoginPassword() -> Bool {
        return true
    }
    
    func isDisplaySwitch() -> Bool {
        return true
    }
    
    func getSwitchText() -> String {
        return NSLocalizedString("Enable Notification Email", comment: "Title")
    }
    
    func getSwitchStatus() -> Bool {
        return sharedUserDataService.notify
    }
  
    func isShowTextView() -> Bool {
        return false
    }
    
    func getPlaceholdText() -> String {
        return NSLocalizedString("Input Notification Email ...", comment: "place holder")
    }

    func getCurrentValue() -> String {
        return sharedUserDataService.notificationEmail
    }
    
    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void) {
        if new_value == getCurrentValue() {
             complete(true, nil)
        } else {
            sharedUserDataService.updateNotificationEmail(new_value, login_password: password, twoFACode: tfaCode) { _, _, error in
                if let error = error {
                    complete(false, error)
                } else {
                    complete(true, nil)
                }
            }
        }
    }
    
    func updateNotification(_ isOn : Bool, complete:@escaping (Bool, NSError?) -> Void) {
        if isOn == getSwitchStatus() {
            complete(true, nil)
        } else {
            sharedUserDataService.updateNotify(isOn, completion: { (task, response, error) -> Void in
                if let error = error {
                    complete(false, error)
                } else {
                    complete(true, nil)
                }
            })
        }
    }
    
    func isSwitchEnabled() -> Bool {
        return true
    }
    func isTextEnabled() -> Bool {
        return true
    }
    
    func getNotes() -> String {
        return ""
    }
    
    func needAsk2FA() -> Bool {
        return sharedUserDataService.twoFactorStatus == 1
    }
}
