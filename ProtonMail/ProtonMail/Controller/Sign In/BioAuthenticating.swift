//
//  BioAuthenticating.swift
//  ProtonMail - Created on 07/10/2019.
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

protocol BioAuthenticating {
    func authenticateUser()
}
extension BioAuthenticating where Self: UIViewController {
    func subscribeToWillEnterForegroundMessage() {
        let name: Notification.Name = {
            if #available(iOS 13.0, *) {
                return UIWindowScene.willEnterForegroundNotification
            } else {
                return UIApplication.willEnterForegroundNotification
            }
        }()

        NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
            guard userCachedStatus.isTouchIDEnabled else { return }
            self?.decideOnBioAuthentication()
        }
    }
    
    func decideOnBioAuthentication() {
        #if APP_EXTENSION
        self.authenticateUser()
        #else
        if #available(iOS 13.0, *), UIDevice.current.biometricType == .touchID,
            (UIApplication.shared.applicationState != .active || self.view?.window?.windowScene?.activationState != .foregroundActive)
        {
            // mystery that makes TouchID prompt a little bit more stable on iOS 13.0 - 13.1.2
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                #if !APP_EXTENSION
                // TouchID prompt can appear unlock the app if this method was called from background, which can spoil logic of autolocker
                // in our app only unlocking from foreground makes sense
                guard UIApplication.shared.applicationState == .active else { return }
                #endif
                self.authenticateUser()
            }
        } else {
            self.authenticateUser()
        }
        #endif
    }
}
