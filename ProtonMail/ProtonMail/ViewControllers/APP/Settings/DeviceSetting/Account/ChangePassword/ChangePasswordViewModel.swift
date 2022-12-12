//
//  ChangePasswordViewModel.swift
//  Proton Mail - Created on 3/18/15.
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

import ProtonCore_Crypto

protocol ChangePasswordViewModel {
    init(user: UserManager)
    func getNavigationTitle() -> String
    func getCurrentPasswordEditorTitle() -> String
    func getNewPasswordEditorTitle() -> String
    func getConfirmPasswordEditorTitle() -> String
    func needAsk2FA() -> Bool
    func setNewPassword(_ current: String,
                        newPassword: Passphrase,
                        confirmNewPassword: Passphrase,
                        tFACode: String?,
                        complete: @escaping (NSError?) -> Void)
}

class ChangeLoginPWDViewModel: ChangePasswordViewModel {

    let userManager: UserManager

    required init(user: UserManager) {
        self.userManager = user
    }

    func getNavigationTitle() -> String {
        return LocalString._setting_change_password
    }

    func getCurrentPasswordEditorTitle() -> String {
        return LocalString._current_signin_password
    }

    func getNewPasswordEditorTitle() -> String {
        return LocalString._new_signin_password
    }

    func getConfirmPasswordEditorTitle() -> String {
        return LocalString._confirm_new_signin_password
    }

    func needAsk2FA() -> Bool {
        return self.userManager.userInfo.twoFactor > 0
    }

    func setNewPassword(_ current: String,
                        newPassword: Passphrase,
                        confirmNewPassword: Passphrase,
                        tFACode: String?,
                        complete: @escaping (NSError?) -> Void) {
        let currentPassword = current // .trim();
        let newpwd = newPassword // .trim();
        let confirmpwd = confirmNewPassword // .trim();

        if newpwd.isEmpty || confirmpwd.isEmpty {
            complete(UpdatePasswordError.passwordEmpty.error)
        } else if newpwd.value.count < 8 {
            complete(UpdatePasswordError.minimumLengthError.error)
        } else if newpwd != confirmpwd {
            complete(UpdatePasswordError.newNotMatch.error)
        } else {
            self.userManager.userService.updatePassword(
                auth: userManager.authCredential,
                user: userManager.userInfo,
                login_password: currentPassword,
                new_password: newpwd,
                twoFACode: tFACode,
                completion: complete
            )
        }
    }
}

class ChangeMailboxPWDViewModel: ChangePasswordViewModel {
    let userManager: UserManager

    required init(user: UserManager) {
        self.userManager = user
    }

    func getNavigationTitle() -> String {
        return LocalString._setting_change_password
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
                        newPassword: Passphrase,
                        confirmNewPassword: Passphrase,
                        tFACode: String?,
                        complete: @escaping (NSError?) -> Void) {
        // passwords support empty spaces like " 1 1 "
        let currentPassword = current
        let confirmpwd = confirmNewPassword

        if newPassword.isEmpty || confirmpwd.isEmpty {
            complete(UpdatePasswordError.passwordEmpty.error)
        } else if newPassword != confirmpwd {
            complete(UpdatePasswordError.newNotMatch.error)
        } else {
            self.userManager.userService.updateMailboxPassword(
                auth: userManager.authCredential,
                user: userManager.userInfo,
                loginPassword: currentPassword,
                newPassword: newPassword,
                twoFACode: tFACode,
                buildAuth: false,
                completion: complete
            )
        }
    }
}

class ChangeSinglePasswordViewModel: ChangePasswordViewModel {

    let userManager: UserManager

    required init(user: UserManager) {
        self.userManager = user
    }

    func getNavigationTitle() -> String {
        return LocalString._setting_change_password
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
                        newPassword: Passphrase,
                        confirmNewPassword: Passphrase,
                        tFACode: String?,
                        complete: @escaping (NSError?) -> Void) {
        // passwords support empty spaces like " * * "
        let currentPassword = current
        let confirmpwd = confirmNewPassword
        if newPassword.isEmpty || confirmpwd.isEmpty {
            complete(UpdatePasswordError.passwordEmpty.error)
        } else if newPassword.value.count < 8 {
            complete(UpdatePasswordError.minimumLengthError.error)
        } else if newPassword != confirmpwd {
            complete(UpdatePasswordError.newNotMatch.error)
        } else {
            let service = self.userManager.userService
            service.updateMailboxPassword(auth: userManager.authCredential,
                                          user: userManager.userInfo,
                                          loginPassword: currentPassword,
                                          newPassword: newPassword,
                                          twoFACode: tFACode,
                                          buildAuth: true) { error in
                if error == nil {
                    self.userManager.save()
                }
                complete(error)
            }
        }
    }
}
