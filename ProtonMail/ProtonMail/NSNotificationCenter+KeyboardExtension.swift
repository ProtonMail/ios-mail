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

import Foundation

@objc protocol NSNotificationCenterKeyboardObserverProtocol: NSObjectProtocol {
    optional func keyboardWillHideNotification(notification: NSNotification)
    optional func keyboardWillShowNotification(notificaiton: NSNotification)
}

extension NSNotificationCenter {
    func addKeyboardObserver(observer: NSNotificationCenterKeyboardObserverProtocol) {
        addObserver(observer, ifRespondsToAction: .WillHide)
        addObserver(observer, ifRespondsToAction: .WillShow)
    }
    
    func removeKeyboardObserver(observer: NSNotificationCenterKeyboardObserverProtocol) {
        removeObserver(observer, ifRespondsToAction: .WillHide)
        removeObserver(observer, ifRespondsToAction: .WillShow)
    }
    
    // MARK: - Private methods
    
    private enum KeyboardAction {
        case WillHide
        case WillShow
        
        var notificationName: String {
            switch(self) {
            case .WillHide:
                return UIKeyboardWillHideNotification
            default:
                return UIKeyboardWillShowNotification
            }
        }
        
        var selector: Selector {
            switch(self) {
            case .WillHide:
                return "keyboardWillHideNotification:"
            default:
                return "keyboardWillShowNotification:"
            }
        }
        
        func isObserverResponds(observer: NSNotificationCenterKeyboardObserverProtocol) -> Bool {
            return observer.respondsToSelector(selector)
        }
    }
    
    private func addObserver(observer: NSNotificationCenterKeyboardObserverProtocol, ifRespondsToAction action: KeyboardAction) {
        if keyboardObserver(observer, respondsToAction: action) {
            addObserver(observer, selector: action.selector, name: action.notificationName, object: nil)
        }
    }
    
    private func keyboardObserver(observer: NSNotificationCenterKeyboardObserverProtocol, respondsToAction action: KeyboardAction) -> Bool {
        return observer.respondsToSelector(action.selector)
    }
    
    private func removeObserver(observer: NSNotificationCenterKeyboardObserverProtocol, ifRespondsToAction action: KeyboardAction) {
        if keyboardObserver(observer, respondsToAction: action) {
            removeObserver(observer, name: action.notificationName, object: nil)
        }
    }
}