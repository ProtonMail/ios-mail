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

import SwiftUI

public extension DS.Color {

    enum Background {
        public static let norm = Color(.shade0)
        public static let secondary = Color(.shade10)
        public static let deep = Color(.backgroundDeep)
        public static let avatar = Color(.backgroundAvatar)
    }
    
    enum Gradient {
        public static let crazy: [Color] = [
            Color(.neonMint),
            Color(.electricSky),
            Color(.brightAzure),
            Color(.vividOrchid),
            Color(.hotPinkPop)
        ]
    }

    enum BackgroundInverted {
        public static let norm = Color(.backgroundInvertedNorm)
        public static let secondary = Color(.backgroundInvertedSecondary)
        public static let deep = Color(.backgroundInvertedSecondary)
        public static let border = Color(.backgroundInvertedBorder)
    }

    enum Border {
        public static let light = Color(.borderLight)
        public static let norm = Color(.borderNorm)
        public static let strong = Color(.borderStrong)
    }

    enum Brand {
        public static let plus30 = Color(.brandPlus30)
        public static let plus20 = Color(.brandPlus20)
        public static let plus10 = Color(.brandPlus10)
        public static let norm = Color(.brandNorm)
        public static let minus10 = Color(.brandMinus10)
        public static let minus20 = Color(.brandMinus20)
        public static let minus30 = Color(.brandMinus30)
        public static let minus40 = Color(.brandMinus40)
    }

    enum Global {
        public static let black = Color(.globalBlack)
        public static let white = Color(.globalWhite)
        public static let modal = Color(.modal)
    }

    enum Icon {
        public static let norm = Color(.shade100)
        public static let weak = Color(.shade80)
        public static let hint = Color(.iconHint)
        public static let disabled = Color(.iconDisabled)
        public static let inverted = Color(.shade0)
        public static let accent = Color(.brandNorm)
    }

    enum InteractionBrand {
        public static let norm = Color(.interactionBrandNorm)
        public static let pressed = Color(.interactionBrandPressed)
        public static let disabled = Color(.interactionBrandDisabled)
    }

    enum InteractionBrandStrong {
        public static let norm = Color(.interactionBrandStrongNorm)
        public static let pressed = Color(.interactionBrandStrongPressed)
    }

    enum InteractionBrandWeak {
        public static let norm = Color(.interactionBrandWeakNorm)
        public static let pressed = Color(.interactionBrandWeakPressed)
        public static let disabled = Color(.interactionBrandWeakDisabled)
    }

    enum InteractionWeak {
        public static let norm = Color(.interactionWeakNorm)
        public static let pressed = Color(.interactionWeakPressed)
        public static let disabled = Color(.interactionWeakDisabled)
    }

    enum InteractionFab {
        public static let norm = Color(.interactionFabNorm)
        public static let pressed = Color(.interactionFabPressed)
    }

    enum Notification {
        public static let error = Color(.notificationError)
        public static let norm = Color(.notificationNorm)
        public static let success = Color(.notificationSuccess)
        public static let warning = Color(.notificationWarning)
    }

    enum Shade {
        public static let shade0 = Color(.shade0)
        public static let shade10 = Color(.shade10)
        public static let shade20 = Color(.shade20)
        public static let shade40 = Color(.shade40)
        public static let shade45 = Color(.shade45)
        public static let shade50 = Color(.shade50)
        public static let shade60 = Color(.shade60)
        public static let shade80 = Color(.shade80)
        public static let shade100 = Color(.shade100)
    }

    enum Sidebar {
        public static let background = Color(.sidebarBackground)
        public static let interactionPressed = Color(.sidebarInteractionPressed)
        public static let separator = Color(.sidebarSeparator)
        public static let textNorm = Color(.sidebarTextNorm)
        public static let textWeak = Color(.sidebarTextWeak)
        public static let textSelected = Color(.sidebarTextSelected)
        public static let iconNorm = Color(.sidebarIconNorm)
        public static let iconWeak = Color(.sidebarIconWeak)
        public static let iconSelected = Color(.sidebarIconSelected)
    }

    enum Star {
        public static let `default` = Color(.starDefault)
        public static let selected = Color(.starSelected)
    }

    enum Text {
        public static let norm = Color(.shade100)
        public static let weak = Color(.shade80)
        public static let hint = Color(.textHint)
        public static let disabled = Color(.textDisabled)
        public static let inverted = Color(.shade0)
        public static let accent = Color(.brandNorm)
    }
}
