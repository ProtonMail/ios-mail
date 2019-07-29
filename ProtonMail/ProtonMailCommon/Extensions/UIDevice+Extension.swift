//
//  UIDevice.swift
//  ProtonMail - Created on 24/07/2019.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import UIKit
import Keymaker

extension UIDevice {
    enum StateRestorationPolicy {
        case coders, deeplink
    }
    
    var stateRestorationPolicy: StateRestorationPolicy {
        let iOS13: Bool = { if #available(iOS 13.0, *) { return true } else { return false } }()
        let hasSignificantProtection: Bool = keymaker.isProtectorActive(BioProtection.self) || keymaker.isProtectorActive(PinProtection.self)
        
        /*
         TL;DR: restore via deeplink when have only one window with mainKey available
         
         Deeplink restoratin downside: it can not restore UI statle, scrolling offset in tableViews for example.
         NSCoders restoration downside: it does not work when mainKey is protected, it encodes only one UIWindow on multiwindow scene.
         
         Such way, we are balancing between these two methods based on iOS version, mainKey availability and iPhone/iPad idiom.
         
         iOS 9-12   / no protection     / iPhone    - coders
         iOS 9-12   / no protection     / iPad      - coders
         iOS 9-12   / protection        / iPhone    - deeplink
         iOS 9-12   / protection        / iPad      - deeplink
         iOS 13     / no protection     / iPhone    - coders
         iOS 13     / no protection     / iPad      - deeplink
         iOS 13     / protection        / iPhone    - deeplink
         iOS 13     / protection        / iPad      - deeplink
         
         */
        
        switch (iOS13, hasSignificantProtection, self.userInterfaceIdiom) {
        case (_, true, _):          return .deeplink
        case (true, _, .pad):       return .deeplink
        case (true, false, .phone): return .coders
        case (false, false, _):     return .coders
        default:                    return .deeplink
        }
    }
}
