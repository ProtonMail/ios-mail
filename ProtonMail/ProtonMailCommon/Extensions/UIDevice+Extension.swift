//
//  UIDevice.swift
//  Proton Mail - Created on 24/07/2019.
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

import UIKit
import ProtonCore_Keymaker

extension UIDevice {
    enum StateRestorationPolicy {
        case deeplink, multiwindow
    }

    var stateRestorationPolicy: StateRestorationPolicy {
        let iOS13: Bool = { if #available(iOS 13.0, *) { return true } else { return false } }()
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

        switch (iOS13, self.userInterfaceIdiom) {
        case (_, .phone):    return .deeplink
        case (true, .pad):   return .multiwindow
        case (false, .pad): return .deeplink
        default:
            assert(false, "All possible combinations should be covered by cases above")
            return .deeplink
        }
    }
}
