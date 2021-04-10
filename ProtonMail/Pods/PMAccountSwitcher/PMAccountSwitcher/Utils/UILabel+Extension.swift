//
//  UILabel+Extension.swift
//  ProtonMail
//
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

import UIKit

extension UILabel {
    convenience init(_ _text: String?,
                     font _font: UIFont?,
                     textColor _color: UIColor?,
                     alignment: NSTextAlignment = .left,
                     useAutoLayout: Bool = false) {
        self.init(frame: .zero)
        text = _text
        textAlignment = alignment
        translatesAutoresizingMaskIntoConstraints = !useAutoLayout

        if let _font = _font {
            font = _font
        }

        if let _color = _color {
            textColor = _color
        }
    }
}
