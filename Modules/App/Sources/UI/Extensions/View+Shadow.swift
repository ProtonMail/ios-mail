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

extension View {

    func shadow(_ shadow: Shadow, isVisible: Bool) -> some View {
        modifier(ConditionalShadow(shadow: shadow, isVisible: isVisible))
    }

}

private struct ConditionalShadow: ViewModifier {
    private let shadow: Shadow
    private let isVisible: Bool

    init(shadow: Shadow, isVisible: Bool) {
        self.shadow = shadow
        self.isVisible = isVisible
    }

    func body(content: Content) -> some View {
        content
            .shadow(
                color: isVisible ? shadow.color : shadow.color.opacity(0),
                radius: shadow.blur,
                x: shadow.x,
                y: shadow.y
            )
    }
}
