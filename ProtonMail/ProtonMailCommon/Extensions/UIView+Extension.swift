//
//  UIView+Extension.swift
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

import UIKit

extension UIView {
    @discardableResult func loadFromNib<T: UIView>() -> T? {
        let name = String(describing: type(of: self))
        let nib = UINib(nibName: name, bundle: Bundle(for: type(of: self)))

        guard let subview = nib.instantiate(withOwner: self, options: nil).first as? T else {
            return nil
        }
        subview.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(subview)
        subview.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        subview.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        subview.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        subview.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true

        return subview
    }

    enum BorderSide: String {
        case top, bottom, left, right
    }

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

    func add(border side: BorderSide, color: UIColor, borderWidth: CGFloat, at level: CGFloat? = nil) {
        let border = CALayer()
        border.name = side.rawValue
        border.backgroundColor = color.cgColor
        switch side {
        case .top:
            let level = level ?? 0
            border.frame = CGRect(x: 0, y: level, width: self.frame.size.width, height: borderWidth)
        case .bottom:
            let level = level ?? self.frame.size.height
            border.frame = CGRect(x: 0, y: level - borderWidth, width: self.frame.size.width, height: borderWidth)
        case .left:
            let level = level ?? 0
            border.frame = CGRect(x: level, y: 0, width: borderWidth, height: self.frame.size.height)
        case .right:
            let level = level ?? self.frame.size.width
            border.frame = CGRect(x: level - borderWidth, y: 0, width: borderWidth, height: self.frame.size.height)
        }
        //// TODO:: change when switch to swift 4.2
        // self.layer.sublayers?.removeAll(where: { $0.name == border.name })

        // swift 4
        while let index = self.layer.sublayers?.firstIndex(where: { $0.name == border.name }) {
            self.layer.sublayers?.remove(at: index)
        }
        self.layer.addSublayer(border)
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
