//
//  PMActionSheetError.swift
//  ProtonMail - Created on 21.07.20.
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

import Foundation

enum PMActionSheetError: Error, LocalizedError {
    case itemGroupMissing
    case unknowItem
    case initializeFailed
    case styleError

    var localizedDescription: String {
        switch self {
        case .itemGroupMissing:
            return "Item group is missing"
        case .unknowItem:
            return "Can't get item by given indexPath"
        case .initializeFailed:
            return "At least one of needed parameters missing"
        case .styleError:
            return "Must be Grid style"
        }
    }
}
