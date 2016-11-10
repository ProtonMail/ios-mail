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
    func updateValue(new_value: String, password: String, tfaCode: String?, complete:(Bool, NSError?) -> Void)
    func updateNotification(isOn : Bool, complete:(Bool, NSError?) -> Void)
    
    func isSwitchEnabled() -> Bool
    func isTextEnabled() -> Bool
    
    func getNotes() -> String
    
    func needAsk2FA() -> Bool
}


class SettingDetailsViewModelTest : SettingDetailsViewModel{
    func getNavigationTitle() -> String {
        return "Navigation Title - Test"
    }
    
    func getTopHelpText() -> String {
        return "this is description - Test"
    }
    
    func isRequireLoginPassword() -> Bool {
        return false
    }
    
    func getSectionTitle() -> String {
        return "Section Title - Test"
    }
    
    func isDisplaySwitch() -> Bool {
        return true
    }
    
    func getSwitchText() -> String {
        return "Enable - Test"
    }
    
    func getSwitchStatus() -> Bool {
        return true
    }
    
    func isShowTextView() -> Bool {
        return true
    }
    
    func getPlaceholdText() -> String {
        return "Please input ... - Test"
    }
    
    func getCurrentValue() -> String {
        return "test value"
    }
    
    func updateValue(new_value: String, password: String, tfaCode: String?, complete: (Bool, NSError?) -> Void) {
        complete(true, nil)
    }
    
    func updateNotification(isOn : Bool, complete:(Bool, NSError?) -> Void) {
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
        return "DisplayName"
    }
    
    func getTopHelpText() -> String {
        return "What people see in the \"From\" field."
    }
    
    func getSectionTitle() -> String {
        return "DISPLAY NAME"
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
        return "Input Display Name ..."
    }
    
    func getCurrentValue() -> String {
        if let addr = sharedUserDataService.userAddresses.getDefaultAddress() {
            return addr.display_name
        }
        return sharedUserDataService.displayName
    }
    
    func updateValue(new_value: String, password: String, tfaCode: String?, complete: (Bool, NSError?) -> Void) {
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
    
    func updateNotification(isOn : Bool, complete:(Bool, NSError?) -> Void) {
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
        return "Signature"
    }
    
    func getTopHelpText() -> String {
        return "Email default signature"
    }
    
    func getSectionTitle() -> String {
        return "SIGNATURE"
    }
    
    func isDisplaySwitch() -> Bool {
        return true
    }
    
    func getSwitchText() -> String {
        return "Enable Default Signature"
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
        if let addr = sharedUserDataService.userAddresses.getDefaultAddress() {
            return addr.signature
        }
        return sharedUserDataService.signature
    }
    
    func updateValue(new_value: String, password: String, tfaCode: String?, complete: (Bool, NSError?) -> Void) {
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
    
    func updateNotification(isOn : Bool, complete:(Bool, NSError?) -> Void) {
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
        return "Mobile Signature"
    }
    
    func getTopHelpText() -> String {
        return "Only plus user could modify default mobile signature or turn it off!"
    }
    
    func getSectionTitle() -> String {
        return "Mobile Signature"
    }
    
    func isDisplaySwitch() -> Bool {
        return true
    }
    
    func getSwitchText() -> String {
        return "Enable Mobile Signature"
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
    
    func updateValue(new_value: String, password: String, tfaCode: String?, complete: (Bool, NSError?) -> Void) {
        if new_value == getCurrentValue() {
            complete(true, nil)
        } else {
            sharedUserDataService.mobileSignature = new_value.ln2br()
            complete(true, nil)
        }
    }
    
    func updateNotification(isOn : Bool, complete:(Bool, NSError?) -> Void) {
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
        return self.getRole() ? "" : "ProtonMail Plus is required to customize your mobile signature"
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
        return "Notification Email"
    }
    
    func getTopHelpText() -> String {
        return "Also used to reset a forgotten password."
    }
    
    func getSectionTitle() -> String {
        return "Notification / Recovery Email"
    }
    
    func isRequireLoginPassword() -> Bool {
        return true
    }
    
    func isDisplaySwitch() -> Bool {
        return true
    }
    
    func getSwitchText() -> String {
        return "Enable Notification Email"
    }
    
    func getSwitchStatus() -> Bool {
        return sharedUserDataService.notify
    }
  
    func isShowTextView() -> Bool {
        return false
    }
    
    func getPlaceholdText() -> String {
        return "Input Notification Email ..."
    }

    func getCurrentValue() -> String {
        return sharedUserDataService.notificationEmail
    }
    
    func updateValue(new_value: String, password: String, tfaCode: String?, complete: (Bool, NSError?) -> Void) {
        if new_value == getCurrentValue() {
             complete(true, nil)
        } else {
            sharedUserDataService.updateNotificationEmail(new_value, password: password, tfaCode: tfaCode) { _, _, error in
                if let error = error {
                    complete(false, error)
                } else {
                    complete(true, nil)
                }
            }
        }
    }
    
    func updateNotification(isOn : Bool, complete:(Bool, NSError?) -> Void) {
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
