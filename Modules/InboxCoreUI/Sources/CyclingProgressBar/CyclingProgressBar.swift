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

import InboxDesignSystem
import SwiftUI

/// A view that displays a progress bar with a cycling, animated gradient.
/// The animation continuously moves from left to right, creating an infinite loading effect.
public struct CyclingProgressBar: View {
    @State private var animationPhase: CGFloat = 0

    private let animationDurationInSeconds: TimeInterval = 1.2
    private let barHeight: CGFloat = 2

    // FIXME: Extract colors: primary (Avatar/Green/3) edge (no-name)
    private let primaryColor = Color(hex: "#52CD96")
    private let edgeColor = Color(hex: "#99D1C5").opacity(0)

    // MARK: - Body

    public var body: some View {
        GeometryReader { geometry in
            let gradient = LinearGradient(
                gradient: Gradient(colors: [edgeColor, primaryColor, edgeColor]),
                startPoint: .leading,
                endPoint: .trailing
            )

            let totalWidth = geometry.size.width
            let barWidth = totalWidth * 0.58
            let xOffset = animationPhase * (totalWidth + barWidth) - barWidth

            Rectangle()
                .fill(gradient)
                .frame(width: barWidth)
                .offset(x: xOffset)
        }
        .frame(height: barHeight)
        .background(DS.Color.Shade.shade10.opacity(0.91))
        .clipped()
        .onAppear {
            withAnimation(.linear(duration: animationDurationInSeconds).repeatForever(autoreverses: false)) {
                animationPhase = 1.0
            }
        }
    }
}

struct CyclingProgressBar_Preview: View {
    @State private var visible: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Cycling progress bar (\(visible ? "visible" : "hidden"))")
                .font(.headline)
                .padding(.top, 60)
            if visible {
                CyclingProgressBar()
            }

            Spacer()
            Button(role: .none) {
                visible.toggle()
            } label: {
                Text(visible ? "Hide" : "Show")
                    .font(.headline)
                    .padding(20)
                    .frame(width: 150)
            }
            .background(Color.gray.opacity(0.2))
            .roundedRectangleStyle()
        }
        .padding([.horizontal], 0)
    }
}

#Preview {
    CyclingProgressBar_Preview()
}
