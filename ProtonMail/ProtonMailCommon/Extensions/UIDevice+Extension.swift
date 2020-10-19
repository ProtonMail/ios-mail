//
//  UIDevice.swift
//  ProtonMail - Created on 24/07/2019.
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
    

import UIKit
import PMKeymaker

extension UIDevice {
    enum StateRestorationPolicy {
        case deeplink, multiwindow
    }
    
    var stateRestorationPolicy: StateRestorationPolicy {
        let iOS13: Bool = { if #available(iOS 13.0, *) { return true } else { return false } }()
        let hasSignificantProtection: Bool = keymaker.isProtectorActive(BioProtection.self) || keymaker.isProtectorActive(PinProtection.self)
        
        /*
         Deeplink restoratin downside: it can not restore UI statle, scrolling offset in tableViews for example.
         NSCoders restoration downside: it does not work when mainKey is protected, it encodes only one UIWindow on multiwindow scene.
         Multiwindow: relies on NSUserActivity of UIWindowScene sessions, which is broken up to iOS 13.3 beta 2 at least. We do not have any choice in multiwindow environment of iPadOS, but for iPhone we'll use old Deeplink method instead.
         
         Such way, we are balancing between these two methods based on iOS version, mainKey availability and iPhone/iPad idiom.
         
         iOS 9-12   / no protection     / iPhone    - deeplink
         iOS 9-12   / no protection     / iPad      - deeplink
         iOS 9-12   / protection        / iPhone    - deeplink
         iOS 9-12   / protection        / iPad      - deeplink
         iOS 13     / no protection     / iPhone    - deeplink
         iOS 13     / no protection     / iPad      - multiwindow
         iOS 13     / protection        / iPhone    - deeplink
         iOS 13     / protection        / iPad      - multiwindow
         
         */
        
        switch (iOS13, hasSignificantProtection, self.userInterfaceIdiom) {
        case (_, _, .phone):    return .deeplink
        case (true, _, .pad):   return .multiwindow
        case (false, _, .pad): return .deeplink
        default:
            assert(false, "All possible combinations should be covered by cases above")
            return .deeplink
        }
    }
}
