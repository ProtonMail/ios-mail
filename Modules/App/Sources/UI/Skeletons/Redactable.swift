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
import SwiftUI

extension View {
    func redactable() -> some View {
        self.modifier(Redactable())
    }

    func redacted(_ isReadacted: Bool) -> some View {
        self.modifier(RedactContentModifier(isRedacted: isReadacted))
    }
}

private struct RedactionEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private extension EnvironmentValues {
    var isRedactionEnabled: Bool {
        get { self[RedactionEnabledKey.self] }
        set { self[RedactionEnabledKey.self] = newValue }
    }
}

private struct Redactable: ViewModifier {
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

private struct RedactContentModifier: ViewModifier {
    let isRedacted: Bool

    func body(content: Content) -> some View {
        content
            .environment(\.isRedactionEnabled, isRedacted)
    }
}
