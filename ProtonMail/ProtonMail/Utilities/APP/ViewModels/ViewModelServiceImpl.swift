//
//  ViewModelServiceImpl.swift
//  Proton Mail - Created on 6/18/15.
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

// needs refactor while dealing with Contact views
let sharedVMService: ViewModelServiceImpl = ViewModelServiceImpl()

class ViewModelServiceImpl {
    private var activeViewControllerNew: ViewModelProtocolBase?

    func signOut() {
        self.resetView()
    }

    func resetView() {
        DispatchQueue.main.async {
            if let actived = self.activeViewControllerNew {
                actived.inactiveViewModel()
                self.activeViewControllerNew = nil
            }
        }
    }

    func mailbox(fromMenu vmp: ViewModelProtocolBase) {
        if let oldVC = activeViewControllerNew {
            oldVC.inactiveViewModel()
        }
        activeViewControllerNew = vmp
    }
}
