//
//  NSNotificationCenter+KeyboardExtension.swift
//  ProtonMail
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
            switch(self) {
            case .willHide:
                return UIResponder.keyboardWillHideNotification.rawValue
            default:
                return UIResponder.keyboardWillShowNotification.rawValue
            }
        }
        
        var selector: Selector {
            switch(self) {
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
