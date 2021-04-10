//
//  UIView+helper.swift
//  ProtonMail - Created on 03.08.20.
//
//  Copyright (c) 2020 Proton Technologies AG
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
//

import UIKit
extension UIView {
    var safeGuide: UIEdgeInsets {
        guard #available(iOS 11.0, *) else {
            // Device has physical home button
            return UIEdgeInsets.zero
        }
        return self.safeAreaInsets
    }

    func roundCorner(_ radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }

    func getKeyboardHeight() -> CGFloat {

        var application: UIApplication

        #if APP_EXTENSION
        let obj = UIApplication.perform(Selector("sharedApplication"))
        guard application = obj?.takeRetainedValue() as? UIApplication else {
            return 0
        }
        #else
        application = UIApplication.shared
        #endif

        let keyboardWindow = application.windows.first(where: {
            let desc = $0.description.lowercased()
            return desc.contains("keyboard")
        })
        guard let rootVC = keyboardWindow?.rootViewController else {
            return 0
        }
        for sub in rootVC.view.subviews {
            guard sub.description.contains("UIInputSetHostView") else {
                continue
            }
            return sub.frame.size.height
        }
        return 0
    }
}
