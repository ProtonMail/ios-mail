//
//  File.swift
//  
//
//  Created by Maciej Gomółka on 12.09.2024.
//

import Foundation
import SwiftUI

public extension DS.Shadows {

    static let softFull = Shadow.make(x: .zero, y: .zero, color: .shadowWeak)
    static let softTop = Shadow.make(x: .zero, y: -4, color: .shadowWeak)
    static let softBottom = Shadow.make(x: .zero, y: 4, color: .shadowWeak)
    static let softLeft = Shadow.make(x: -4, y: .zero, color: .shadowWeak)
    static let softRight = Shadow.make(x: 4, y: .zero, color: .shadowWeak)

    static let raisedFull = Shadow.make(x: .zero, y: .zero, color: .shadowMedium)
    static let raisedTop = Shadow.make(x: .zero, y: -2, color: .shadowMedium)
    static let raisedBottom = Shadow.make(x: .zero, y: 2, color: .shadowMedium)
    static let raisedLeft = Shadow.make(x: -2, y: .zero, color: .shadowMedium)
    static let raisedRight = Shadow.make(x: 2, y: .zero, color: .shadowMedium)

    static let liftedFull = Shadow.make(x: .zero, y: .zero, color: .shadowStrong)
    static let liftedTop = Shadow.make(x: .zero, y: -4, color: .shadowStrong)
    static let liftedBottom = Shadow.make(x: .zero, y: 4, color: .shadowStrong)
    static let liftedLeft = Shadow.make(x: -4, y: .zero, color: .shadowStrong)
    static let liftedRight = Shadow.make(x: 4, y: .zero, color: .shadowStrong)

}

public struct Shadow {
    public let x: CGFloat
    public let y: CGFloat
    public let blur: CGFloat
    public let color: Color

    public init(x: CGFloat, y: CGFloat, blur: CGFloat, color: Color) {
        self.x = x
        self.y = y
        self.blur = blur
        self.color = color
    }
}

private extension Shadow {

    static func make(x: CGFloat, y: CGFloat, color: Color) -> Shadow {
        .init(x: x, y: y, blur: 15, color: color)
    }

}

private extension Color {
    static let shadowWeak = Color(.shadowWeak)
    static let shadowMedium = Color(.shadowMedium)
    static let shadowStrong = Color(.shadowStrong)
}
