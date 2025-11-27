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

public struct LongPressFormBigButton<BottomContent: View>: View {
    private let title: LocalizedStringResource
    private let value: String
    private let hasAccentTextColor: Bool
    private let onTap: () -> Void
    @ViewBuilder private let bottomContent: () -> BottomContent?
    @State private var isPressed: Bool = false

    public init(
        title: LocalizedStringResource,
        value: String,
        hasAccentTextColor: Bool,
        onTap: @escaping () -> Void,
        bottomContent: @escaping () -> BottomContent?
    ) {
        self.title = title
        self.value = value
        self.hasAccentTextColor = hasAccentTextColor
        self.onTap = onTap
        self.bottomContent = bottomContent
    }

    public var body: some View {
        FormBigButtonContent(
            title: title,
            value: value,
            hasAccentTextColor: hasAccentTextColor,
            accessoryType: .none,
            bottomContent: bottomContent
        )
        .textSelection(.enabled)
        .conditionalLongPress(onPressingChanged: { changed in isPressed = changed })
        .onTapGesture(perform: onTap)
        .background(isPressed && hasAccentTextColor ? DS.Color.InteractionWeak.pressed : .clear)
        .background(DS.Color.BackgroundInverted.secondary)
    }
}

private extension View {
    func conditionalLongPress(onPressingChanged: ((Bool) -> Void)?) -> some View {
        modifier(ConditionalLongPress(onPressingChanged: onPressingChanged))
    }
}

private struct ConditionalLongPress: ViewModifier {
    let onPressingChanged: ((Bool) -> Void)?

    func body(content: Content) -> some View {
        if #available(iOS 18, *) {
            content
                .onLongPressGesture(perform: {}, onPressingChanged: onPressingChanged)
        } else {
            content
        }
    }
}
