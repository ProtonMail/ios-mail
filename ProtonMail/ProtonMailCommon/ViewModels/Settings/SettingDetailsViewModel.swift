//
//  SettingDetailsViewModel.swift
//  Proton Mail - Created on 3/19/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

protocol SettingDetailsViewModel {
    var userManager: UserManager { get }
    var sectionTitle2: String { get }
    init(user: UserManager)
    func getNavigationTitle() -> String
    func isDisplaySwitch() -> Bool
    func getSwitchText() -> String
    func getSwitchStatus() -> Bool
    func isShowTextView() -> Bool
    func isRequireLoginPassword() -> Bool
    func getPlaceholdText() -> String
    func getCurrentValue() -> String
    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void)
    func updateNotification(_ isOn: Bool, complete: @escaping (Bool, NSError?) -> Void)
    func isSwitchEnabled() -> Bool
    func getNotes() -> String
    func needAsk2FA() -> Bool
}

class ChangeDisplayNameViewModel: SettingDetailsViewModel {
    let userManager: UserManager

    required init(user: UserManager) {
        self.userManager = user
    }

    var sectionTitle2: String {
        return ""
    }

    func getNavigationTitle() -> String {
        return LocalString._settings_displayname_title
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
        if let addr = userManager.addresses.defaultAddress() {
            return addr.displayName
        }
        return userManager.displayName
    }

    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void) {
        let userService = userManager.userService
        if let addr = userManager.addresses.defaultAddress() {
            userService.updateAddress(auth: userManager.auth, user: userManager.userInfo,
                                      addressId: addr.addressID, displayName: new_value,
                                      signature: addr.signature, completion: { _, _, error in
                                          if let error = error {
                                              complete(false, error)
                                          } else {
                                              self.userManager.save()
                                              complete(true, nil)
                                          }
                                      })
        } else {
            fatalError("Current user has no defualt address. Should not go here")
        }
    }

    func updateNotification(_ isOn: Bool, complete: @escaping (Bool, NSError?) -> Void) {
        complete(true, nil)
    }

    func isSwitchEnabled() -> Bool {
        return true
    }

    func getNotes() -> String {
        return ""
    }

    func needAsk2FA() -> Bool {
        return false
    }
}

class ChangeSignatureViewModel: SettingDetailsViewModel {
    let userManager: UserManager

    required init(user: UserManager) {
        self.userManager = user
    }

    var sectionTitle2: String {
        return ""
    }

    func getNavigationTitle() -> String {
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
        return LocalString._settings_default_signature_placeholder
    }

    func getCurrentValue() -> String {
        if let addr = userManager.addresses.defaultAddress() {
            return addr.signature
        }
        return userManager.userDefaultSignature
    }

    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void) {
        let userService = userManager.userService
        let valueToSave = new_value.trim().ln2br()
        if let addr = userManager.addresses.defaultAddress() {
            userService.updateAddress(auth: userManager.auth, user: userManager.userInfo,
                                      addressId: addr.addressID, displayName: addr.displayName,
                                      signature: valueToSave, completion: { _, _, error in
                                          if let error = error {
                                              complete(false, error)
                                          } else {
                                              self.userManager.save()
                                              complete(true, nil)
                                          }
                                      })
        } else {
            userService.updateSignature(auth: userManager.auth,
                                        user: userManager.userInfo,
                                        valueToSave) { _, _, error in
                if let error = error {
                    complete(false, error)
                } else {
                    self.userManager.save()
                    complete(true, nil)
                }
            }
        }
    }

    func updateNotification(_ isOn: Bool, complete: @escaping (Bool, NSError?) -> Void) {
        userManager.defaultSignatureStatus = isOn
        complete(true, nil)
    }

    func isSwitchEnabled() -> Bool {
        return true
    }

    func getNotes() -> String {
        return ""
    }

    func needAsk2FA() -> Bool {
        return false
    }
}

class ChangeMobileSignatureViewModel: SettingDetailsViewModel {
    let userManager: UserManager

    required init(user: UserManager) {
        self.userManager = user
    }

    var sectionTitle2: String {
        return ""
    }

    func getNavigationTitle() -> String {
        return LocalString._settings_mobile_signature_title
    }

    func isDisplaySwitch() -> Bool {
        return true
    }

    func getSwitchText() -> String {
        return LocalString._settings_enable_mobile_signature_title
    }

    func getSwitchStatus() -> Bool {
        return userManager.showMobileSignature
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
        return userManager.mobileSignature
    }

    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void) {
        if new_value == getCurrentValue() {
            complete(true, nil)
        } else {
            let newValueToSave = new_value.trim().ln2br()
            userManager.mobileSignature = newValueToSave
            userManager.save()
            complete(true, nil)
        }
    }

    func updateNotification(_ isOn: Bool, complete: @escaping (Bool, NSError?) -> Void) {
        if isOn == getSwitchStatus() {
            complete(true, nil)
        } else {
            userManager.showMobileSignature = isOn
            complete(true, nil)
        }
    }

    func isSwitchEnabled() -> Bool {
        return getRole()
    }

    func getNotes() -> String {
        return ""
    }

    internal func getRole() -> Bool {
#if Enterprise
        let isEnterprise = true
#else
        let isEnterprise = false
#endif
        let role = userManager.userInfo.role
        return role > 0 || isEnterprise
    }

    func needAsk2FA() -> Bool {
        return false
    }
}

class ChangeNotificationEmailViewModel: SettingDetailsViewModel {
    let userManager: UserManager

    required init(user: UserManager) {
        self.userManager = user
    }

    var sectionTitle2: String {
        return LocalString._settings_notification_email_section_title
    }

    func getNavigationTitle() -> String {
        return LocalString._settings_notification_email
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
        return userManager.notify
    }

    func isShowTextView() -> Bool {
        return false
    }

    func getPlaceholdText() -> String {
        return LocalString._settings_notification_email_placeholder
    }

    func getCurrentValue() -> String {
        return userManager.notificationEmail
    }

    func updateValue(_ new_value: String, password: String, tfaCode: String?, complete: @escaping (Bool, NSError?) -> Void) {
        if new_value == getCurrentValue() {
            complete(true, nil)
        } else {
            let service = userManager.userService
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

    func updateNotification(_ isOn: Bool, complete: @escaping (Bool, NSError?) -> Void) {
        if isOn == getSwitchStatus() {
            complete(true, nil)
        } else {
            let service = userManager.userService
            service.updateNotify(auth: userManager.auth,
                                 user: userManager.userInfo,
                                 isOn, completion: { _, _, error in
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

    func getNotes() -> String {
        return ""
    }

    func needAsk2FA() -> Bool {
        return userManager.userInfo.twoFactor > 0
    }
}
