//
//  PMTabBArError.swift
//  ProtonCore-UIFoundations - Created on 15.07.20.
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

enum PMTabBarError: Error, LocalizedError {
    case configMissing
    case countNotEqual
    case emptyItemAndVC
    case cannotUpdate

    var localizedDescription: String {
        switch self {
        case .configMissing:
            return "Tabbar config is missing"
        case .countNotEqual:
            return "Count of bar items and viewcontrollers is not equal"
        case .emptyItemAndVC:
            return "Haven't set tab bar items and viewcontrollers"
        case .cannotUpdate:
            return "Can't update this value after initialization"
        }
    }
}
