//
//  SettingDetailsViewModel.swift
//  ProtonMail - Created on 3/19/15.
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
    
    let userManager : UserManager
    init(user: UserManager) {
        self.userManager = user
    }
    
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
        if let addr = self.userManager.addresses.defaultAddress() {
            return addr.display_name
        }
        return self.userManager.displayName
    }
    
    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void) {
        let userService = self.userManager.userService
        if let addr = self.userManager.addresses.defaultAddress() {
            userService.updateAddress(auth: userManager.auth, user: userManager.userInfo,
                                      addressId: addr.address_id, displayName: new_value,
                                      signature: addr.signature, completion: { (_, _, error) in
                if let error = error {
                    complete(false, error)
                } else {
                    self.userManager.save()
                    complete(true, nil)
                }
            })
        } else {
            userService.updateDisplayName(auth: userManager.auth, user: userManager.userInfo,
                                          displayName: new_value) { _, _, error in
                if let error = error {
                    complete(false, error)
                } else {
                    self.userManager.save()
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
    let userManager : UserManager
    init(user: UserManager) {
        self.userManager = user
    }
    
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
        return userManager.defaultSignatureStatus
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
        if let addr = userManager.addresses.defaultAddress() {
            return addr.signature
        }
        return userManager.userDefaultSignature
    }
    
    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void) {
        let userService = userManager.userService
        if let addr = userManager.addresses.defaultAddress() {
            userService.updateAddress(auth: userManager.auth, user: userManager.userInfo,
                                      addressId: addr.address_id, displayName: addr.display_name,
                                      signature: new_value.ln2br(), completion: { (_, _, error) in
                if let error = error {
                    complete(false, error)
                } else {
                    self.userManager.save()
                    complete(true, nil)
                }
            })
        } else {
            userService.updateSignature(auth: userManager.auth, user: userManager.userInfo,
                                        new_value.ln2br()) { _, _, error in
                if let error = error {
                    complete(false, error)
                } else {
                    self.userManager.save()
                    complete(true, nil)
                }
            }
        }
    }
    
    func updateNotification(_ isOn : Bool, complete:@escaping(Bool, NSError?) -> Void) {
        userManager.defaultSignatureStatus = isOn
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
    let userManager : UserManager
    init(user: UserManager) {
        self.userManager = user
    }
    
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
        return self.userManager.showMobileSignature
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
        return self.userManager.mobileSignature
    }
    
    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete:@escaping (Bool, NSError?) -> Void) {
        if new_value == getCurrentValue() {
            complete(true, nil)
        } else {
            self.userManager.mobileSignature = new_value.ln2br()
            self.userManager.save()
            complete(true, nil)
        }
    }
    
    func updateNotification(_ isOn : Bool, complete:@escaping(Bool, NSError?) -> Void) {
        if isOn == getSwitchStatus() {
            complete(true, nil)
        } else {
            self.userManager.showMobileSignature = isOn
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
        let role = self.userManager.userInfo.role
        return role > 0 || isEnterprise
    }
    
    func needAsk2FA() -> Bool {
        return false
    }
}


class ChangeNotificationEmailViewModel : SettingDetailsViewModel {
    
    let userManager : UserManager
    init(user: UserManager) {
        self.userManager = user
    }
    
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
        return self.userManager.notify
    }
    
    func isShowTextView() -> Bool {
        return false
    }
    
    func getPlaceholdText() -> String {
        return LocalString._settings_notification_email_placeholder
    }

    func getCurrentValue() -> String {
        return self.userManager.notificationEmail
    }
    
    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void) {
        if new_value == getCurrentValue() {
            complete(true, nil)
        } else {
            let service = self.userManager.userService
            service.updateNotificationEmail(auth: userManager.auth,
                                            user: userManager.userInfo,
                                            new_notification_email: new_value,
                                            login_password: password,
                                            twoFACode: tfaCode) { _, _, error in
                if let error = error {
                    complete(false, error)
                } else {
                    self.userManager.save()
                    complete(true, nil)
                }
            }
        }
    }
    
    func updateNotification(_ isOn : Bool, complete:@escaping (Bool, NSError?) -> Void) {
        if isOn == getSwitchStatus() {
            complete(true, nil)
        } else {
            let service = self.userManager.userService
            service.updateNotify(auth: userManager.auth,
                                 user: userManager.userInfo,
                                 isOn, completion: { (task, response, error) -> Void in
                if let error = error {
                    complete(false, error)
                } else {
                    self.userManager.save()
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
        return self.userManager.userInfo.twoFactor > 0
    }
}
