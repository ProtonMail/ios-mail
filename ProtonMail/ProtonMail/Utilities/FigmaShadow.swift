//
//  FigmaShadow.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

import ProtonCore_UIFoundations
import UIKit

struct TempFigmaShadow {
    let color: UIColor
    let x: CGFloat
    let y: CGFloat
    let blur: CGFloat
    let spread: CGFloat

    init(color: UIColor, x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat) {
        self.color = color
        self.x = x
        self.y = y
        self.blur = blur
        self.spread = spread
    }
}

extension CALayer {

    func apply(shadow: TempFigmaShadow) {
        shadowColor = shadow.color.cgColor
        shadowOpacity = 1
        shadowOffset = CGSize(width: shadow.x, height: shadow.y)
        shadowRadius = shadow.blur / 2.0
        shadowPath = shadow.path(bounds: bounds)
    }

    func clearShadow() {
        shadowColor = nil
        shadowOpacity = 0
        shadowOffset = .zero
        shadowRadius = 0
        shadowPath = nil
    }

}

private extension TempFigmaShadow {

    func path(bounds: CGRect) -> CGPath? {
        guard spread != 0 else { return nil }
        let dx = -spread
        let rect = bounds.insetBy(dx: dx, dy: dx)
        return UIBezierPath(rect: rect).cgPath
    }

}

extension UIView {
    func apply(shadows: [TempFigmaShadow]) {
        self.clipsToBounds = false
        for shadow in shadows {
            let layer = CALayer()
            layer.frame = self.layer.bounds
            layer.shadowColor = shadow.color.cgColor
            layer.shadowOpacity = 1
            layer.shadowOffset = CGSize(width: shadow.x, height: shadow.y)
            layer.shadowRadius = shadow.blur
            let shadowPath = UIBezierPath(roundedRect: layer.bounds, cornerRadius: 0)
            layer.shadowPath = shadowPath.cgPath
            self.layer.addSublayer(layer)
        }

    }

    func clearShadow() {
        layer.sublayers?
            .filter({ $0.shadowColor != nil })
            .forEach({ $0.removeFromSuperlayer() })
    }
}

extension Collection where Element == TempFigmaShadow {
    static var shadowNorm: [Element] {
        let shadow10 = UIColor(named: "shadowNorm10") ?? UIColor.black.withAlphaComponent(0.1)
        let shadow5 = UIColor(named: "shadowGeneral5") ?? UIColor.black.withAlphaComponent(0.05)
        return [
            TempFigmaShadow.init(color: shadow10, x: 0, y: 1, blur: 2, spread: 0),
            TempFigmaShadow.init(color: shadow5, x: 0, y: 0, blur: 1, spread: 0)
        ]
    }
}

extension TempFigmaShadow {

    static var `default`: TempFigmaShadow {
        .init(color: ColorProvider.Shade100.withAlphaComponent(0.1), x: 0, y: 4, blur: 8, spread: 0)
    }

    static func custom(y: CGFloat, blur: CGFloat) -> TempFigmaShadow {
        .init(color: ColorProvider.Shade100.withAlphaComponent(0.1), x: 0, y: y, blur: blur, spread: 0)
    }

}
