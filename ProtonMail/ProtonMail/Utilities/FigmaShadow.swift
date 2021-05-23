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

import UIKit
import ProtonCore_UIFoundations

public struct FigmaShadow {
    let color: UIColor
    let x: CGFloat
    let y: CGFloat
    let blur: CGFloat
    let spread: CGFloat

    public init(color: UIColor, x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat) {
        self.color = color
        self.x = x
        self.y = y
        self.blur = blur
        self.spread = spread
    }
}

extension CALayer {

    public func apply(shadow: FigmaShadow) {
        shadowColor = shadow.color.cgColor
        shadowOpacity = 1
        shadowOffset = CGSize(width: shadow.x, height: shadow.y)
        shadowRadius = shadow.blur / 2.0
        shadowPath = shadow.path(bounds: bounds)
    }

    public func clearShadow() {
        shadowColor = nil
        shadowOpacity = 0
        shadowOffset = .zero
        shadowRadius = 0
        shadowPath = nil
    }

}

private extension FigmaShadow {

    func path(bounds: CGRect) -> CGPath? {
        guard spread != 0 else { return nil }
        let dx = -spread
        let rect = bounds.insetBy(dx: dx, dy: dx)
        return UIBezierPath(rect: rect).cgPath
    }

}

extension FigmaShadow {

    static var `default`: FigmaShadow {
        .init(color: UIColorManager.Shade100.withAlphaComponent(0.1), x: 0, y: 4, blur: 8, spread: 0)
    }

}
