//
//  NSNotification+KeyboardExtension.swift
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

public struct KeyboardInfo {
    public let beginFrame: CGRect
    public let endFrame: CGRect
    public let duration: TimeInterval
    public let animationOption: UIViewAnimationOptions = .beginFromCurrentState
    
    init(beginFrame: CGRect, endFrame: CGRect, duration: TimeInterval) {
        self.beginFrame = beginFrame
        self.endFrame = endFrame
        self.duration = duration
    }
}

extension Notification {
    public var keyboardInfo: KeyboardInfo {
        let beginFrame = (userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect.zero
        let endFrame = (userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect.zero
        let duration = (userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        
        return KeyboardInfo(beginFrame: beginFrame, endFrame: endFrame, duration: duration)
    }
}
