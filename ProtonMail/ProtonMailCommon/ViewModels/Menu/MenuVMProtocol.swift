//
//  MenuVMProtocol.swift
//  ProtonMail
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
import PromiseKit
import ProtonCore_AccountSwitcher

protocol MenuVMProtocol: AnyObject {
    var menuWidth: CGFloat! { get }
    var sections: [MenuSection] { get }
    var folderItems: [MenuLabel] { get }
    var currentUser: UserManager? { get }
    var secondUser: UserManager? { get }
    var enableFolderColor: Bool { get }
    var isInAppFeedbackEnable: Bool { get }
    var reloadClosure: (() -> Void)? { get set }
    
    func userDataInit()
    func menuViewInit()
    func getMenuItem(indexPath: IndexPath) -> MenuLabel?
    func numberOfRowsIn(section: Int) -> Int
    func clickCollapsedArrow(labelID: String)
    func isCurrentUserHasQueuedMessage() -> Bool
    func removeAllQueuedMessageOfCurrentUser()
    func signOut(userID: String) -> Promise<Void>
    func removeDisconnectAccount(userID: String)
    func subscriptionUnavailable()
    func highlight(label: MenuLabel)
    func appVersion() -> String
    func getAccountList() -> [AccountSwitcher.AccountData]
    func getUnread(of userID: String) -> Promise<Int>
    func activateUser(id: String)
    func prepareLogin(userID: String)
    func prepareLogin(mail: String)
    func set(menuWidth: CGFloat)
    func getColor(of label: MenuLabel) -> UIColor
    func allowToCreate(type: PMLabelType) -> Bool
}


protocol MenuUIProtocol: UIViewController {
    func update(email: String)
    func update(displayName: String)
    func update(avatar: String)
    func showToast(message: String)
    func showAlert(title: String, message: String)
    func updateMenu(section: Int?)
    func update(rows: [IndexPath],
                insertRows: [IndexPath],
                deleteRows: [IndexPath])
    func reloadRow(indexPath: IndexPath)
    func insertRows(indexPaths: [IndexPath])
    func deleteRows(indexPaths: [IndexPath])
    func navigateTo(label: MenuLabel)
}
