//
//  NSNotificationCenter+KeyboardExtension.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import UIKit

@objc protocol NSNotificationCenterKeyboardObserverProtocol: NSObjectProtocol {
    @objc optional func keyboardWillHideNotification(_ notification: Notification)
    @objc optional func keyboardWillShowNotification(_ notificaiton: Notification)
}

extension NotificationCenter {
    func addKeyboardObserver(_ observer: NSNotificationCenterKeyboardObserverProtocol) {
        addObserver(observer, ifRespondsToAction: .willHide)
        addObserver(observer, ifRespondsToAction: .willShow)
    }
    
    func removeKeyboardObserver(_ observer: NSNotificationCenterKeyboardObserverProtocol) {
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
                return NSNotification.Name.UIKeyboardWillHide.rawValue
            default:
                return NSNotification.Name.UIKeyboardWillShow.rawValue
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
