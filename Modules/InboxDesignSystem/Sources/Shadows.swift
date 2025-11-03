// Copyright (c) 2025 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

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

    public var innerShadowStyle: ShadowStyle {
        .inner(color: color, radius: blur, x: x, y: y)
    }
}

private extension Shadow {

    static func make(x: CGFloat, y: CGFloat, color: Color) -> Shadow {
        .init(x: x, y: y, blur: blur, color: color)
    }

    /// Figma blur is 10, but in the app a blur of 5 produces a visually equivalent effect.
    private static let blur: CGFloat = 5

}

private extension Color {
    static let shadowWeak = Color(.shadowWeak)
    static let shadowMedium = Color(.shadowMedium)
    static let shadowStrong = Color(.shadowStrong)
}
