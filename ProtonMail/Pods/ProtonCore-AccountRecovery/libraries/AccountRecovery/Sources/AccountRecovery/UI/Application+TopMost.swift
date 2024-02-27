//
//  Created on 28/7/23.
//
//  Copyright (c) 2023 Proton AG
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if os(iOS)
extension UIWindow {
    var topMostViewController: UIViewController? {
        var topController = self.rootViewController
        while let presentedViewController = topController?.presentedViewController
            ?? (topController as? UINavigationController)?.topViewController {
            if presentedViewController is UIAlertController {
                break
            }
            topController = presentedViewController
        }
        return topController
    }
}
#endif
