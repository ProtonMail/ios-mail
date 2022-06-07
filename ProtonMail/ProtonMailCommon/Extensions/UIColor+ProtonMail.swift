//
// UIColor+ProtonMail.swift
// Proton Mail
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
import UIKit

extension UIColor {

    convenience init(RRGGBB: UInt) {
        self.init(
            red: CGFloat((RRGGBB & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((RRGGBB & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(RRGGBB & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }

    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        self.init(
            red: r / 255.0,
            green: g / 255.0,
            blue: b / 255.0,
            alpha: a
        )
    }

    func toHex() -> String {
        guard let components = self.cgColor.components else {
            return "#000000"
        }

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0

        if self.cgColor.numberOfComponents < 3 {
            // UIExtendedGrayColorSpace
            r = components[0]
            g = components[0]
            b = components[0]
        } else {
            r = components[0]
            g = components[1]
            b = components[2]
        }

        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
    }

    struct ProtonMail {
        static let onboardingImageBackgroundColor = UIColor(r: 245, g: 247, b: 250, a: 1)
    }
}

extension UIColor {

    convenience init(hexColorCode: String) {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 1.0

        if hexColorCode.hasPrefix("#") {
            let index   = hexColorCode.index(hexColorCode.startIndex, offsetBy: 1)
            let hex     = String(hexColorCode[index...])
            let scanner = Scanner(string: hex)
            var hexValue: CUnsignedLongLong = 0

            if scanner.scanHexInt64(&hexValue) {
                if hex.count == 6 {
                    red   = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
                    blue  = CGFloat(hexValue & 0x0000FF) / 255.0
                } else if hex.count == 8 {
                    red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                    blue  = CGFloat((hexValue & 0x0000FF00) >> 8) / 255.0
                    alpha = CGFloat(hexValue & 0x000000FF) / 255.0
                }
            }
        }
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// Other Methods
extension UIColor {
    /**
     Create non-autoreleased color with in the given hex string and alpha
     
     :param:   hexString
     :param:   alpha
     :returns: color with the given hex string and alpha
     
     
     Example:
     
     // With hash
     let color: UIColor = UIColor(hexString: "#ff8942")
     
     // Without hash, with alpha
     let secondColor: UIColor = UIColor(hexString: "ff8942", alpha: 0.5)
     
     // Short handling
     let shortColorWithHex: UIColor = UIColor(hexString: "fff")
     */

    convenience init(hexString: String, alpha: Float) {
        var hex = hexString

        // Check for hash and remove the hash
        if hex.hasPrefix("#") {
            let hexL = hex.index(hex.startIndex, offsetBy: 1)
            hex = String(hex[hexL...])
        }

        if hex.count == 0 {
            hex = "000000"
        }

        let hexLength = hex.count
        // Check for string length
        assert(hexLength == 6 || hexLength == 3)

        // Deal with 3 character Hex strings
        if hexLength == 3 {
            let redR = hex.index(hex.startIndex, offsetBy: 1)
            let redHex = String(hex[..<redR])
            let greenL = hex.index(hex.startIndex, offsetBy: 1)
            let greenR = hex.index(hex.startIndex, offsetBy: 2)
            let greenHex = String(hex[greenL..<greenR])
            let blueL = hex.index(hex.startIndex, offsetBy: 2)
            let blueHex = String(hex[blueL...])
            hex = redHex + redHex + greenHex + greenHex + blueHex + blueHex
        }
        let redR = hex.index(hex.startIndex, offsetBy: 2)
        let redHex = String(hex[..<redR])
        let greenL = hex.index(hex.startIndex, offsetBy: 2)
        let greenR = hex.index(hex.startIndex, offsetBy: 4)
        let greenHex = String(hex[greenL..<greenR])

        let blueL = hex.index(hex.startIndex, offsetBy: 4)
        let blueR = hex.index(hex.startIndex, offsetBy: 6)
        let blueHex = String(hex[blueL..<blueR])

        var redInt: CUnsignedInt = 0
        var greenInt: CUnsignedInt = 0
        var blueInt: CUnsignedInt = 0

        Scanner(string: redHex).scanHexInt32(&redInt)
        Scanner(string: greenHex).scanHexInt32(&greenInt)
        Scanner(string: blueHex).scanHexInt32(&blueInt)

        self.init(red: CGFloat(redInt) / 255.0, green: CGFloat(greenInt) / 255.0, blue: CGFloat(blueInt) / 255.0, alpha: CGFloat(alpha))
    }
}
