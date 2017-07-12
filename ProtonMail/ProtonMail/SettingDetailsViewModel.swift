//
//  GeneralSettingViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/19/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


public protocol SettingDetailsViewModel {
    
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


public class SettingDetailsViewModelTest : SettingDetailsViewModel{
    public func getNavigationTitle() -> String {
        return NSLocalizedString("Navigation Title - Test", comment: "Test")
    }
    
    public func getTopHelpText() -> String {
        return NSLocalizedString("this is description - Test", comment: "Test")
    }
    
    public func isRequireLoginPassword() -> Bool {
        return false
    }
    
    public func getSectionTitle() -> String {
        return NSLocalizedString("Section Title - Test", comment: "Test")
    }
    
    public func isDisplaySwitch() -> Bool {
        return true
    }
    
    public func getSwitchText() -> String {
        return NSLocalizedString("Enable - Test", comment: "Test")
    }
    
    public func getSwitchStatus() -> Bool {
        return true
    }
    
    public func isShowTextView() -> Bool {
        return true
    }
    
    public func getPlaceholdText() -> String {
        return NSLocalizedString("Please input ... - Test", comment: "Test")
    }
    
    public func getCurrentValue() -> String {
        return NSLocalizedString("test value", comment: "Test")
    }
    
    public func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping(Bool, NSError?) -> Void) {
        complete(true, nil)
    }
    
    public func updateNotification(_ isOn : Bool, complete:@escaping(Bool, NSError?) -> Void) {
        complete(true, nil)
    }
    
    public func isSwitchEnabled() -> Bool {
        return true
    }
    public func isTextEnabled() -> Bool{
        return true
    }
    
    public func getNotes() -> String {
        return ""
    }
    
    public func needAsk2FA() -> Bool {
        return false
    }
}



public class ChangeDisplayNameViewModel : SettingDetailsViewModel{
    public func getNavigationTitle() -> String {
        return NSLocalizedString("DisplayName", comment: "Title")
    }
    
    public func getTopHelpText() -> String {
        return NSLocalizedString("What people see in the \"From\" field.", comment: "Description")
    }
    
    public func getSectionTitle() -> String {
        return NSLocalizedString("DISPLAY NAME", comment: "Title")
    }
    
    public func isDisplaySwitch() -> Bool {
        return false
    }
    
    public func getSwitchText() -> String {
        return ""
    }
    
    public func getSwitchStatus() -> Bool {
        return true
    }

    public func isShowTextView() -> Bool {
        return false
    }
    
    public func isRequireLoginPassword() -> Bool {
        return false
    }
    
    public func getPlaceholdText() -> String {
        return NSLocalizedString("Input Display Name ...", comment: "place holder")
    }
    
    public func getCurrentValue() -> String {
        if let addr = sharedUserDataService.userAddresses.getDefaultAddress() {
            return addr.display_name
        }
        return sharedUserDataService.displayName
    }
    
    public func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void) {
        if let addr = sharedUserDataService.userAddresses.getDefaultAddress() {
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
    
    public func updateNotification(_ isOn : Bool, complete:@escaping(Bool, NSError?) -> Void) {
        complete(true, nil)
    }
    public func isSwitchEnabled() -> Bool {
        return true
    }
    public func isTextEnabled() -> Bool {
        return true
    }
    
    public func getNotes() -> String {
        return ""
    }
    
    public func needAsk2FA() -> Bool {
        return false
    }
}


public class ChangeSignatureViewModel : SettingDetailsViewModel{
    public func getNavigationTitle() -> String {
        return NSLocalizedString("Signature", comment: "Title")
    }
    
    public func getTopHelpText() -> String {
        return NSLocalizedString("Email default signature", comment: "place holder")
    }
    
    public func getSectionTitle() -> String {
        return NSLocalizedString("SIGNATURE", comment: "Title")
    }
    
    public func isDisplaySwitch() -> Bool {
        return true
    }
    
    public func getSwitchText() -> String {
        return NSLocalizedString("Enable Default Signature", comment: "Title")
    }
    
    public func getSwitchStatus() -> Bool {
        return sharedUserDataService.showDefaultSignature
    }

    public func isShowTextView() -> Bool {
        return true
    }
    
    public func isRequireLoginPassword() -> Bool {
        return false
    }
    
    public func getPlaceholdText() -> String {
        return ""
    }
    
    public func getCurrentValue() -> String {
        if let addr = sharedUserDataService.userAddresses.getDefaultAddress() {
            return addr.signature
        }
        return sharedUserDataService.signature
    }
    
    public func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void) {
        if let addr = sharedUserDataService.userAddresses.getDefaultAddress() {
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
    
    public func updateNotification(_ isOn : Bool, complete:@escaping(Bool, NSError?) -> Void) {
        sharedUserDataService.showDefaultSignature = isOn
        complete(true, nil)
    }
    
    public func isSwitchEnabled() -> Bool {
        return true
    }
    public func isTextEnabled() -> Bool {
        return true
    }
    
    public func getNotes() -> String {
        return ""
    }
    
    public func needAsk2FA() -> Bool {
        return false
    }
}

public class ChangeMobileSignatureViewModel : SettingDetailsViewModel{
    public func getNavigationTitle() -> String {
        return NSLocalizedString("Mobile Signature", comment: "Title")
    }
    
    func getTopHelpText() -> String {
        let _ = NSLocalizedString("Only a paid user can modify default mobile signature or turn it off!", comment: "Description")
        return NSLocalizedString("Only plus user could modify default mobile signature or turn it off!", comment: "Description")
    }
    
    public func getSectionTitle() -> String {
        return NSLocalizedString("Mobile Signature", comment: "Title")
    }
    
    public func isDisplaySwitch() -> Bool {
        return true
    }
    
    public func getSwitchText() -> String {
        return NSLocalizedString("Enable Mobile Signature", comment: "Title")
    }
    
    public func getSwitchStatus() -> Bool {
        return sharedUserDataService.showMobileSignature
    }
    
    public func isShowTextView() -> Bool {
        return true
    }
    
    public func isRequireLoginPassword() -> Bool {
        return false
    }
    
    public func getPlaceholdText() -> String {
        return ""
    }
    
    public func getCurrentValue() -> String {
        return sharedUserDataService.mobileSignature
    }
    
    public func updateValue(_ new_value: String, password: String, tfaCode: String?, complete:@escaping (Bool, NSError?) -> Void) {
        if new_value == getCurrentValue() {
            complete(true, nil)
        } else {
            sharedUserDataService.mobileSignature = new_value.ln2br()
            complete(true, nil)
        }
    }
    
    public func updateNotification(_ isOn : Bool, complete:@escaping(Bool, NSError?) -> Void) {
        if isOn == getSwitchStatus() {
            complete(true, nil)
        } else {
            sharedUserDataService.showMobileSignature = isOn
            complete(true, nil)
        }
    }
    public func isSwitchEnabled() -> Bool {
        return self.getRole()
    }
    public func isTextEnabled() -> Bool {
        return self.getRole()
    }
    
    public func getNotes() -> String {
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
    
    public func needAsk2FA() -> Bool {
        return false
    }
}


public class ChangeNotificationEmailViewModel : SettingDetailsViewModel{
    public func getNavigationTitle() -> String {
        return NSLocalizedString("Notification Email", comment: "Title")
    }
    
    public func getTopHelpText() -> String {
        return NSLocalizedString("Also used to reset a forgotten password.", comment: "Description")
    }
    
    public func getSectionTitle() -> String {
        return NSLocalizedString("Notification / Recovery Email", comment: "Title")
    }
    
    public func isRequireLoginPassword() -> Bool {
        return true
    }
    
    public func isDisplaySwitch() -> Bool {
        return true
    }
    
    public func getSwitchText() -> String {
        return NSLocalizedString("Enable Notification Email", comment: "Title")
    }
    
    public func getSwitchStatus() -> Bool {
        return sharedUserDataService.notify
    }
  
    public func isShowTextView() -> Bool {
        return false
    }
    
    public func getPlaceholdText() -> String {
        return NSLocalizedString("Input Notification Email ...", comment: "place holder")
    }

    public func getCurrentValue() -> String {
        return sharedUserDataService.notificationEmail
    }
    
    public func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void) {
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
    
    public func updateNotification(_ isOn : Bool, complete:@escaping (Bool, NSError?) -> Void) {
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
    
    public func isSwitchEnabled() -> Bool {
        return true
    }
    public func isTextEnabled() -> Bool {
        return true
    }
    
    public func getNotes() -> String {
        return ""
    }
    
    public func needAsk2FA() -> Bool {
        return sharedUserDataService.twoFactorStatus == 1
    }
}
