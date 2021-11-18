//
//  Coordinator+SWReveal.swift
//  ProtonMail - Created on 12/12/18.
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
import SideMenuSwift


protocol SideMenuCoordinator: DefaultCoordinator {
    /// this will be called before push
    var configuration: ((VC) -> ())? { get }
    
    var navigation: UIViewController? { get set }
    var sideMenu: SideMenuController? { get set }
}


extension SideMenuCoordinator where VC: CoordinatedNew {
    func start() {
        guard let viewController = viewController else {
            return
        }
        configuration?(viewController) //set viewmodel and coordinator
        if self.navigation != nil, self.sideMenu != nil {
            self.sideMenu?.setContentViewController(to: self.navigation!)
            self.sideMenu?.hideMenu()
        }
        self.processDeepLink()
    }
    
    func stop() {
//        delegate?.willStop(in: self)
        //navigationController.popViewController(animated: animated)
//        delegate?.didStop(in: self)
    }
}
