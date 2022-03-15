//
//  UIAlertController+Extension.swift
//  ProtonMail
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

extension UIAlertController {
    func addCloseAction() {
        addAction(UIAlertAction.closeAction())
    }

    func addOKAction() {
        addAction(UIAlertAction.okAction())
    }

    func addOKAction(handler: ((UIAlertAction?) -> Void)? = nil) {
        addAction(UIAlertAction.okAction(handler))
    }

    func addCancelAction(handler: ((UIAlertAction?) -> Void)? = nil) {
        addAction(UIAlertAction.cancelAction(handler))
    }

    func showOnTopVC() {
        var application: UIApplication?

        #if APP_EXTENSION
        let obj = UIApplication.perform(Selector(("sharedApplication")))
        application = obj?.takeRetainedValue() as? UIApplication
        #else
        application = UIApplication.shared
        #endif

        guard var vc = application?.keyWindow?.rootViewController else {
            return
        }
        while let presentedViewController = vc.presentedViewController {
            vc = presentedViewController
        }
        vc.present(self, animated: true, completion: nil)
    }
}
