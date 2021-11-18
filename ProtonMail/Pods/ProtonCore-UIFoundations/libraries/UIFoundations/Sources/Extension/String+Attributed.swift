//
//  String+Attributed.swift
//  ProtonCore-UIFoundations - Created on 13.09.21.
//
//  Copyright (c) 2020 Proton Technologies AG
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

import UIKit

public extension String {
    func getAttributedString(replacement: String, attrFont: UIFont, attrColor: UIColor = ColorProvider.TextNorm) -> NSMutableAttributedString {
        let attrStr = NSMutableAttributedString(string: self)
        if let range = range(of: replacement) {
            let boldedRange = NSRange(range, in: self)
            attrStr.addAttributes([.font: attrFont, .foregroundColor: attrColor], range: boldedRange)
        }
        return attrStr
    }
}
