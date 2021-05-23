//
//  LabelCount.swift
//  ProtonMail - Created on 2020.
//
//
//  Copyright (c) 2020 Proton Technologies AG
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
//

import CoreData
import Foundation

protocol LabelCount: NSManagedObject {
    var userID: String { get set }
    var labelID: String { get set }

    var start: Date? { get set }
    var end: Date? { get set }
    var update: Date? { get set }
    
    //Used for unread msg filtering
    var unreadStart: Date? { get set }
    var unreadEnd: Date? { get set }
    var unreadUpdate: Date? { get set }

    var total: Int32 { get set }
    var unread: Int32 { get set }
}

extension LabelCount {
    var isNew: Bool {
        return start == end && start == update
    }

    var startTime: Date {
        return start ?? Date.distantPast
    }

    var endTime: Date {
        return end ?? Date.distantPast
    }
    
    var isUnreadNew: Bool {
        return unreadStart == unreadEnd && unreadStart == unreadUpdate
    }
    
    var unreadStartTime: Date {
        return unreadStart ?? Date.distantPast
    }
    
    var unreadEndTime: Date {
        return unreadEnd ?? Date.distantPast
    }
}
