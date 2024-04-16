//
//  Created on 5/4/24.
//
//  Copyright (c) 2024 Proton AG
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import SwiftUI

public enum BannerState: Equatable {
    case error(content: PCBannerContent)
    case none

    public static func == (lhs: BannerState, rhs: BannerState) -> Bool {
        switch (lhs, rhs) {
        case (.error, .error): return true
        case (.none, .none): return true
        default: return false
        }
    }
}

public struct PCBannerConfiguration {
    public var animationDuration: CGFloat
    public var dismissDuration: TimeInterval?

    public init(
        animationDuration: CGFloat = 0.25,
        dismissDuration: TimeInterval? = 4
    ) {
        self.animationDuration = animationDuration
        self.dismissDuration = dismissDuration
    }

    public static func `default`() -> PCBannerConfiguration {
        .init()
    }
}

@MainActor
public struct PCBannerDisplay: ViewModifier {
    @Binding public var bannerState: BannerState
    let configuration: PCBannerConfiguration

    @State private var animating: Bool = false
    @State private var dragYOffset: CGFloat = 0

    @State var timer: Timer?

    public func body(content: Content) -> some View {
        if bannerState != .none {
            content
                .overlay(banner, alignment: .top)
        } else {
            content
        }
    }

    @ViewBuilder
    private var banner: some View {
        ZStack {
            if animating {
                PCBanner(
                    style: .constant(style),
                    content: .constant(content)
                )
                .padding()
                .offset(y: min(0, dragYOffset))
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    withAnimation { dragYOffset = gesture.translation.height }
                }
                .onEnded { value in
                    let velocity = CGSize(
                        width:  value.predictedEndLocation.x - value.location.x,
                        height: value.predictedEndLocation.y - value.location.y
                    )
                    if velocity.height <= -50 {
                        dismissBanner()
                    }
                }
        )
        .onAppear {
            showBanner()
            if let dismissDuration = configuration.dismissDuration {
                timer = Timer.scheduledTimer(withTimeInterval: dismissDuration, repeats: false, block: { _ in
                    DispatchQueue.main.async { dismissBanner() }
                })
            }
        }
    }

    var style: PCBannerStyle {
        switch bannerState {
        case .error: return .init(style: .error)
        case .none: return .init(style: .info)
        }
    }

    var content: PCBannerContent {
        switch bannerState {
        case .error(let content): return content
        case .none: return .init(message: "")
        }
    }

    private func showBanner() {
        withAnimation(Animation.easeInOut(duration: configuration.animationDuration)) {
            animating = true
        }
    }

    private func dismissBanner() {
        timer?.invalidate()
        timer = nil
        withAnimation(Animation.easeInOut(duration: configuration.animationDuration)) {
            animating = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + configuration.animationDuration) {
            bannerState = .none
            dragYOffset = 0
        }
    }
}

public extension View {
    @MainActor
    func bannerDisplayable(bannerState: Binding<BannerState>, configuration: PCBannerConfiguration) -> some View {
        modifier(PCBannerDisplay(bannerState: bannerState, configuration: configuration))
    }
}

#endif
