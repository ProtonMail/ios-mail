//
//  AccountManagerViewModel.swift
//  ProtonCore-AccountSwitcher - Created on 03.06.2021
//
//  Copyright (c) 2022 Proton Technologies AG
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

protocol AccountManagerVMProtocl: AnyObject {
    func getSignedInAccountAmount() -> Int
    func getSignedOutAccountAmount() -> Int
    func getSignedInAccount(in row: Int) -> AccountSwitcher.AccountData?
    func getSignedOutAccount(in row: Int) -> AccountSwitcher.AccountData?
    func getAccountData(of userID: String) -> AccountSwitcher.AccountData?

    func signinAccount(for mail: String, userID: String?)
    func signoutAccount(userID: String)
    func switchToAccount(userID: String)
    func removeAccount(userID: String)
    func accountManagerWillAppear()
    func accountManagerWillDisappear()
}

public protocol AccountManagerVMDataSource: AnyObject {
    func set(delegate: AccountSwitchDelegate)
    func updateAccountList(list: [AccountSwitcher.AccountData])
}

public final class AccountManagerViewModel: NSObject {
    private var accounts: [AccountSwitcher.AccountData]
    private weak var uiDelegate: AccountManagerUIProtocl?
    private weak var delegate: AccountSwitchDelegate?

    public init(accounts: [AccountSwitcher.AccountData], uiDelegate: AccountManagerUIProtocl) {
        self.accounts = accounts
        self.uiDelegate = uiDelegate
        super.init()
        if let vc = uiDelegate as? AccountManagerVC {
            vc.set(viewModel: self)
        }
    }
}

extension AccountManagerViewModel: AccountManagerVMProtocl {

    func getSignedInAccountAmount() -> Int {
        return self.accounts.filter { $0.isSignin == true }.count
    }

    func getSignedOutAccountAmount() -> Int {
        return self.accounts.filter { $0.isSignin == false }.count
    }

    func getSignedInAccount(in row: Int) -> AccountSwitcher.AccountData? {
        let list = self.accounts.filter { $0.isSignin == true }
        guard list.count > row else { return nil }
        return list[row]
    }

    func getSignedOutAccount(in row: Int) -> AccountSwitcher.AccountData? {
        let list = self.accounts.filter { $0.isSignin == false }
        guard list.count > row else { return nil }
        return list[row]
    }

    func getAccountData(of userID: String) -> AccountSwitcher.AccountData? {
        return self.accounts.first(where: { $0.userID == userID })
    }

    func signinAccount(for mail: String, userID: String?) {
        self.uiDelegate?.dismiss()
        self.delegate?.signinAccount(for: mail, userID: userID)
    }

    func signoutAccount(userID: String) {
        self.delegate?.signoutAccount(userID: userID, viewModel: self)
    }

    func switchToAccount(userID: String) {
        self.uiDelegate?.dismiss()
        self.delegate?.switchTo(userID: userID)
    }

    func removeAccount(userID: String) {
        self.delegate?.removeAccount(userID: userID, viewModel: self)
    }

    func accountManagerWillAppear() {
        self.delegate?.accountManagerWillAppear()
    }

    func accountManagerWillDisappear() {
        self.delegate?.accountManagerWillDisappear()
    }
}

extension AccountManagerViewModel: AccountManagerVMDataSource {
    public func set(delegate: AccountSwitchDelegate) {
        self.delegate = delegate
    }

    public func updateAccountList(list: [AccountSwitcher.AccountData]) {
        self.accounts = list
        self.uiDelegate?.reload()
    }
}
