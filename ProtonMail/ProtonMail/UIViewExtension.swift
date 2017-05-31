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
        case top, bottom, left, right
    }
    
    func roundCorners() {
        layer.cornerRadius = 4.0
        clipsToBounds = true
    }
    
    func shake(_ times: Float, offset: CGFloat) {
        
        PMLog.D("\(self.center)");
        UIView.animate(withDuration: 1.0, animations: {
            let shakeAnimation = CABasicAnimation(keyPath: "position")
            shakeAnimation.duration = 0.075
            shakeAnimation.repeatCount = times
            shakeAnimation.autoreverses = true
            shakeAnimation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - offset, y: self.center.y))
            shakeAnimation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + offset, y: self.center.y))
            PMLog.D("\(self.center)");
            self.layer.add(shakeAnimation, forKey: "position")
        })
    }
    
    public func addBorder(_ side: UIBorderSide, color: UIColor, borderWidth: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        
        switch side {
        case .top:
            border.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: borderWidth)
        case .bottom:
            border.frame = CGRect(x: 0, y: self.frame.size.height - borderWidth, width: self.frame.size.width, height: borderWidth)
        case .left:
            border.frame = CGRect(x: 0, y: 0, width: borderWidth, height: self.frame.size.height)
        case .right:
            border.frame = CGRect(x: self.frame.size.width - borderWidth, y: 0, width: borderWidth, height: self.frame.size.height)
        }
        
        self.layer.addSublayer(border)
    }
}
