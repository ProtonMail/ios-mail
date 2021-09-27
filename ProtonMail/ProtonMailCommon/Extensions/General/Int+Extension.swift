//
//  Int+Extension.swift
//  ProtonMail - Created on 9/11/18.
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

extension Int {
    //TODO:: the error code should be in same place, this extension could move to the error code class
    /// check if response code is 5003
    var forceUpgrade : Bool {
        get {
            return self == 5003
        }
    }

    var toByteCount: String {
        let byteCountFormatter = ByteCountFormatter()
        return byteCountFormatter.string(fromByteCount: Int64(self))
    }
}
