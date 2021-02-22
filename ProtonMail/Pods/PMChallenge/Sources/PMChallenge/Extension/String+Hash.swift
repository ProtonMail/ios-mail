//
//  String+Hash.swift
//  ProtonMail - Created on 6/08/20.
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

extension String {
    func rollingHash(base: Int = 7, mod: Int64 = 100000007) -> Int {
        let base = Int64(base)
        var ans = 0
        var coefficient: Int64 = 0
        for str in self {
            for code in str.utf8 {
                if coefficient == 0 {
                    coefficient = 1
                } else {
                    coefficient = coefficient * base % mod
                }
                ans += Int(code) * Int(coefficient)
            }
        }
        return ans
    }
}
