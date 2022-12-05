//
//  NSMutableAttributedString.swift
//  ProtonCore-Login - Created on 27.11.2020.
//
//  Copyright (c) 2022 Proton Technologies AG
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

public extension NSMutableAttributedString {
    func setAttributes(textToFind: String, attributes: [NSAttributedString.Key: Any]) -> Bool {
        let foundRange = self.mutableString.range(of: textToFind)
        if foundRange.location != NSNotFound {
            self.setAttributes(attributes, range: foundRange)
            return true
        }
        return false
    }
    
    func addHyperLink(subString: String, link: String, font: UIFont? = nil) {
        if let subStrRange = self.string.range(of: subString) {
            let nsRange = NSRange(subStrRange, in: self.string)
            self.addAttributes([.link: link], range: nsRange)
            if let font = font {
                self.addAttributes([.font: font], range: nsRange)
            }
        }
    }
    
    func addHyperLinks(hyperlinks: [String: String]) {
        for (key, value) in hyperlinks {
            self.addHyperLink(subString: key, link: value)
        }
    }
}

public extension NSAttributedString {
    static func hyperlink(in string: String, as substring: String, path: String, subfont: UIFont?) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attributerString = NSMutableAttributedString(string: string, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        attributerString.addHyperLink(subString: substring, link: path, font: subfont)
        return attributerString
    }
}

public extension String {
    func buildAttributedString(font: UIFont, color: UIColor) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: self,
                                         attributes: [NSAttributedString.Key.font: font,
                                                      NSAttributedString.Key.foregroundColor: color])
    }
}
