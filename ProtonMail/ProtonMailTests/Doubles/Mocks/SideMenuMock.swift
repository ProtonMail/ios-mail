//
//  SideMenuMock.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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
//  along with ProtonMail. If not, see <https://www.gnu.org/licenses/>.

@testable import ProtonMail
import ProtonCore_TestingToolkit

class SideMenuMock: SideMenuProtocol {
    var menuViewController: UIViewController! = nil

    @FuncStub(SideMenuMock.hideMenu) var hideMenu
    func hideMenu(animated: Bool, completion: ((Bool) -> Void)?) {
        hideMenu(animated, completion)
    }

    @FuncStub(SideMenuMock.revealMenu) var revealMenu
    func revealMenu(animated: Bool, completion: ((Bool) -> Void)?) {
        revealMenu(animated, completion)
    }

    @FuncStub(SideMenuMock.setContentViewController) var setContentViewController
    func setContentViewController(to viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        setContentViewController(viewController, animated, completion)
    }

}
