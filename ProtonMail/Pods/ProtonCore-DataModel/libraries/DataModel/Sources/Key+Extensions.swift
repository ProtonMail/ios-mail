//
//  Key+Extensions.swift
//  ProtonCore-DataModel - Created on 4/19/21.
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
//

import Foundation

extension Array where Element: Key {
    func archive() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    
    @available(*, deprecated, renamed: "isKeyV2")
    public var newSchema: Bool {
        for key in self where key.newSchema {
            return true
        }
        return false
    }
    
    public var isKeyV2: Bool {
        for key in self where key.isKeyV2 {
            return true
        }
        return false
    }
    
}
