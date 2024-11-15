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

struct ComposeButtonView: View {
    private let animation: Animation = .easeInOut(duration: 0.2)
    
    let text: LocalizedStringResource
    @Binding private(set) var isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap, label: {
            HStack(spacing: DS.Spacing.standard) {
                Image(DS.Icon.icPenSquare)
                    .foregroundStyle(DS.Color.Brand.minus30)
                    .accessibilityIdentifier(ComposeButtonIdentifiers.icon)
                if isExpanded {
                    Text(text)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(DS.Color.Brand.minus30)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .accessibilityIdentifier(ComposeButtonIdentifiers.text)
                }
            }
            .accessibilityElement(children: .contain)
            .animation(animation, value: isExpanded)
        })
        .buttonStyle(ComposeButtonStyle(isExpanded: isExpanded, animation: animation))
        .accessibilityIdentifier(ComposeButtonIdentifiers.rootElement)
    }
}

private struct ComposeButtonStyle: ButtonStyle {
    var isExpanded: Bool
    var animation: Animation

    func makeBody(configuration: Self.Configuration) -> some View {
        return configuration
            .label
            .padding(.horizontal, DS.Spacing.large)
            .padding(.vertical, DS.Spacing.moderatelyLarge)
            .background(configuration.isPressed ? DS.Color.InteractionBrandStrong.pressed : DS.Color.InteractionBrandStrong.norm)
            .foregroundColor(Color.white)
            .clipShape(Capsule(style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 10)
            .animation(animation, value: isExpanded)
    }
}

#Preview {
    struct Container: View {
        @State var expand: Bool =  true
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
