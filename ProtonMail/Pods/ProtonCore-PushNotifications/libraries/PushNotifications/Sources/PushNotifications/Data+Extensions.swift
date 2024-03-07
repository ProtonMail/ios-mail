//
//  Data+Extensions.swift
//  proton-push-notifications - Created on 9/6/23.
//
//  Copyright (c) 2023 Proton AG
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

extension Data {
    /// returns the hex representation of binary data
    func toHexRepresentation() -> String {
        self.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
