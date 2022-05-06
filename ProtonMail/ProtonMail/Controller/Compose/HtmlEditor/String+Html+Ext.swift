//
//  String+Html+Ext.swift
//  Proton Mail - Created on 5/8/15.
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

extension String {
    /// A string with the special characters in it escaped.
    /// Used when passing a string into JavaScript, so the string is not completed too soon
    /// Performance is not good for large string - Notes from Feng
    var escaped: String {
        var arr = [String]()
        for u in self.utf16 {
            arr.append("\\u\(String(format: "%04X", u))")
        }
        let str = arr.joined()
        return str
    }
}
