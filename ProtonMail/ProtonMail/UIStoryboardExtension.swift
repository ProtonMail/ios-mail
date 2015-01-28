//
//  UIStoryboardExtension.swift
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

extension UIStoryboard {
    enum Storyboard: String {
        case inbox = "Menu"
        case signIn = "SignIn"
        
        var storyboard: UIStoryboard {
            return UIStoryboard(name: rawValue, bundle: nil)
        }
        
        func instantiateInitialViewController() -> UIViewController {
            return storyboard.instantiateInitialViewController() as UIViewController
        }
    }
    
    class func instantiateInitialViewController(#storyboard: Storyboard) -> UIViewController {
        return storyboard.instantiateInitialViewController()
    }
}