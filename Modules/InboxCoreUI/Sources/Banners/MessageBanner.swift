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

struct MessageBanner {
    struct Button {
        let title: String
        let action: () -> Void
    }

    struct ColorStyle {
        let background: Color
        let icon: Color
        let text: Color
        let border: Color
        let button: Button
        
        struct Button {
            let background: Color
            let text: Color
        }
    }
    
    enum Style {
        case regular
        case error
        
        var color: ColorStyle {
            switch self {
            case .regular:
                .init(
                    background: DS.Color.Background.norm,
                    icon: DS.Color.Icon.weak,
                    text: DS.Color.Text.weak,
                    border: DS.Color.Border.strong,
                    button: .init(background: DS.Color.InteractionWeak.norm, text: DS.Color.Text.norm)
                )
            case .error:
                .init(
                    background: DS.Color.Notification.error,
                    icon: DS.Color.Icon.inverted,
                    text: DS.Color.Text.inverted,
                    border: .clear,
                    button: .init(background: DS.Color.Global.white.opacity(0.2), text: DS.Color.Text.inverted)
                )
            }
        }
    }

    let id: UUID = UUID()
    let message: String
    let button: Button?
    let style: Style
}
