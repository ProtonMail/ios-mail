//
//  UIView+Extension.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

extension UIView {
    func roundCorners() {
        layer.cornerRadius = 4.0
        clipsToBounds = true
    }

    func setCornerRadius(radius: CGFloat) {
        layer.cornerRadius = radius
        clipsToBounds = true
    }

    func shake(_ times: Float, offset: CGFloat) {
        UIView.animate(withDuration: 1.0, animations: {
            let shakeAnimation = CABasicAnimation(keyPath: "position")
            shakeAnimation.duration = 0.075
            shakeAnimation.repeatCount = times
            shakeAnimation.autoreverses = true
            shakeAnimation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - offset, y: self.center.y))
            shakeAnimation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + offset, y: self.center.y))
            self.layer.add(shakeAnimation, forKey: "position")
        })
    }

    func gradient() {
        if let sls = self.layer.sublayers {
            for s in sls {
                if let slay = s as? CAGradientLayer {
                    slay.frame = self.bounds
                    return
                }
            }
        }

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds

        let topColor = UIColor(hexColorCode: "#fbfbfb").cgColor
        let top2Color = UIColor(hexColorCode: "#cfcfcf").cgColor
        let midPoint = UIColor(hexColorCode: "#aaa9aa").cgColor
        let bottomColor = UIColor(hexColorCode: "#c7c7c7").cgColor

        gradientLayer.locations = [0.0, 0.3, 0.5, 0.8, 1]

        gradientLayer.colors = [topColor, top2Color, midPoint, midPoint, bottomColor]

        self.layer.addSublayer(gradientLayer)
    }
}
