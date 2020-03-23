//
//  UIStoryboard+Extension.swift
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

extension UIStoryboard {
    /// The raw value must match the restorationIdentifier for the initialViewController
    enum Storyboard: String {
        case attachments = "Attachments"
        case inbox = "Menu"
        case signIn = "SignIn"
        case composer = "Composer"
        case message = "Message"
        case alert = "Alerts"
        var restorationIdentifier: String {
            return rawValue
        }
        
        var storyboard: UIStoryboard {
            return UIStoryboard(name: rawValue, bundle: nil)
        }
        
        func instantiateInitialViewController() -> UIViewController? {
            return storyboard.instantiateInitialViewController()
        }
    }
    
    class func instantiateInitialViewController(storyboard: Storyboard) -> UIViewController? {
        return storyboard.instantiateInitialViewController()
    }
}

extension UIStoryboard {
    func make<T>(_ type: T.Type) -> T {
        return self.instantiateViewController(withIdentifier: .init(describing: T.self)) as! T
    }
}
