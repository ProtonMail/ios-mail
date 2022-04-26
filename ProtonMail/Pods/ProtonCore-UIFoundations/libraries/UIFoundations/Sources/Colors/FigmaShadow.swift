//
//  FigmaShadow.swift
//  ProtonCore-UIFoundations - Created on 04.11.20.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

public struct FigmaShadow {
    let lightRGB: Int
    let lightAlpha: CGFloat
    let darkRGB: Int
    let darkAlpha: CGFloat
    
    let x: CGFloat
    let y: CGFloat
    let blur: CGFloat
    let spread: CGFloat

    public init(lightRGB: Int, lightAlpha: CGFloat, darkRGB: Int, darkAlpha: CGFloat,
                x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat) {
        self.lightRGB = lightRGB
        self.lightAlpha = lightAlpha
        self.darkRGB = darkRGB
        self.darkAlpha = darkAlpha
        self.x = x
        self.y = y
        self.blur = blur
        self.spread = spread
    }
}

#if canImport(UIKit)
import UIKit
public extension UIView {
    func apply(shadows: [FigmaShadow]) {
        clearShadow()
        self.clipsToBounds = false
        for shadow in shadows {
            let layer = CALayer()
            layer.frame = self.layer.bounds
            let color = UIColor.dynamic(lightRGB: shadow.lightRGB, lightAlpha: shadow.lightAlpha,
                                        darkRGB: shadow.darkRGB, darkAlpha: shadow.darkAlpha)
            layer.shadowColor = color.cgColor
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

#endif

extension FigmaShadow {
    
    internal static var shadowBase: FigmaShadow {
        .init(lightRGB: 0x000000, lightAlpha: 0.05, darkRGB: 0x000000, darkAlpha: 0.80, x: 0, y: 0, blur: 1, spread: 0)
    }
    
    internal static var shadowNorm: FigmaShadow {
        .init(lightRGB: 0x000000, lightAlpha: 0.10, darkRGB: 0x000000, darkAlpha: 0.80, x: 0, y: 1, blur: 2, spread: 0)
    }
    
    internal static var shadowRaised: FigmaShadow {
        .init(lightRGB: 0x000000, lightAlpha: 0.10, darkRGB: 0x000000, darkAlpha: 0.80, x: 0, y: 8, blur: 4, spread: 0)
    }
    
    internal static var shadowLifted: FigmaShadow {
        .init(lightRGB: 0x000000, lightAlpha: 0.10, darkRGB: 0x000000, darkAlpha: 0.86, x: 0, y: 8, blur: 24, spread: 0)
    }
    
}

public extension Collection where Element == FigmaShadow {
    static var shadowNorm: [Element] { [.shadowNorm, .shadowBase] }
    static var shadowRaised: [Element] { [.shadowRaised, .shadowNorm] }
    static var shadowLifted: [Element] { [.shadowLifted, .shadowNorm] }
}
