//
//  MenuViewModelImpl.swift
//  ProtonMail - Created - on 11/20/17.
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
import CoreData
import UIKit


enum AccountSection {
    case users
    case add
}

class AccountManagerViewModel {
    private let kMenuCellHeight: CGFloat = 44.0
    private let kUserCellHeight: CGFloat = 60.0
    
    func cellHeight(at: Int) -> CGFloat {
        let section = self.section(at: at)
        switch section {
        case .users:
            return kUserCellHeight
        default:
            return kMenuCellHeight
        }
    }
    
    func user(at: Int) -> UserManager? {
        return self.usersManager.user(at: at)
    }
    
    var usersCount: Int {
        get {
            return self.usersManager.count
        }
    }
    
    //menu sections
    private var sections : [AccountSection] = [.users, .add]

    private var showingUsers: Bool = false
    
    //
    let usersManager : UsersManager
    
    
    init(usersManager : UsersManager) {
        self.usersManager = usersManager
    }
    
    func signOut() {
         self.usersManager.loggedOutAll()
    }

    func sectionCount() -> Int {
        return self.sections.count
    }
    
    func section(at: Int) -> AccountSection {
        if at < self.sectionCount() {
            return sections[at]
        }
        return .users
    }
        
    func rowCount(at section : Int) -> Int {
        let s = sections[section]
        
        switch s {
        case .users:
            return self.usersCount
        case .add:
            return 1
        }
    }
    
}
