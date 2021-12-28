//
//  ClientApp.swift
//  ProtonCore-DataModel - Created on 07/12/2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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

public enum ClientApp: Codable, Equatable {
    case mail
    case vpn
    case drive
    case calendar
    case other(named: String)
    
    public var name: String {
        // this name is used in requests to our BE and should not be changed
        // without checking the affected place and consulting the changes with BE devs
        switch self {
        case .mail: return "mail"
        case .vpn: return "vpn"
        case .drive: return "drive"
        case .calendar: return "calendar"
        case .other(let named): return named
        }
    }
}
