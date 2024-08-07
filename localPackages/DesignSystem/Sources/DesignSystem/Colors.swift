//
//  File.swift
//  
//
//  Created by xavi on 5/3/24.
//

import SwiftUI

public extension DS.Color {

    enum Background {
        public static let norm = Color(.shade0)
        public static let secondary = Color(.shade10)
        public static let deep = Color(.shade20)
    }

    enum Border {
        public static let norm = Color(.shade10)
        public static let strong = Color(.shade20)
    }

    enum Brand {
        public static let lighten30 = Color(.brandLighten30)
        public static let lighten20 = Color(.brandLighten20)
        public static let lighten10 = Color(.brandLighten10)
        public static let norm = Color(.brandNorm)
        public static let darken10 = Color(.brandDarken10)
        public static let darken20 = Color(.brandDarken20)
        public static let darken30 = Color(.brandDarken30)
    }

    enum Global {
        public static let black = Color(.globalBlack)
        public static let white = Color(.globalWhite)
    }

    enum Icon {
        public static let norm = Color(.shade100)
        public static let weak = Color(.shade80)
        public static let hint = Color(.shade50)
        public static let disabled = Color(.shade40)
        public static let inverted = Color(.shade0)
        public static let accent = Color(.brandNorm)
    }

    enum Interaction {
        public static let norm = Color(.brandNorm)
        public static let pressed = Color(.brandDarken10)
        public static let disabled = Color(.brandLighten10)
    }

    enum InteractionStrong {
        public static let norm = Color(.brandDarken10)
        public static let pressed = Color(.brandDarken20)
    }

    enum InteractionWeak {
        public static let norm = Color(.shade10)
        public static let pressed = Color(.shade20)
        public static let disabled = Color(.shade10)
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
        public static let shade50 = Color(.shade50)
        public static let shade60 = Color(.shade60)
        public static let shade80 = Color(.shade80)
        public static let shade100 = Color(.shade100)
    }

    enum Sidebar {
        public static let background = Color(.sidebarBackground)
        public static let interactionPressed = Color(.sidebarInteractionPressed)
        public static let interactionSelected = Color(.sidebarInteractionSelected)
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
        public static let hint = Color(.shade50)
        public static let disabled = Color(.shade40)
        public static let inverted = Color(.shade0)
        public static let accent = Color(.brandNorm)
    }
}
