//
// UIColor+ProtonMail.swift
// ProtonMail
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
import UIKit

extension UIColor {
    
    convenience init(RRGGBB: UInt, alpha: CGFloat) {
        self.init(
            red: CGFloat((RRGGBB & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((RRGGBB & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(RRGGBB & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
    
    convenience init(RRGGBB: UInt) {
        self.init(
            red: CGFloat((RRGGBB & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((RRGGBB & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(RRGGBB & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
    
    convenience init(r: CGFloat, g:CGFloat, b:CGFloat, a:CGFloat) {
        self.init(
            red: r / 255.0,
            green: g / 255.0,
            blue: b / 255.0,
            alpha: a
        )
    }
    
    struct ProtonMail {
        
        static let Blue_475F77 = UIColor(RRGGBB: UInt(0x475F77))
        static let Blue_85B1DE = UIColor(RRGGBB: UInt(0x85B1DE))
        static let Blue_5C7A99 = UIColor(RRGGBB: UInt(0x5C7A99))
        static let Blue_6789AB = UIColor(RRGGBB: UInt(0x6789AB))
        static let Blue_9397CD = UIColor(RRGGBB: UInt(0x9397CD))
        static let Gray_383A3B = UIColor(RRGGBB: UInt(0x383A3B))
        static let Gray_FCFEFF = UIColor(RRGGBB: UInt(0xFCFEFF))
        static let Gray_C9CED4 = UIColor(RRGGBB: UInt(0xC9CED4))
        static let Gray_E8EBED = UIColor(RRGGBB: UInt(0xE8EBED))
        static let Gray_E2E6E8 = UIColor(RRGGBB: UInt(0xE2E6E8))
        static let Gray_999DA1 = UIColor(RRGGBB: UInt(0x999DA1))
        static let Gray_8E8E8E = UIColor(RRGGBB: UInt(0x8E8E8E))
        static let Red_D74B4B = UIColor(RRGGBB: UInt(0xD74B4B))
        static let Red_FF5959 = UIColor(RRGGBB: UInt(0xFF5959))
        
        
        static let Menu_UnreadCountBackground = UIColor(RRGGBB: UInt(0x8182C3))
        static let Menu_UnSelectBackground = UIColor(RRGGBB: UInt(0x505061))
        static let Menu_UnSelectBackground_Label = UIColor(RRGGBB:UInt(0x3F3E4E))
        static let Menu_SelectedBackground = UIColor(RRGGBB: UInt(0x2F2E3C))
        
        static let ServicePlanFree = UIColor(red: 0/255, green: 172/255, blue: 63/255, alpha: 1.0)
        static let ServicePlanPro = UIColor(red: 153/255, green: 30/255, blue: 245/255, alpha: 1.0)
        static let ServicePlanPlus = UIColor(red: 199/255, green: 89/255, blue: 31/255, alpha: 1.0)
        static let ServicePlanVisionary = UIColor(red: 56/255, green: 114/255, blue: 218/255, alpha: 1.0)
        
        static let TableFootnoteTextGray = UIColor(red: 110/255, green: 110/255, blue: 112/255, alpha: 1.0)
        static let TableSeparatorGray = UIColor(red: 226/255, green: 230/255, blue: 232/255, alpha: 1.0)
        static let ButtonBackground: UIColor = {
            return Menu_UnreadCountBackground
        }()
        
        static let Nav_Bar_Background = UIColor(RRGGBB: UInt(0x505061))
        
        static let Login_Background_Gradient_Left = UIColor(red: 147/255, green: 151/255, blue: 205/255, alpha: 0.9)
        static let Login_Background_Gradient_Right = UIColor(red: 23/255, green: 41/255, blue: 131/255, alpha: 0.9)
        static let Login_Button_Border_Color = UIColor(RRGGBB: UInt(0x9397CD))
        
        static let MessageCell_UnRead_Color = UIColor(RRGGBB: UInt(0xFFFFFF))
        static let MessageCell_Read_Color = UIColor(RRGGBB: UInt(0xF2F3F7))
        
        static let TextFieldTintColor = UIColor.white
        static let MessageActionTintColor = UIColor(hexString: "#9397cd", alpha: 1.0)
    }
}


extension UIColor {

    convenience init(hexColorCode: String) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        
        if hexColorCode.hasPrefix("#") {
            let index   = hexColorCode.index(hexColorCode.startIndex, offsetBy: 1)
            let hex     = String(hexColorCode[index...])
            let scanner = Scanner(string: hex)
            var hexValue: CUnsignedLongLong = 0
            
            if scanner.scanHexInt64(&hexValue) {
                if hex.count == 6 {
                    red   = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8)  / 255.0
                    blue  = CGFloat(hexValue & 0x0000FF) / 255.0
                } else if hex.count == 8 {
                    red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                    blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                    alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
                } else {
                    PMLog.D("invalid hex code string, length should be 7 or 9")
                }
            } else {
                PMLog.D("scan hex error")
            }
        } else {
            PMLog.D("invalid hex code string, missing '#' as prefix")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
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
        
        var redInt:   CUnsignedInt = 0
        var greenInt: CUnsignedInt = 0
        var blueInt:  CUnsignedInt = 0
        
        Scanner(string: redHex).scanHexInt32(&redInt)
        Scanner(string: greenHex).scanHexInt32(&greenInt)
        Scanner(string: blueHex).scanHexInt32(&blueInt)
        
        self.init(red: CGFloat(redInt) / 255.0, green: CGFloat(greenInt) / 255.0, blue: CGFloat(blueInt) / 255.0, alpha: CGFloat(alpha))
    }
    
    /**
     Create non-autoreleased color with in the given hex value and alpha
     
     :param:   hex
     :param:   alpha
     :returns: color with the given hex value and alpha
     
     Example:
     let secondColor: UIColor = UIColor(hex: 0xff8942, alpha: 0.5)
     
     */
    convenience init(hex: Int, alpha: Float) {
        let hexString = NSString(format: "%2X", hex)
        self.init(hexString: hexString as String, alpha: alpha)
    }
}
