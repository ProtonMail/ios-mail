//
//  WalletColorPaletteiOS.swift
//  ProtonCore-UIFoundations - Created on 21.05.24.
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

import Foundation

public struct WalletColorPaletteiOS: ColorPaletteiOS {

    public typealias T = WalletColorPaletteiOS

    public static let instance = WalletColorPaletteiOS()

    private init() {}

    // MARK: MobileBrand
    public var BrandNorm: ProtonColor {
        ProtonColor(name: "DreamyBlue")
    }
    public var BrandDarken10: ProtonColor {
        ProtonColor(name: "MoodyBlue")
    }
    public var BrandDarken20: ProtonColor {
        ProtonColor(name: "Victoria")
    }
    public var BrandDarken30: ProtonColor {
        ProtonColor(name: "Meteorite")
    }
    public var BrandLighten10: ProtonColor {
        ProtonColor(name: "LavenderMist")
    }
    public var BrandLighten20: ProtonColor {
        ProtonColor(name: "WhisperLila")
    }
    public var BrandLighten30: ProtonColor {
        ProtonColor(name: "TitanWhite")
    }

    // MARK: Notification
    public var NotificationError: ProtonColor {
        ProtonColor(name: "Bittersweet", alternativeDarkName: "VividTangerine")
    }
    public var NotificationWarning: ProtonColor {
        ProtonColor(name: "TreePoppy", alternativeDarkName: "TexasRose")
    }
    public var NotificationSuccess: ProtonColor {
        ProtonColor(name: "MountainMeadow", alternativeDarkName: "Tara")
    }
    public var NotificationNorm: ProtonColor {
        ProtonColor(name: "DreamyBlue", alternativeDarkName: "TitanWhite")
    }

    // MARK: Interaction norm
    public var InteractionNorm: ProtonColor {
        BrandNorm
    }
    public var InteractionNormPressed: ProtonColor {
        ProtonColor(name: "MoodyBlue", alternativeDarkName: "WhisperLila")
    }
    public var InteractionNormDisabled: ProtonColor {
        BrandLighten30
    }

    // MARK: Interaction Strong
    public var InteractionStrong: ProtonColor {
        Shade100
    }
    public var InteractionStrongPressed: ProtonColor {
        Shade80
    }

    // MARK: Interaction Weak
    public var InteractionWeak: ProtonColor {
        Shade0
    }
    public var InteractionWeakPressed: ProtonColor {
        Shade40
    }
    public var InteractionWeakDisabled: ProtonColor {
        Shade20
    }

    // MARK: Shade
    public var Shade100: ProtonColor {
        ProtonColor(name: "Mirage", alternativeDarkName: "White")
    }
    public var Shade80: ProtonColor {
        ProtonColor(name: "Trout", alternativeDarkName: "Manatee")
    }
    public var Shade60: ProtonColor {
        ProtonColor(name: "MistySilver", alternativeDarkName: "Topaz")
    }
    public var Shade50: ProtonColor {
        ProtonColor(name: "Mischka", alternativeDarkName: "MulledWine")
    }
    public var Shade40: ProtonColor {
        ProtonColor(name: "Mercury", alternativeDarkName: "BlueGunPowder")
    }
    public var Shade20: ProtonColor {
        ProtonColor(name: "FrostWhisper", alternativeDarkName: "Martinique")
    }
    public var Shade10: ProtonColor {
        ProtonColor(name: "CloudVeil", alternativeDarkName: "BlueCinder")
    }

    // MARK: Text
    public var TextNorm: ProtonColor {
        Shade100
    }
    public var TextWeak: ProtonColor {
        Shade80
    }
    public var TextHint: ProtonColor {
        Shade60
    }
    public var TextDisabled: ProtonColor {
        Shade50
    }
    public var TextInverted: ProtonColor {
        Shade0
    }
    public var TextAccent: ProtonColor {
        ProtonColor(name: "DreamyBlue", alternativeDarkName: "WhisperLila")
    }

    // MARK: Icon
    public var IconNorm: ProtonColor {
        Shade100
    }
    public var IconWeak: ProtonColor {
        Shade80
    }
    public var IconHint: ProtonColor {
        Shade60
    }
    public var IconDisabled: ProtonColor {
        Shade50
    }
    public var IconInverted: ProtonColor {
        Shade0
    }
    public var IconAccent: ProtonColor {
        ProtonColor(name: "DreamyBlue", alternativeDarkName: "WhisperLila")
    }

    // MARK: Background
    public var BackgroundNorm: ProtonColor {
        Shade10
    }
    public var BackgroundDeep: ProtonColor {
        Shade20
    }
    public var BackgroundSecondary: ProtonColor {
        Shade0
    }

    // MARK: Separator
    public var SeparatorNorm: ProtonColor {
        Shade20
    }

    public var SeparatorStrong: ProtonColor {
        Shade40
    }

    // MARK: Sidebar
    public var SidebarBackground: ProtonColor {
        ProtonColor(name: "MidnightPulse")
    }
    public var SidebarInteractionWeakPressed: ProtonColor {
        ProtonColor(name: "PortGore")
    }
    public var SidebarInteractionSelected: ProtonColor {
        ProtonColor(name: "DreamyBlue")
    }
    public var SidebarInteractionAlternative: ProtonColor {
        ProtonColor(name: "TexasRose")
    }
    public var SidebarTextNorm: ProtonColor {
        ProtonColor(name: "CadetBlue")
    }
    public var SidebarTextWeak: ProtonColor {
        ProtonColor(name: "MulledWine")
    }
    public var SidebarIconNorm: ProtonColor {
        ProtonColor(name: "Topaz")
    }
    public var SidebarIconWeak: ProtonColor {
        ProtonColor(name: "MulledWine")
    }
    public var SidebarInteractionPressed: ProtonColor {
        ProtonColor(name: "PortGore")
    }
}
