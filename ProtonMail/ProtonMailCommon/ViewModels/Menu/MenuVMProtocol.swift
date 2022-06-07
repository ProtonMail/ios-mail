//
//  MenuVMProtocol.swift
//  Proton Mail
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
import PromiseKit
import ProtonCore_AccountSwitcher

protocol MenuVMProtocol: AnyObject {
    var menuWidth: CGFloat! { get }
    var sections: [MenuSection] { get }
    var folderItems: [MenuLabel] { get }
    var currentUser: UserManager? { get }
    var secondUser: UserManager? { get }
    var enableFolderColor: Bool { get }
    var reloadClosure: (() -> Void)? { get set }

    func userDataInit()
    func menuViewInit()
    func getMenuItem(indexPath: IndexPath) -> MenuLabel?
    func numberOfRowsIn(section: Int) -> Int
    func clickCollapsedArrow(labelID: String)
    func isCurrentUserHasQueuedMessage() -> Bool
    func removeAllQueuedMessageOfCurrentUser()
    func signOut(userID: String, completion: (() -> Void)?)
    func removeDisconnectAccount(userID: String)
    func highlight(label: MenuLabel)
    func appVersion() -> String
    func getAccountList() -> [AccountSwitcher.AccountData]
    func getUnread(of userID: String) -> Int
    func activateUser(id: String)
    func prepareLogin(userID: String)
    func prepareLogin(mail: String)
    func set(menuWidth: CGFloat)
    func getIconColor(of label: MenuLabel) -> UIColor
    func allowToCreate(type: PMLabelType) -> Bool
}

protocol MenuUIProtocol: UIViewController {
    func update(email: String)
    func update(displayName: String)
    func update(avatar: String)
    func showToast(message: String)
    func updateMenu(section: Int?)
    func update(rows: [IndexPath],
                insertRows: [IndexPath],
                deleteRows: [IndexPath])
    func navigateTo(label: MenuLabel)
}
