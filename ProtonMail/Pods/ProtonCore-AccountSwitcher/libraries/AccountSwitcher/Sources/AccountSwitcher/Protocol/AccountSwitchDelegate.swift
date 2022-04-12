//
//  AccountSwitchDelegate.swift
//  ProtonCore-AccountSwitcher - Created on 03.06.2021
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

public protocol AccountSwitchDelegate: AnyObject {
    // MARK: Optional
    func switcherWillAppear()
    func switcherWillDisappear()
    func accountManagerWillAppear()
    func accountManagerWillDisappear()

    // MARK: Required
    func switchTo(userID: String)
    func signinAccount(for mail: String, userID: String?)
    func signoutAccount(userID: String, viewModel: AccountManagerVMDataSource)
    func removeAccount(userID: String, viewModel: AccountManagerVMDataSource)
}

public extension AccountSwitchDelegate {
    func switcherWillAppear() {}
    func switcherWillDisappear() {}
    func accountManagerWillAppear() {}
    func accountManagerWillDisappear() {}
}
