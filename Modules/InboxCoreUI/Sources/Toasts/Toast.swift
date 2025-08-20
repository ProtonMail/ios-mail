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

import InboxCore
import InboxDesignSystem
import SwiftUI

public struct Toast: Hashable, Sendable {
    let id: UUID
    let title: String?
    let message: String
    let button: Button?
    let style: Style
    let duration: TimeInterval

    public enum Duration: Hashable {
        /// duration with custom interval
        case custom(TimeInterval)
        /// 1.5s
        case short
        /// 3.0s
        case medium
        /// 8.0 s
        case long

        var timeInterval: TimeInterval {
            switch self {
            case .custom(let interval):
                interval
            case .short:
                1.5
            case .medium:
                3.0
            case .long:
                8.0
            }
        }
    }

    public init(
        id: UUID = UUID(),
        title: String?,
        message: String,
        button: Button?,
        style: Style,
        duration: Duration
    ) {
        self.init(id: id, title: title, message: message, button: button, style: style, duration: duration.timeInterval)
    }

    init(
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
        lhs.title == rhs.title && lhs.message == rhs.message && lhs.button == rhs.button && lhs.style == rhs.style && lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(message)
        hasher.combine(button)
        hasher.combine(style)
        hasher.combine(duration)
    }

    public struct Button: Hashable, Sendable {
        let type: ButtonType
        let action: @Sendable () -> Void

        public init(type: ButtonType, action: @escaping @Sendable () -> Void) {
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

    public enum Style: Sendable {
        case error
        case information
        case success
        case warning
    }

    public enum ButtonType: Hashable, Sendable {
        case largeBottom(buttonTitle: String)
        case smallTrailing(content: ContentType)

        public enum ContentType: Hashable, Sendable {
            case image(ImageResource)
            case title(String)
        }
    }
}

public extension Toast {

    static var comingSoon: Self {
        .information(message: "Coming soon")
    }

    static func error(message: String, duration: Toast.Duration = .short) -> Self {
        .noButton(message: message, style: .error, duration: duration)
    }

    static func information(message: String, duration: Toast.Duration = .short) -> Self {
        .noButton(message: message, style: .information, duration: duration)
    }

    static func informationUndo(
        id: UUID = UUID(),
        message: String,
        duration: Duration,
        undoAction: (() -> Void)?
    ) -> Self {
        let button: Button? =
            switch undoAction {
            case .none:
                .none
            case .some(let action):
                Button(
                    type: .smallTrailing(content: .title(CommonL10n.undo.string)),
                    action: action
                )
            }

        return .init(
            id: id,
            title: .none,
            message: message,
            button: button,
            style: .information,
            duration: duration
        )
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

    private static func noButton(
        message: String,
        style: Toast.Style,
        duration: Toast.Duration
    ) -> Self {
        .init(title: .none, message: message, button: .none, style: style, duration: duration)
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
