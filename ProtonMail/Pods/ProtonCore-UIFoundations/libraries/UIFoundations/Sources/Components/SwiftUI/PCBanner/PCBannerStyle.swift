//
//  PCBannerStyle.swift
//  ProtonCore-UIFoundations - Created on 02.04.2024.
//
//  Copyright (c) 2024 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import SwiftUI

@MainActor
public struct PCBannerStyle {
    public var style: Style

    public enum Style {
        case success
        case warning
        case error
        case info
    }

    public init(style: Style) {
        self.style = style
    }

    var backgroundColor: Color {
        switch style {
        case .success:
            return ColorProvider.NotificationSuccess
        case .warning:
            return ColorProvider.NotificationWarning
        case .error:
            return ColorProvider.NotificationError
        case .info:
            return ColorProvider.NotificationNorm
        }
    }

    var iconColor: Color {
        switch style {
        case .success, .warning, .error:
            return ColorProvider.White
        case .info:
            return ColorProvider.IconInverted
        }
    }

    var buttonBackgroundColor: Color {
        ColorProvider.White.opacity(0.2)
    }
}

#endif
