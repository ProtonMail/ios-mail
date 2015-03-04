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
    
    public enum UIBorderSide {
        case Top, Bottom, Left, Right
    }
    
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
    
    public func addBorder(side: UIBorderSide, color: UIColor, borderWidth: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.CGColor
        
        switch side {
        case .Top:
            border.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: borderWidth)
        case .Bottom:
            border.frame = CGRect(x: 0, y: self.frame.size.height - borderWidth, width: self.frame.size.width, height: borderWidth)
        case .Left:
            border.frame = CGRect(x: 0, y: 0, width: borderWidth, height: self.frame.size.height)
        case .Right:
            border.frame = CGRect(x: self.frame.size.width - borderWidth, y: 0, width: borderWidth, height: self.frame.size.height)
        }
        
        self.layer.addSublayer(border)
    }
}