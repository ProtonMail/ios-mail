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
struct CyclingProgressBar: View {
    private struct ViewState {
        let barHeight: CGFloat = 2
        let primaryColor = DS.Color.Loader.success
        let edgeColor = DS.Color.Loader.success.opacity(0)
        let backgroundColor = DS.Color.Shade.shade10.opacity(0.91)
    }

    @State private var animationPhase: CGFloat
    private let isAnimationEnabled: Bool

    private let configuration: LoadingBarConfiguration
    private let viewState = ViewState()

    init(configuration: LoadingBarConfiguration) {
        self.configuration = configuration
        _animationPhase = State(initialValue: 0)
        isAnimationEnabled = true
    }

    init(animationPhase: CGFloat) {
        self.configuration = .init()
        _animationPhase = State(initialValue: animationPhase)
        isAnimationEnabled = false
    }

    // MARK: - View

    var body: some View {
        GeometryReader { geometry in
            let gradient = LinearGradient(
                gradient: Gradient(colors: [viewState.edgeColor, viewState.primaryColor, viewState.edgeColor]),
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
        .frame(height: viewState.barHeight)
        .background(viewState.backgroundColor)
        .clipped()
        .onAppear {
            if isAnimationEnabled {
                withAnimation(.linear(duration: configuration.cycleDuration).repeatForever(autoreverses: false)) {
                    animationPhase = 1.0
                }
            }
        }
    }
}

private struct CyclingProgressBar_Preview: View {
    @State private var visible: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Cycling progress bar (\(visible ? "visible" : "hidden"))")
                .font(.headline)
                .padding(.top, 60)
            if visible {
                CyclingProgressBar(configuration: .init())
            }

            Spacer()
            Button {
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
