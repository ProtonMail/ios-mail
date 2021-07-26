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

typealias ChangePasswordComplete = (Bool, NSError?) -> Void

protocol ChangePasswordViewModel {

    func getNavigationTitle() -> String
    func getSectionTitle() -> String
    func getCurrentPasswordEditorTitle() -> String
    func getNewPasswordEditorTitle() -> String
    func getConfirmPasswordEditorTitle() -> String
    func needAsk2FA() -> Bool
    func setNewPassword(_ current: String,
                        newPassword: String,
                        confirmNewPassword: String,
                        tFACode: String?,
                        complete: @escaping ChangePasswordComplete)
}

class ChangeLoginPWDViewModel: ChangePasswordViewModel {

    let userManager: UserManager

    init(user: UserManager) {
        self.userManager = user
    }

    public func getNavigationTitle() -> String {
        return LocalString._setting_change_password
    }

    public func getSectionTitle() -> String {
        return LocalString._change_signin_password
    }

    public func getCurrentPasswordEditorTitle() -> String {
        return LocalString._current_signin_password
    }

    public func getNewPasswordEditorTitle() -> String {
        return LocalString._new_signin_password
    }

    public func getConfirmPasswordEditorTitle() -> String {
        return LocalString._confirm_new_signin_password
    }

    public func needAsk2FA() -> Bool {
        return self.userManager.userInfo.twoFactor > 0
    }

    public func setNewPassword(_ current: String,
                               newPassword: String,
                               confirmNewPassword: String,
                               tFACode: String?,
                               complete: @escaping ChangePasswordComplete) {
        let currentPassword = current // .trim();
        let newpwd = newPassword // .trim();
        let confirmpwd = confirmNewPassword // .trim();

        if newpwd.isEmpty || confirmpwd.isEmpty {
            complete(false, UpdatePasswordError.passwordEmpty.error)
        } else if newpwd.count < 8 {
            complete(false, UpdatePasswordError.minimumLengthError.error)
        } else if newpwd != confirmpwd {
            complete(false, UpdatePasswordError.newNotMatch.error)
        } else {
            self.userManager.userService.updatePassword(auth: userManager.auth,
                                                        user: userManager.userInfo,
                                                        login_password: currentPassword,
                                                        new_password: newpwd,
                                                        twoFACode: tFACode) { _, _, error in
                if let error = error {
                    complete(false, error)
                } else {
                    complete(true, nil)
                }
            }
        }
    }
}

class ChangeMailboxPWDViewModel: ChangePasswordViewModel {
    let userManager: UserManager

    init(user: UserManager) {
        self.userManager = user
    }

    func getNavigationTitle() -> String {
        return LocalString._setting_change_password
    }
    func getSectionTitle() -> String {
        return LocalString._change_mailbox_password
    }

    func getCurrentPasswordEditorTitle() -> String {
        return LocalString._current_signin_password
    }

    func getNewPasswordEditorTitle() -> String {
        return LocalString._new_mailbox_password
    }

    func getConfirmPasswordEditorTitle() -> String {
        return LocalString._confirm_new_mailbox_password
    }

    func needAsk2FA() -> Bool {
        return self.userManager.userInfo.twoFactor > 0
    }

    func setNewPassword(_ current: String,
                        newPassword: String,
                        confirmNewPassword: String,
                        tFACode: String?,
                        complete: @escaping ChangePasswordComplete) {
        // passwords support empty spaces like " 1 1 "
        let currentPassword = current
        let confirmpwd = confirmNewPassword

        if newPassword.isEmpty || confirmpwd.isEmpty {
            complete(false, UpdatePasswordError.passwordEmpty.error)
        } else if newPassword != confirmpwd {
            complete(false, UpdatePasswordError.newNotMatch.error)
        } else {
            self.userManager.userService.updateMailboxPassword(auth: userManager.auth,
                                                               user: userManager.userInfo,
                                                               loginPassword: currentPassword,
                                                               newPassword: newPassword,
                                                               twoFACode: tFACode,
                                                               buildAuth: false) { _, _, error in
                if let error = error {
                    complete(false, error)
                } else {
                    complete(true, nil)
                }
            }
        }
    }
}

class ChangeSinglePasswordViewModel: ChangePasswordViewModel {

    let userManager: UserManager

    init(user: UserManager) {
        self.userManager = user
    }

    func getNavigationTitle() -> String {
        return LocalString._setting_change_password
    }
    func getSectionTitle() -> String {
        return LocalString._change_single_password
    }

    func getCurrentPasswordEditorTitle() -> String {
        return LocalString._settings_current_password
    }

    func getNewPasswordEditorTitle() -> String {
        return LocalString._settings_new_password
    }

    func getConfirmPasswordEditorTitle() -> String {
        return LocalString._settings_confirm_new_password
    }

    func needAsk2FA() -> Bool {
        return userManager.userInfo.twoFactor > 0
    }

    func setNewPassword(_ current: String,
                        newPassword: String,
                        confirmNewPassword: String,
                        tFACode: String?,
                        complete: @escaping ChangePasswordComplete) {
        // passwords support empty spaces like " * * "
        let currentPassword = current
        let confirmpwd = confirmNewPassword
        if newPassword.isEmpty || confirmpwd.isEmpty {
            complete(false, UpdatePasswordError.passwordEmpty.error)
        } else if newPassword.count < 8 {
            complete(false, UpdatePasswordError.minimumLengthError.error)
        } else if newPassword != confirmpwd {
            complete(false, UpdatePasswordError.newNotMatch.error)
        } else {
            let service = self.userManager.userService
            service.updateMailboxPassword(auth: userManager.auth,
                                          user: userManager.userInfo,
                                          loginPassword: currentPassword,
                                          newPassword: newPassword,
                                          twoFACode: tFACode,
                                          buildAuth: true) { _, _, error in
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

class ChangePWDViewModelTest: ChangePasswordViewModel {
    func getNavigationTitle() -> String {
        return "PASSWORD - Test"
    }
    func getSectionTitle() -> String {
        return "Change Mailbox Password - Test"
    }

    func getCurrentPasswordEditorTitle() -> String {
        return "Current mailbox password - Test"
    }

    func getNewPasswordEditorTitle() -> String {
        return "New mailbox password - Test"
    }

    func getConfirmPasswordEditorTitle() -> String {
        return "Confirm new mailbox password - Test"
    }

    func needAsk2FA() -> Bool {
        return false
    }

    func setNewPassword(_ current: String,
                        newPassword: String,
                        confirmNewPassword: String,
                        tFACode: String?,
                        complete: @escaping (Bool, NSError?) -> Void) {
        // add random test case and random
        // remove space.
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
