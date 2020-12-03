//
//  String+Alert+Extension.swift
//  ProtonMail - Created on 7/13/17.
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


extension String {
    
    public func alertViewController(_ title: String?, _ action: UIAlertAction?) {
        #if !APP_EXTENSION
        DispatchQueue.main.async {
            guard let window: UIWindow = UIApplication.shared.keyWindow else {
                return
            }
            
            let alert = UIAlertController(title: title ?? LocalString._general_alert_title,
                                          message: self,
                                          preferredStyle: .alert)
            alert.addCloseAction()
            if let action = action {
                alert.addAction(action)
            }
            window.topmostViewController()?.present(alert, animated: true, completion: nil)
        }
        #endif
    }
    
    public func alertController() -> UIAlertController {
        let message = self
        return UIAlertController(title: LocalString._general_alert_title,
                                 message: message,
                                 preferredStyle: .alert)
    }
    
    public func alertController(_ localizedTitle : String) -> UIAlertController {
        let message = self
        return UIAlertController(title: localizedTitle,
                                 message: message,
                                 preferredStyle: .alert)
    }
}
