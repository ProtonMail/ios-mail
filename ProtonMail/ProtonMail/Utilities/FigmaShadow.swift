//
//  FigmaShadow.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
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

extension TempFigmaShadow {

    static var `default`: TempFigmaShadow {
        .init(color: ColorProvider.Shade100.withAlphaComponent(0.1), x: 0, y: 4, blur: 8, spread: 0)
    }

    static func custom(y: CGFloat, blur: CGFloat) -> TempFigmaShadow {
        .init(color: ColorProvider.Shade100.withAlphaComponent(0.1), x: 0, y: y, blur: blur, spread: 0)
    }

}
