// Copyright (c) 2026 Proton Technologies AG
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
import ProtonUIFoundations
import SwiftUI

struct FadingEffect: ViewModifier {
    @State var move = false
    let color = DS.Color.Global.white

    func body(content: Content) -> some View {
        content
            .opacity(move ? 0.4 : 1)
            .animation(.linear(duration: 0.35).delay(0.6).repeatForever(autoreverses: true), value: move)
            .onLoad { move = true }
    }
}

extension View {
    func fadingEffect() -> some View {
        self.modifier(FadingEffect())
    }
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea(.all)
        VStack {
            ForEach((0...10), id: \.self) { _ in
                HStack(alignment: .top, spacing: DS.Spacing.compact) {
                    Image(symbol: .arrowCirclePath)
                        .resizable()
                        .square(size: 14)
                        .redactable()

                    VStack(alignment: .leading, spacing: DS.Spacing.small) {
                        Text("Stored with zero-access encryption")
                            .font(.footnote)
                            .foregroundStyle(DS.Color.Text.norm)
                            .redactable()
                        Button(action: {}) {
                            Text("Learn more")
                                .font(.footnote)
                                .foregroundStyle(DS.Color.Text.accent)
                                .redactable()
                        }
                    }
                }
                .redacted(true)
                .fadingEffect()
            }
        }
    }
}

// - Redaction

private struct RedactionEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isRedactionEnabled: Bool {
        get { self[RedactionEnabledKey.self] }
        set { self[RedactionEnabledKey.self] = newValue }
    }
}

extension View {
    func redactable() -> some View {
        self.modifier(Redactable())
    }

    func redacted(_ isReadacted: Bool) -> some View {
        self.modifier(RedactContentModifier(isRedacted: isReadacted))
    }
}

struct Redactable: ViewModifier {
    @Environment(\.isRedactionEnabled) private var isRedacted

    func body(content: Content) -> some View {
        if isRedacted {
            content
                .opacity(0)
                .lineLimit(1)
                .overlay(DS.Color.Background.deep)
                .clipShape(Capsule())
        } else {
            content
        }
    }
}

struct RedactContentModifier: ViewModifier {
    let isRedacted: Bool

    func body(content: Content) -> some View {
        content
            .environment(\.isRedactionEnabled, isRedacted)
    }
}
