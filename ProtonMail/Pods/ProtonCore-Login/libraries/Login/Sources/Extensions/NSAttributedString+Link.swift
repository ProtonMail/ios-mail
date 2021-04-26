//
//  NSAttributedString+Link.swift
//  PMLogin - Created on 11/03/2021.
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

#if canImport(UIKit)

import Foundation
import UIKit

extension NSAttributedString {
    static func hyperlink(path: String, in string: String, as substring: String, alignment: NSTextAlignment = .left, font: UIFont?) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        let nsString = NSString(string: string)
        let substringRange = nsString.range(of: substring)
        let attributerString = NSMutableAttributedString(string: string, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        attributerString.addAttribute(.link, value: path, range: substringRange)
        if let font = font {
            attributerString.addAttribute(.font, value: font, range: nsString.range(of: string))
        }
        return attributerString
    }
}

#endif
