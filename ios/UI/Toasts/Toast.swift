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

import DesignSystem
import SwiftUI

struct Toast: Equatable {
    let title: String?
    let message: String
    let button: Button?
    let style: Style

    struct Button: Equatable {
        let type: ButtonType
        let action: () -> Void

        static func == (lhs: Toast.Button, rhs: Toast.Button) -> Bool {
            lhs.type == rhs.type
        }
    }

    enum Style {
        case error
        case information
        case success
        case warning
    }

    enum ButtonType: Equatable {
        case largeBottom(buttonTitle: String)
        case smallTrailing(content: ContentType)

        enum ContentType: Equatable {
            case image(Image)
            case title(String)
        }
    }
}

extension Toast {

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
