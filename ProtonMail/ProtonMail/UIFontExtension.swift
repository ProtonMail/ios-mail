//
//  UIFontExtension.swift
//  ProtonMail
//
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

extension UIFont {
    public class func robotoThin(size: CGFloat) -> UIFont {
        return UIFont(name: "Roboto-Thin", size: size)!
    }
    
    public class func robotoRegular(size: CGFloat) -> UIFont {
        return UIFont(name: "Roboto-Regular", size: size)!
    }
    
    public class func robotoLight(size: CGFloat) -> UIFont {
        return UIFont(name: "Roboto-Light", size: size)!
    }
    
    public class func robotoMedium(size: CGFloat) -> UIFont {
        return UIFont(name: "Roboto-Medium", size: size)!
    }
    
    public class func robotoMediumItalic(size: CGFloat) -> UIFont {
        return UIFont(name: "Roboto-MediumItalic", size: size)!
    }
    
    public class func robotoLightItalic(size: CGFloat) -> UIFont {
        return UIFont(name: "Roboto-LightItalic", size: size)!
    }
    
    public struct Size {
        public static var h1:CGFloat = 24.0
        
        /// size 18
        public static var h2:CGFloat = 18.0
        public static var h3:CGFloat = 17.0
        /// size 16
        public static var h4:CGFloat = 16.0
        public static var h5:CGFloat = 14.0
        /// size 12
        public static var h6:CGFloat = 12.0
        public static var h7:CGFloat = 9.0
    }
}
