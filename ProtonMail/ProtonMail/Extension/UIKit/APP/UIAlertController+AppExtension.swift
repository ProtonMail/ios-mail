// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import UIKit

extension UIAlertController {
    func addURLAction(title: String, url: URL) {
        addAction(.urlAction(title: title, url: url))
    }

    static func showOnTopmostVC(title: String, message: String, action: UIAlertAction) {
        #if !APP_EXTENSION
        DispatchQueue.main.async {
            guard let window: UIWindow = UIApplication.shared.keyWindow else {
                return
            }
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addCloseAction()
            alert.addAction(action)
            window.topmostViewController()?.present(alert, animated: true, completion: nil)
        }
        #endif
    }
}
