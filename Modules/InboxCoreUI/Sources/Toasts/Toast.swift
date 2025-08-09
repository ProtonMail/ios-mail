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

public struct Toast: Hashable {
    let id: UUID
    let title: String?
    let message: String
    let button: Button?
    let style: Style
    let duration: TimeInterval

    public init(
        id: UUID = UUID(),
        title: String?,
        message: String,
        button: Button?,
        style: Style,
        duration: TimeInterval
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.button = button
        self.style = style
        self.duration = duration
    }

    public static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.title == rhs.title &&
        lhs.message == rhs.message &&
        lhs.button == rhs.button &&
        lhs.style == rhs.style &&
        lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(message)
        hasher.combine(button)
        hasher.combine(style)
        hasher.combine(duration)
    }

    public struct Button: Hashable {
        let type: ButtonType
        let action: () -> Void

        public init(type: ButtonType, action: @escaping () -> Void) {
            self.type = type
            self.action = action
        }

        public static func == (lhs: Toast.Button, rhs: Toast.Button) -> Bool {
            lhs.type == rhs.type
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
        }
    }

    public enum Style {
        case error
        case information
        case success
        case warning
    }

    public enum ButtonType: Hashable {
        case largeBottom(buttonTitle: String)
        case smallTrailing(content: ContentType)

        public enum ContentType: Hashable {
            case image(ImageResource)
            case title(String)
        }
    }

    public func duration(_ newDuration: TimeInterval) -> Self {
        .init(
            title: title,
            message: message,
            button: button,
            style: style,
            duration: newDuration
        )
    }
}

public extension Toast {

    static var comingSoon: Self {
        .information(message: "Coming soon")
    }

    static func error(message: String) -> Self {
        .noButtonDefaultDuration(message: message, style: .error)
    }

    static func information(message: String) -> Self {
        .noButtonDefaultDuration(message: message, style: .information)
    }

    var shadowOpacity: CGFloat {
        let smallToastOpacity: CGFloat = 0.4
        let bigToastOpacity: CGFloat = 0.2

        switch button {
        case .none:
            return smallToastOpacity
        case .some(let button):
            switch button.type {
            case .smallTrailing:
                return smallToastOpacity
            case .largeBottom:
                return bigToastOpacity
            }
        }
    }

    // MARK: - Private

    private static func noButtonDefaultDuration(message: String, style: Toast.Style) -> Self {
        .init(title: nil, message: message, button: nil, style: style, duration: .toastDefaultDuration)
    }

}

extension Toast.Style {

    var color: Color {
        switch self {
        case .error:
            return DS.Color.Notification.error
        case .information:
            return DS.Color.Notification.norm
        case .success:
            return DS.Color.Notification.success
        case .warning:
            return DS.Color.Notification.warning
        }
    }

}

public extension TimeInterval {
    static let toastDefaultDuration: TimeInterval = 1.5
    static let toastMediumDuration: TimeInterval = 3.0
}
