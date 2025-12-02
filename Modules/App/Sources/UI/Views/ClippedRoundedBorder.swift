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

extension View {
    func clippedRoundedBorder(cornerRadius: CGFloat, lineColor: Color, lineWidth: CGFloat = 1) -> some View {
        modifier(ClippedRoundedBorder(cornerRadius: cornerRadius, lineColor: lineColor, lineWidth: lineWidth))
    }
}

struct ClippedRoundedBorder: ViewModifier {
    private let cornerRadius: CGFloat
    private let lineColor: Color
    private let lineWidth: CGFloat

    init(cornerRadius: CGFloat, lineColor: Color, lineWidth: CGFloat) {
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.lineColor = lineColor
    }

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(lineColor, lineWidth: lineWidth))
    }
}
