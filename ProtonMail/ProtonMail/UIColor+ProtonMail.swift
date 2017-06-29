//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

import Foundation
import UIKit

extension UIColor {
    
    public convenience init(RRGGBB: UInt, alpha: CGFloat) {
        self.init(
            red: CGFloat((RRGGBB & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((RRGGBB & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(RRGGBB & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
    
    public convenience init(RRGGBB: UInt) {
        self.init(
            red: CGFloat((RRGGBB & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((RRGGBB & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(RRGGBB & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
    
    public convenience init(r: CGFloat, g:CGFloat, b:CGFloat, a:CGFloat) {
        self.init(
            red: r / 255.0,
            green: g / 255.0,
            blue: b / 255.0,
            alpha: a
        )
    }
    
    public struct ProtonMail {

        public static let Blue_475F77 = UIColor(RRGGBB: UInt(0x475F77))
        public static let Blue_85B1DE = UIColor(RRGGBB: UInt(0x85B1DE))
        public static let Blue_5C7A99 = UIColor(RRGGBB: UInt(0x5C7A99))
        public static let Blue_6789AB = UIColor(RRGGBB: UInt(0x6789AB))
        public static let Gray_383A3B = UIColor(RRGGBB: UInt(0x383A3B))
        public static let Gray_FCFEFF = UIColor(RRGGBB: UInt(0xFCFEFF))
        public static let Gray_C9CED4 = UIColor(RRGGBB: UInt(0xC9CED4))
        public static let Gray_E8EBED = UIColor(RRGGBB: UInt(0xE8EBED))
        public static let Gray_999DA1 = UIColor(RRGGBB: UInt(0x999DA1))
        public static let Red_D74B4B = UIColor(RRGGBB: UInt(0xD74B4B))
        public static let Red_FF5959 = UIColor(RRGGBB: UInt(0xFF5959))
        
        
        public static let Menu_UnreadCountBackground = UIColor(RRGGBB: UInt(0x8182C3))
        public static let Menu_UnSelectBackground = UIColor(RRGGBB: UInt(0x505061))
        public static let Menu_SelectedBackground = UIColor(RRGGBB: UInt(0x2F2E3C))
        
        public static let Nav_Bar_Background = UIColor(RRGGBB: UInt(0x505061))
    
        
        public  static let Login_Background_Gradient_Left = UIColor(red: 147/255, green: 151/255, blue: 205/255, alpha: 0.9)
        public static let Login_Background_Gradient_Right = UIColor(red: 23/255, green: 41/255, blue: 131/255, alpha: 0.9)
        public static let Login_Button_Border_Color = UIColor(RRGGBB: UInt(0x9397CD))
        
        
        public static let MessageCell_UnRead_Color = UIColor(RRGGBB: UInt(0xFFFFFF))
        public static let MessageCell_Read_Color = UIColor(RRGGBB: UInt(0xF2F3F7))
    
        
        public static let TextFieldTintColor = UIColor.white
        
        public static let MessageActionTintColor = UIColor(hexString: "#9397cd", alpha: 1.0)
    }
}


extension UIColor
{
    
    public convenience init(hexColorCode: String)
    {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        
        if hexColorCode.hasPrefix("#")
        {
            let index   = hexColorCode.characters.index(hexColorCode.startIndex, offsetBy: 1)
            let hex     = hexColorCode.substring(from: index)
            let scanner = Scanner(string: hex)
            var hexValue: CUnsignedLongLong = 0
            
            if scanner.scanHexInt64(&hexValue)
            {
                if hex.characters.count == 6
                {
                    red   = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8)  / 255.0
                    blue  = CGFloat(hexValue & 0x0000FF) / 255.0
                }
                else if hex.characters.count == 8
                {
                    red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                    blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                    alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
                }
                else
                {
                    PMLog.D("invalid hex code string, length should be 7 or 9")
                }
            }
            else
            {
                PMLog.D("scan hex error")
            }
        }
        else
        {
            PMLog.D("invalid hex code string, missing '#' as prefix")
        }
        
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
    
}




// Other Methods

extension UIColor
    
{
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
    public convenience init(hexString: String, alpha: Float)
    {
        var hex = hexString
        
        // Check for hash and remove the hash
        if hex.hasPrefix("#")
        {
            hex = hex.substring(from: hex.characters.index(hex.startIndex, offsetBy: 1))
        }

        if hex.characters.count == 0 {
            hex = "000000"
        }

        let hexLength = hex.characters.count
        // Check for string length
        assert(hexLength == 6 || hexLength == 3)
        
        // Deal with 3 character Hex strings
        if hexLength == 3
        {
            let redHex   = hex.substring(to: hex.characters.index(hex.startIndex, offsetBy: 1))
            let greenHex = hex.substring(with: hex.characters.index(hex.startIndex, offsetBy: 1) ..< hex.characters.index(hex.startIndex, offsetBy: 2))
            let blueHex  = hex.substring(from: hex.characters.index(hex.startIndex, offsetBy: 2))
            hex = redHex + redHex + greenHex + greenHex + blueHex + blueHex
        }
        
        let redHex = hex.substring(to: hex.characters.index(hex.startIndex, offsetBy: 2))
        let greenHex = hex.substring(with: hex.characters.index(hex.startIndex, offsetBy: 2) ..< hex.characters.index(hex.startIndex, offsetBy: 4))
        let blueHex = hex.substring(with: hex.characters.index(hex.startIndex, offsetBy: 4) ..< hex.characters.index(hex.startIndex, offsetBy: 6))
        
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
    public convenience init(hex: Int, alpha: Float)
    {
        let hexString = NSString(format: "%2X", hex)
        self.init(hexString: hexString as String, alpha: alpha)
    }
    
}
