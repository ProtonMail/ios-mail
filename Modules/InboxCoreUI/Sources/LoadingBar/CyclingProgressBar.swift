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
    }

    private let configuration: LoadingBarConfiguration
    private let onCycleCompleted: (() -> Void)
    /// Only for snapshot testing purposes to disable animation and allow manual control of animation phase
    private let isAnimationEnabled: Bool
    private let viewState = ViewState()

    @State private var animationPhase: CGFloat
    @State private var isAnimating: Bool = false

    init(configuration: LoadingBarConfiguration, onCycleCompleted: @escaping (() -> Void)) {
        self.configuration = configuration
        self.onCycleCompleted = onCycleCompleted
        self.isAnimationEnabled = true
        _animationPhase = State(initialValue: 0)
    }

    /// Only for snapshot testing purposes to disable animation and control the animation phase
    init(animationPhase: CGFloat) {
        self.configuration = .init()
        self.onCycleCompleted = {}
        self.isAnimationEnabled = false
        _animationPhase = State(initialValue: animationPhase)
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
        .onAppear { startAnimatingIfNeeded() }
        .onDisappear { stopAnimating() }
    }

    // MARK: - Private

    private func startAnimatingIfNeeded() {
        guard isAnimationEnabled, !isAnimating else { return }

        isAnimating = true

        startAnimationCycle()
    }

    private func stopAnimating() {
        isAnimating = false
    }

    private func startAnimationCycle() {
        guard isAnimating else { return }

        animationPhase = 0

        withAnimation(.linear(duration: configuration.cycleDuration)) {
            animationPhase = 1.0
        } completion: {
            guard isAnimating else { return }
            onCycleCompleted()
            continueAnimationCycle()
        }
    }

    /// When using `withAnimation`, if there is no visible content to animate,
    /// SwiftUI may trigger the completion closure immediately, without waiting
    /// for the animation duration.
    ///
    /// In this case, the completion handler starts the same animation cycle again,
    /// which results in an endless loop of immediate animation completions and
    /// restarts.
    ///
    /// This behavior occurs only on iOS 17 and only when another view is presented
    /// over the mailbox, making the cycling progress bar not visible. Since the
    /// progress bar is not rendered in this state, the animation should not be
    /// triggered at all, but this is how iOS 17 behaves.
    ///
    /// The issue is resolved by dispatching the next animation cycle asynchronously
    /// using `DispatchQueue.main.async`, which ensures that the animation restart
    /// does not occur within the same animation transaction, preventing the
    /// immediate completion loop.
    private func continueAnimationCycle() {
        if #available(iOS 18, *) {
            startAnimationCycle()
        } else {
            DispatchQueue.main.async {
                startAnimationCycle()
            }
        }
    }
}

private struct CyclingProgressBar_Preview: View {
    @State private var visible: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Cycling progress bar (\(visible ? "visible" : "hidden"))".notLocalized)
                .font(.headline)
                .padding(.top, 60)
            if visible {
                CyclingProgressBar(configuration: .init(), onCycleCompleted: {})
            }

            Spacer()
            Button {
                visible.toggle()
            } label: {
                Text(visible ? "Hide".notLocalized : "Show".notLocalized)
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
