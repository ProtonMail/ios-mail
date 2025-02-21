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

struct MessageBanner: Hashable {
    struct Button: Hashable {
        let title: String
        let action: () -> Void
        
        public static func == (lhs: Button, rhs: Button) -> Bool {
            lhs.title == rhs.title
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(title)
        }
    }

    struct ColorStyle: Hashable {
        let background: Color
        let border: Color
        let button: ButtonStyle
        let content: ContentStyle
    }
    
    struct ContentStyle: Hashable {
        let icon: Color
        let text: Color
    }
    
    struct ButtonStyle: Hashable {
        let background: Color
        let text: Color
    }

    enum LargeType: Hashable {
        case one(Button)
        case two(left: Button, right: Button)
    }

    enum Size: Hashable {
        case small(Button?)
        case large(LargeType)
    }

    enum Style: Hashable {
        case regular
        case error
        
        var color: ColorStyle {
            switch self {
            case .regular:
                .init(
                    background: DS.Color.Background.norm,
                    border: DS.Color.Border.strong,
                    button: .init(background: DS.Color.InteractionWeak.norm, text: DS.Color.Text.norm),
                    content: .init(icon: DS.Color.Icon.weak, text: DS.Color.Text.weak)
                )
            case .error:
                .init(
                    background: DS.Color.Notification.error,
                    border: .clear,
                    button: .init(background: DS.Color.Global.white.opacity(0.2), text: DS.Color.Text.inverted),
                    content: .init(icon: DS.Color.Icon.inverted, text: DS.Color.Text.inverted)
                )
            }
        }
    }

    let id: UUID = UUID()
    let icon: ImageResource
    let message: String
    let size: Size
    let style: Style
}
