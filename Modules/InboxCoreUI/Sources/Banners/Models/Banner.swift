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

public struct Banner: Hashable {
    public struct Button: Hashable {
        public let title: String
        public let action: () -> Void
        
        public init(title: LocalizedStringResource, action: @escaping () -> Void) {
            self.title = title.string
            self.action = action
        }
        
        public static func == (lhs: Button, rhs: Button) -> Bool {
            lhs.title == rhs.title
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(title)
        }
    }

    public struct ColorStyle: Hashable {
        let background: Color
        let border: Color
        let button: ButtonStyle
        let content: ContentStyle
    }
    
    public struct ContentStyle: Hashable {
        let icon: Color
        let text: Color
        
        public static var regular: Self {
            .init(icon: DS.Color.Icon.weak, text: DS.Color.Text.weak)
        }
    }
    
    public struct ButtonStyle: Hashable {
        let background: Color
        let text: Color
        let strokeColors: [Color]
        
        public static var regular: Self {
            .textNorm(background: DS.Color.InteractionWeak.norm, strokeColors: [])
        }
        
        public static var gradient: Self {
            .textNorm(background: DS.Color.Background.norm, strokeColors: DS.Color.Gradient.crazy)
        }
        
        // MARK: - Private
        
        private static func textNorm(background: Color, strokeColors: [Color]) -> Self {
            .init(background: background, text: DS.Color.Text.norm, strokeColors: strokeColors)
        }
    }

    public enum LargeType: Hashable {
        case one(Button)
        case two(left: Button, right: Button)
    }

    public enum Size: Hashable {
        case small(Button?)
        case large(LargeType)
    }

    public enum Style: Hashable {
        case regular
        case error
        
        var color: ColorStyle {
            switch self {
            case .regular:
                .init(
                    background: DS.Color.Background.norm,
                    border: DS.Color.Border.strong,
                    button: .regular,
                    content: .regular
                )
            case .error:
                .init(
                    background: DS.Color.Notification.error,
                    border: .clear,
                    button: .init(
                        background: DS.Color.Global.white.opacity(0.2),
                        text: DS.Color.Text.inverted,
                        strokeColors: []
                    ),
                    content: .init(icon: DS.Color.Icon.inverted, text: DS.Color.Text.inverted)
                )
            }
        }
    }

    let id: UUID = UUID()
    public let icon: ImageResource
    public let message: String
    public let size: Size
    public let style: Style
    
    public init(icon: ImageResource, message: LocalizedStringResource, size: Size, style: Style) {
        self.icon = icon
        self.message = message.string
        self.size = size
        self.style = style
    }
}
