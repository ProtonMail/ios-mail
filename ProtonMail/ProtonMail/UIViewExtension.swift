//
//  UIViewExtension.swift
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

extension UIView {
    
    func roundCorners() {
        layer.cornerRadius = 4.0
        clipsToBounds = true
    }
    
    func shake(times: Float, offset: CGFloat) {
        UIView.animateWithDuration(1.0, animations: {
            var shakeAnimation = CABasicAnimation(keyPath: "position")
            shakeAnimation.duration = 0.075
            shakeAnimation.repeatCount = times
            shakeAnimation.autoreverses = true
            shakeAnimation.fromValue = NSValue(CGPoint: CGPointMake(self.center.x - offset, self.center.y))
            shakeAnimation.toValue = NSValue(CGPoint: CGPointMake(self.center.x + offset, self.center.y))
            
            self.layer.addAnimation(shakeAnimation, forKey: "position")
        })
    }
}