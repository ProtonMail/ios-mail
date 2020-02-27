//
//  AutolockTimeout.swift
//  Keymaker - Created on 23/10/2018.
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

public enum AutolockTimeout: RawRepresentable {
    case never
    case always
    case minutes(Int)
    
    public init(rawValue: Int) {
        switch rawValue {
        case -1: self = .never
        case 0: self = .always
        case let number: self = .minutes(number)
        }
    }
    
    public var rawValue: Int {
        switch self {
        case .never: return -1
        case .always: return 0
        case .minutes(let number): return number
        }
    }
}
