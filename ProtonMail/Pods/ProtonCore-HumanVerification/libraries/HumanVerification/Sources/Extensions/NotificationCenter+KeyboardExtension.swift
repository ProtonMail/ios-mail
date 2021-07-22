//
//  NSNotificationCenter+KeyboardExtension.swift
//  ProtonCore-HumanVerification - Created on 03.06.2021
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

#if canImport(UIKit)
import UIKit

@objc public protocol NSNotificationCenterKeyboardObserverProtocol: NSObjectProtocol {
    @objc optional func keyboardWillHideNotification(_ notification: Notification)
    @objc optional func keyboardWillShowNotification(_ notificaiton: Notification)
}

extension NotificationCenter {
    public func addKeyboardObserver(_ observer: NSNotificationCenterKeyboardObserverProtocol) {
        addObserver(observer, ifRespondsToAction: .willHide)
        addObserver(observer, ifRespondsToAction: .willShow)
    }

    public func removeKeyboardObserver(_ observer: NSNotificationCenterKeyboardObserverProtocol) {
        removeObserver(observer, ifRespondsToAction: .willHide)
        removeObserver(observer, ifRespondsToAction: .willShow)
    }

    // MARK: - Private methods

    fileprivate enum KeyboardAction {
        case willHide
        case willShow

        var notificationName: String {
            switch self {
            case .willHide:
                return UIResponder.keyboardWillHideNotification.rawValue
            default:
                return UIResponder.keyboardWillShowNotification.rawValue
            }
        }

        var selector: Selector {
            switch self {
            case .willHide:
                return #selector(NSNotificationCenterKeyboardObserverProtocol.keyboardWillHideNotification(_:))
            default:
                return #selector(NSNotificationCenterKeyboardObserverProtocol.keyboardWillShowNotification(_:))
            }
        }

        func isObserverResponds(_ observer: NSNotificationCenterKeyboardObserverProtocol) -> Bool {
            return observer.responds(to: selector)
        }
    }

    fileprivate func addObserver(_ observer: NSNotificationCenterKeyboardObserverProtocol, ifRespondsToAction action: KeyboardAction) {
        if keyboardObserver(observer, respondsToAction: action) {
            addObserver(observer, selector: action.selector, name: NSNotification.Name(rawValue: action.notificationName), object: nil)
        }
    }

    fileprivate func keyboardObserver(_ observer: NSNotificationCenterKeyboardObserverProtocol, respondsToAction action: KeyboardAction) -> Bool {
        return observer.responds(to: action.selector)
    }

    fileprivate func removeObserver(_ observer: NSNotificationCenterKeyboardObserverProtocol, ifRespondsToAction action: KeyboardAction) {
        if keyboardObserver(observer, respondsToAction: action) {
            removeObserver(observer, name: NSNotification.Name(rawValue: action.notificationName), object: nil)
        }
    }
}
#endif
