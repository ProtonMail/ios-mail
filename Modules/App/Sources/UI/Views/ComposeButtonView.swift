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

import InboxDesignSystem
import SwiftUI

// MARK: - Liquid Glass Adapter

extension View {
    /// Adapts view modifications based on iOS version for Liquid Glass support.
    ///
    /// Provides a clean API to apply different view modifications depending on whether
    /// the device is running iOS 26.0 or later (with Liquid Glass support) or an earlier version.
    ///
    /// - Parameters:
    ///   - ios26: A ViewBuilder closure that modifies the view for iOS 26.0 and later
    ///   - belowIOS26: A ViewBuilder closure that modifies the view for iOS versions below 26.0
    /// - Returns: A view with the appropriate modifications applied
    ///
    /// Example usage:
    /// ```swift
    /// // Apply modifications for both versions
    /// someView
    ///     .liquidGlassAdapter(
    ///         ios26: { view in
    ///             view.toolbar {
    ///                 ToolbarItem(placement: .bottomBar) {
    ///                     Button("Action") { }
    ///                 }
    ///             }
    ///         },
    ///         belowIOS26: { view in
    ///             view.overlay(alignment: .bottom) {
    ///                 Button("Action") { }
    ///             }
    ///         }
    ///     )
    ///
    /// // Apply modifications only for iOS 26+ (pass identity closure for belowIOS26)
    /// someView
    ///     .liquidGlassAdapter(
    ///         ios26: { $0.someModifier() },
    ///         belowIOS26: { $0 }
    ///     )
    ///
    /// // Apply modifications only for below iOS 26 (pass identity closure for ios26)
    /// someView
    ///     .liquidGlassAdapter(
    ///         ios26: { $0 },
    ///         belowIOS26: { $0.someModifier() }
    ///     )
    /// ```
    func liquidGlassAdapter<iOS26Content: View, BelowIOS26Content: View>(
        @ViewBuilder ios26: @escaping (Self) -> iOS26Content,
        @ViewBuilder belowIOS26: @escaping (Self) -> BelowIOS26Content
    ) -> some View {
        LiquidGlassAdapterView(
            content: self,
            ios26Modification: ios26,
            belowIOS26Modification: belowIOS26
        )
    }
}

private struct LiquidGlassAdapterView<Content: View, iOS26Content: View, BelowIOS26Content: View>: View {
    let content: Content
    let ios26Modification: (Content) -> iOS26Content
    let belowIOS26Modification: (Content) -> BelowIOS26Content

    var body: some View {
        if #available(iOS 26.0, *) {
            ios26Modification(content)
        } else {
            belowIOS26Modification(content)
        }
    }
}

struct LiquidComposeButton: ToolbarContent {
    let isExpanded: Bool
    let action: () -> Void

    var body: some ToolbarContent {
        if isExpanded {
            ToolbarItem(placement: .bottomBar) {
                Button(
                    action: action,
                    label: {
                        HStack(spacing: DS.Spacing.standard) {
                            Image(DS.Icon.icPenSquare)
                                .foregroundStyle(DS.Color.Icon.norm)
                            Text(L10n.Mailbox.compose)
                                .fontWeight(.semibold)
                                .foregroundStyle(DS.Color.Icon.norm)
                        }
                    }
                )
            }
        } else {
            ToolbarItem(placement: .bottomBar) {
                Button(
                    action: action,
                    label: {
                        Image(DS.Icon.icPenSquare)
                            .foregroundStyle(DS.Color.Icon.norm)
                    }
                )
            }
        }
    }
}

struct ComposeButtonView: View {
    private let animation: Animation = .easeInOut(duration: 0.2)

    let text: LocalizedStringResource
    @Binding private(set) var isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(
            action: onTap,
            label: {
                HStack(spacing: DS.Spacing.standard) {
                    Image(DS.Icon.icPenSquare)
                        .foregroundStyle(DS.Color.Icon.norm)
                        .accessibilityIdentifier(ComposeButtonIdentifiers.icon)
                    if isExpanded {
                        Text(text)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.Icon.norm)
                            .padding(.trailing, DS.Spacing.small)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                            .accessibilityIdentifier(ComposeButtonIdentifiers.text)
                    }
                }
                .accessibilityElement(children: .contain)
                .animation(animation, value: isExpanded)
            }
        )
        .buttonStyle(ComposeButtonStyle(isExpanded: isExpanded, animation: animation))
        .accessibilityIdentifier(ComposeButtonIdentifiers.rootElement)
    }
}

private struct ComposeButtonStyle: ButtonStyle {
    var isExpanded: Bool
    var animation: Animation

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration
            .label
            .padding(.all, DS.Spacing.moderatelyLarge)
            .background(configuration.isPressed ? DS.Color.InteractionFab.pressed : DS.Color.InteractionFab.norm)
            .overlay(
                Capsule(style: .continuous)
                    .stroke(DS.Color.Border.light, lineWidth: 1)
            )
            .clipShape(Capsule(style: .continuous))
            .shadow(DS.Shadows.liftedFull, isVisible: true)
            .animation(animation, value: isExpanded)
    }
}

#Preview {
    struct Container: View {
        @State var expand: Bool = true
        var body: some View {
            ComposeButtonView(text: "Compose", isExpanded: $expand) {
                expand.toggle()
            }
        }
    }
    return Container()
}

private struct ComposeButtonIdentifiers {
    static let rootElement = "compose.button"
    static let icon = "compose.button.icon"
    static let text = "compose.button.text"
}
