// Copyright (c) 2024 Proton Technologies AG
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

/// A background view that applies a transparent blur effect to the content
/// behind it, without adding the extra white tint layer that system
/// materials like `.ultraThinMaterial` introduce.
///
/// `BlurredBackground` is useful in places where you want a clean blur
/// effect that lets the underlying content remain visible but softened,
/// without altering the overall color tone with an additional overlay.
///
/// - Note: When the **Reduce Transparency** accessibility setting is enabled,
///   the blur effect is disabled by the system. In that case, the view falls
///   back to displaying a solid background color instead of a blur.
public struct BlurredBackground: View {
    private let fallbackBackgroundColor: Color?
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    /// Creates a blurred background.
    ///
    /// - Parameter fallbackBackgroundColor:
    ///   The color used as a solid background when the **Reduce Transparency**
    ///   accessibility setting is turned on. This prevents the content behind
    ///   the view from becoming fully visible when blur is removed.
    public init(fallbackBackgroundColor: Color?) {
        self.fallbackBackgroundColor = fallbackBackgroundColor
    }

    public var body: some View {
        if reduceTransparency {
            fallbackBackgroundColor
        } else {
            TransparentBlur()
        }
    }
}

private struct TransparentBlur: UIViewRepresentable {
    init() {}

    func makeUIView(context: Context) -> some UIView {
        TransparentBlurView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

private class TransparentBlurView: UIVisualEffectView {
    override func layoutSublayers(of layer: CALayer) {
        layer.sublayers?.first?.filters?.removeAll(where: { filter in
            String(describing: filter) != "gaussianBlur"
        })
    }
}
