//
//  BioAuthenticating.swift
//  ProtonMail - Created on 07/10/2019.
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
