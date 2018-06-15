
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



enum Fonts : CGFloat {
    case h1 = 24.0
    /// size 18
    case h2 = 18.0
    case h3 = 17.0
    /// size 16
    case h4 = 16.0
    case h5 = 14.0
    /// size 12
    case h6 = 12.0
    case h7 = 9.0
    /// custom size
    case s20 = 20.0
    case s13 = 13.0
    
    var regular : UIFont {
        if #available(iOS 8.2, *) {
            return UIFont.systemFont(ofSize: self.rawValue, weight: .regular)
        } else {
            return UIFont(name: "HelveticaNeue", size: self.rawValue)!
        }
    }
    
    var light : UIFont {
        if #available(iOS 8.2, *) {
            return UIFont.systemFont(ofSize: self.rawValue, weight: .light)
        } else {
            return UIFont(name: "HelveticaNeue-Light", size: self.rawValue)!
        }
    }
    
    var medium : UIFont {
        if #available(iOS 8.2, *) {
            return UIFont.systemFont(ofSize: self.rawValue, weight: .medium)
        } else {
            return UIFont(name: "HelveticaNeue-Medium", size: self.rawValue)!
        }
    }
    
    var bold : UIFont {
        if #available(iOS 8.2, *) {
            return UIFont.systemFont(ofSize: self.rawValue, weight: .medium)
        } else {
            return UIFont(name: "HelveticaNeue-Bold", size: self.rawValue)!
        }
    }
}
