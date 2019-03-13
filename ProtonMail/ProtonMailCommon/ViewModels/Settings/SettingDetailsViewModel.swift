//
//  SettingDetailsViewModel.swift
//  ProtonMail - Created on 3/19/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation

protocol SettingDetailsViewModel {
    
    var sectionTitle2 : String {get}
    
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
    var sectionTitle2: String {
        return ""
    }
    
    func getNavigationTitle() -> String {
        return "Navigation localized Title - Test"
    }
    
    func getTopHelpText() -> String {
        return "this is localized description - Test"
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
    var sectionTitle2: String {
        return ""
    }
    
    func getNavigationTitle() -> String {
        return LocalString._settings_displayname_title
    }
    
    func getTopHelpText() -> String {
        return NSLocalizedString("What people see in the \"From\" field.", comment: "Description")
    }
    
    func getSectionTitle() -> String {
        return LocalString._settings_display_name_title
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
        return LocalString._settings_input_display_name_placeholder
    }
    
    func getCurrentValue() -> String {
        if let addr = sharedUserDataService.addresses.defaultAddress() {
            return addr.display_name
        }
        return sharedUserDataService.displayName
    }
    
    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void) {
        if let addr = sharedUserDataService.addresses.defaultAddress() {
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
    var sectionTitle2: String {
        return LocalString._edit_signature
    }
    
    func getNavigationTitle() -> String {
        return LocalString._settings_signature_title
    }
    
    func getTopHelpText() -> String {
        return LocalString._settings_email_default_signature
    }
    
    func getSectionTitle() -> String {
        return LocalString._settings_signature_title
    }
    
    func isDisplaySwitch() -> Bool {
        return true
    }
    
    func getSwitchText() -> String {
        return LocalString._settings_enable_default_signature_title
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
        if let addr = sharedUserDataService.addresses.defaultAddress() {
            return addr.signature
        }
        return sharedUserDataService.userDefaultSignature
    }
    
    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void) {
        if let addr = sharedUserDataService.addresses.defaultAddress() {
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

class ChangeMobileSignatureViewModel : SettingDetailsViewModel {
    var sectionTitle2: String {
        return LocalString._edit_mobile_signature
    }
    
    func getNavigationTitle() -> String {
        return LocalString._settings_mobile_signature_title
    }
    
    func getTopHelpText() -> String {
        return LocalString._settings_only_paid_to_modify_mobile_signature
    }
    
    func getSectionTitle() -> String {
        return LocalString._settings_mobile_signature_title
    }
    
    func isDisplaySwitch() -> Bool {
        return true
    }
    
    func getSwitchText() -> String {
        return LocalString._settings_enable_mobile_signature_title
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
        return self.getRole() ? "" : LocalString._settings_plus_is_required_to_modify_signature_notes
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


class ChangeNotificationEmailViewModel : SettingDetailsViewModel {
    
    var sectionTitle2: String {
        return ""
    }
    func getNavigationTitle() -> String {
        return LocalString._settings_notification_email
    }
    
    func getTopHelpText() -> String {
        return LocalString._settings_notification_email_notes
    }
    
    func getSectionTitle() -> String {
        return LocalString._settings_notification_email_title
    }
    
    func isRequireLoginPassword() -> Bool {
        return true
    }
    
    func isDisplaySwitch() -> Bool {
        return true
    }
    
    func getSwitchText() -> String {
        return LocalString._settings_notification_email_switch_title
    }
    
    func getSwitchStatus() -> Bool {
        return sharedUserDataService.notify
    }
  
    func isShowTextView() -> Bool {
        return false
    }
    
    func getPlaceholdText() -> String {
        return LocalString._settings_notification_email_placeholder
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
