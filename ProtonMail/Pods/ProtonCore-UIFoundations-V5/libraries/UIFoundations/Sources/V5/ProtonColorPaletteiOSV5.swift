//
//  ProtonColorPaletteiOSV5.swift
//  ProtonCore-UIFoundations - Created on 04.11.20.
//
//  Copyright (c) 2022 Proton Technologies AG
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

public struct ProtonColorPaletteiOS {
    static let instance = ProtonColorPaletteiOS()

    private init() {}

    // MARK: MobileBrand
    public let BrandDarken40 = ProtonColor(name: "MobileBrandDarken40")
    public let BrandDarken20 = ProtonColor(name: "MobileBrandDarken20")
    public let BrandNorm = ProtonColor(name: "MobileBrandNorm")
    public let BrandLighten20 = ProtonColor(name: "MobileBrandLighten20")
    public let BrandLighten40 = ProtonColor(name: "MobileBrandLighten40")

    // MARK: Notification
    public var NotificationError: ProtonColor {
        ProtonColor(name: "MobileNotificationError", vpnFallbackRgb: notificationErrorVpn)
    }
    public var NotificationWarning: ProtonColor {
        ProtonColor(name: "MobileNotificationWarning", vpnFallbackRgb: notificationWarningVpn)
    }
    public var NotificationSuccess: ProtonColor {
        ProtonColor(name: "MobileNotificationSuccess", vpnFallbackRgb: notificationSuccessVpn)
    }
    public var NotificationNorm: ProtonColor {
        ProtonColor(name: "MobileNotificationNorm", vpnFallbackRgb: notificationNormVpn)
    }

    // MARK: Interaction norm
    public let InteractionNorm = ProtonColor(name: "MobileInteractionNorm")
    public let InteractionNormPressed = ProtonColor(name: "MobileInteractionNormPressed")
    public let InteractionNormDisabled = ProtonColor(name: "MobileInteractionNormDisabled")
    
    // MARK: Shade
    public var Shade100: ProtonColor {
        ProtonColor(name: "MobileShade100", vpnFallbackRgb: shade100Vpn)
    }
    public var Shade80: ProtonColor {
        ProtonColor(name: "MobileShade80", vpnFallbackRgb: shade80Vpn)
    }
    public var Shade60: ProtonColor {
        ProtonColor(name: "MobileShade60", vpnFallbackRgb: shade60Vpn)
    }
    public var Shade50: ProtonColor {
        ProtonColor(name: "MobileShade50", vpnFallbackRgb: shade50Vpn)
    }
    public var Shade40: ProtonColor {
        ProtonColor(name: "MobileShade40", vpnFallbackRgb: shade40Vpn)
    }
    public var Shade20: ProtonColor {
        ProtonColor(name: "MobileShade20", vpnFallbackRgb: shade20Vpn)
    }
    public var Shade15: ProtonColor {
        ProtonColor(name: "MobileShade15", vpnFallbackRgb: shade15Vpn)
    }
    public var Shade10: ProtonColor {
        ProtonColor(name: "MobileShade10", vpnFallbackRgb: shade10Vpn)
    }
    public var Shade0: ProtonColor {
        ProtonColor(name: "MobileShade0", vpnFallbackRgb: shade0Vpn)
    }

    // MARK: Text
    public var TextNorm: ProtonColor {
        ProtonColor(name: "MobileTextNorm", vpnFallbackRgb: textNormVpn)
    }
    public var TextWeak: ProtonColor {
        ProtonColor(name: "MobileTextWeak", vpnFallbackRgb: textWeakVpn)
    }
    public var TextHint: ProtonColor {
        ProtonColor(name: "MobileTextHint", vpnFallbackRgb: textHintVpn)
    }
    public var TextDisabled: ProtonColor {
        ProtonColor(name: "MobileTextDisabled", vpnFallbackRgb: textDisabledVpn)
    }
    public var TextInverted: ProtonColor {
        ProtonColor(name: "MobileTextInverted", vpnFallbackRgb: textInvertedVpn)
    }
    public var TextAccent: ProtonColor {
        ProtonColor(name: "MobileTextAccent", vpnFallbackRgb: textAccentVpn)
    }

    // MARK: Icon
    public var IconNorm: ProtonColor {
        ProtonColor(name: "MobileIconNorm", vpnFallbackRgb: iconNormVpn)
    }
    public var IconWeak: ProtonColor {
        ProtonColor(name: "MobileIconWeak", vpnFallbackRgb: iconWeakVpn)
    }
    public var IconHint: ProtonColor {
        ProtonColor(name: "MobileIconHint", vpnFallbackRgb: iconHintVpn)
    }
    public var IconDisabled: ProtonColor {
        ProtonColor(name: "MobileIconDisabled", vpnFallbackRgb: iconDisabledVpn)
    }
    public var IconInverted: ProtonColor {
        ProtonColor(name: "MobileIconInverted", vpnFallbackRgb: iconInvertedVpn)
    }
    public var IconAccent: ProtonColor {
        ProtonColor(name: "MobileIconAccent", vpnFallbackRgb: iconAccentVpn)
    }
    
    // MARK: Interaction
    public var InteractionWeak: ProtonColor {
        ProtonColor(name: "MobileInteractionWeak", vpnFallbackRgb: interactionWeakVpn)
    }
    public var InteractionWeakPressed: ProtonColor {
        ProtonColor(name: "MobileInteractionWeakPressed", vpnFallbackRgb: interactionWeakPressedVpn)
    }
    public var InteractionWeakDisabled: ProtonColor {
        ProtonColor(name: "MobileInteractionWeakDisabled", vpnFallbackRgb: interactionWeakDisabledVpn)
    }
    public var InteractionStrong: ProtonColor {
        ProtonColor(name: "MobileInteractionStrong", vpnFallbackRgb: interactionStrongVpn)
    }
    public var InteractionStrongPressed: ProtonColor {
        ProtonColor(name: "MobileInteractionStrongPressed", vpnFallbackRgb: interactionStrongPressedVpn)
    }

    // MARK: Floaty
    public let FloatyBackground = ProtonColor(name: "MobileFloatyBackground")
    public let FloatyPressed = ProtonColor(name: "MobileFloatyPressed")
    public let FloatyText = ProtonColor(name: "MobileFloatyText")
    
    // MARK: Background
    public var BackgroundNorm: ProtonColor {
        ProtonColor(name: "MobileBackgroundNorm", vpnFallbackRgb: backgroundNormVpn)
    }
    public var BackgroundDeep: ProtonColor {
        ProtonColor(name: "MobileBackgroundDeep", vpnFallbackRgb: backgroundDeepVpn)
    }
    public var BackgroundSecondary: ProtonColor {
        ProtonColor(name: "MobileBackgroundSecondary", vpnFallbackRgb: backgroundSecondaryVpn)
    }

    // MARK: Separator
    public var SeparatorNorm: ProtonColor {
        ProtonColor(name: "MobileSeparatorNorm", vpnFallbackRgb: separatorNormVpn)
    }

    // MARK: Sidebar
    public var SidebarBackground: ProtonColor {
        ProtonColor(name: "MobileSidebarBackground", vpnFallbackRgb: sidebarBackgroundVpn)
    }
    public var SidebarInteractionWeakNorm: ProtonColor {
        ProtonColor(name: "MobileSidebarInteractionWeakNorm", vpnFallbackRgb: sidebarInteractionWeakNormVpn)
    }
    public var SidebarInteractionWeakPressed: ProtonColor {
        ProtonColor(name: "MobileSidebarInteractionWeakPressed", vpnFallbackRgb: sidebarInteractionWeakPressedVpn)
    }
    public var SidebarSeparator: ProtonColor {
        ProtonColor(name: "MobileSidebarSeparator", vpnFallbackRgb: sidebarSeparatorVpn)
    }
    public var SidebarTextNorm: ProtonColor {
        ProtonColor(name: "MobileSidebarTextNorm", vpnFallbackRgb: sidebarTextNormVpn)
    }
    public var SidebarTextWeak: ProtonColor {
        ProtonColor(name: "MobileSidebarTextWeak", vpnFallbackRgb: sidebarTextWeakVpn)
    }
    public var SidebarIconNorm: ProtonColor {
        ProtonColor(name: "MobileSidebarIconNorm", vpnFallbackRgb: sidebarIconNormVpn)
    }
    public var SidebarIconWeak: ProtonColor {
        ProtonColor(name: "MobileSidebarIconWeak", vpnFallbackRgb: sidebarIconWeakVpn)
    }
    public let SidebarInteractionPressed = ProtonColor(name: "MobileSidebarInteractionPressed")

    // MARK: Blenders
    public let BlenderNorm = ProtonColor(name: "MobileBlenderNorm")
    
    // MARK: Accent
    public let PurpleBase = ProtonColor(name: "SharedPurpleBase")
    public let EnzianBase = ProtonColor(name: "SharedEnzianBase")
    public let PinkBase = ProtonColor(name: "SharedPinkBase")
    public let PlumBase = ProtonColor(name: "SharedPlumBase")
    public let StrawberryBase = ProtonColor(name: "SharedStrawberryBase")
    public let CeriseBase = ProtonColor(name: "SharedCeriseBase")
    public let CarrotBase = ProtonColor(name: "SharedCarrotBase")
    public let CopperBase = ProtonColor(name: "SharedCopperBase")
    public let SaharaBase = ProtonColor(name: "SharedSaharaBase")
    public let SoilBase = ProtonColor(name: "SharedSoilBase")
    public let SlateblueBase = ProtonColor(name: "SharedSlateblueBase")
    public let CobaltBase = ProtonColor(name: "SharedCobaltBase")
    public let PacificBase = ProtonColor(name: "SharedPacificBase")
    public let OceanBase = ProtonColor(name: "SharedOceanBase")
    public let ReefBase = ProtonColor(name: "SharedReefBase")
    public let PineBase = ProtonColor(name: "SharedPineBase")
    public let FernBase = ProtonColor(name: "SharedFernBase")
    public let ForestBase = ProtonColor(name: "SharedForestBase")
    public let OliveBase = ProtonColor(name: "SharedOliveBase")
    public let PickleBase = ProtonColor(name: "SharedPickleBase")
    
    // MARK: Two special colors that consistently occur in designs even though they are not part af the palette
    public let White = ProtonColor(name: "White")
    public let Black = ProtonColor(name: "Black")
    
    // MARK: Special banner colors
    public let Ebb = ProtonColor(name: "Ebb")
    public let Cloud = ProtonColor(name: "Cloud")
}

// Two special global colors

extension ProtonColorPaletteiOS {
    private var balticSea: Int { 0x1C1B24 }
    private var bastille: Int { 0x292733 }
    private var steelGray: Int { 0x343140 }
    private var blackcurrant: Int { 0x3B3747 }
    private var gunPowder: Int { 0x4A4658 }
    private var smoky: Int { 0x5B576B }
    private var dolphin: Int { 0x6D697D }
    private var cadetBlue: Int { 0xA7A4B5 }
    private var cinder: Int { 0x0C0C14 }
    private var shipGray: Int { 0x35333D }
    private var doveGray: Int { 0x706D6B }
    private var dawn: Int { 0x999693 }
    private var cottonSeed: Int { 0xC2BFBC }
    private var cloud: Int { 0xD1CFCD }
    private var ebb: Int { 0xEAE7E4 }
    private var cararra: Int { 0xF5F4F2 }
    private var haiti: Int { 0x1B1340 }
    private var valhalla: Int { 0x271B54 }
    private var jacarta: Int { 0x2E2260 }
    private var pomegranate: Int { 0xCC2D4F }
    private var mauvelous: Int { 0xF08FA4 }
    private var sunglow: Int { 0xE65200 }
    private var texasRose: Int { 0xFFB84D }
    private var apple: Int { 0x007B58 }
    private var puertoRico: Int { 0x4AB89A }
    private var white: Int { 0xFFFFFF }
    private var pampas: Int { 0xF1EEEB }

    private var shade100Vpn: Int { white }
    private var shade80Vpn: Int { cadetBlue }
    private var shade60Vpn: Int { dolphin }
    private var shade50Vpn: Int { smoky }
    private var shade40Vpn: Int { gunPowder }
    private var shade20Vpn: Int { blackcurrant }
    private var shade15Vpn: Int { bastille }
    private var shade10Vpn: Int { balticSea }
    private var shade0Vpn: Int { cinder }
    private var textNormVpn: Int { shade100Vpn }
    private var textWeakVpn: Int { shade80Vpn }
    private var textHintVpn: Int { shade60Vpn }
    private var textDisabledVpn: Int { shade50Vpn }
    private var textInvertedVpn: Int { shade0Vpn }
    private var textAccentVpn: Int { 0x8A6EFF }
    private var iconNormVpn: Int { shade100Vpn }
    private var iconWeakVpn: Int { shade80Vpn }
    private var iconHintVpn: Int { shade60Vpn }
    private var iconDisabledVpn: Int { shade50Vpn }
    private var iconInvertedVpn: Int { shade0Vpn }
    private var iconAccentVpn: Int { 0x8A6EFF }
    private var interactionWeakVpn: Int { shade20Vpn }
    private var interactionWeakPressedVpn: Int { shade40Vpn }
    private var interactionWeakDisabledVpn: Int { shade10Vpn }
    private var interactionStrongVpn: Int { shade100Vpn }
    private var interactionStrongPressedVpn: Int { shade80Vpn }
    private var backgroundNormVpn: Int { shade10Vpn }
    private var backgroundDeepVpn: Int { shade0Vpn }
    private var backgroundSecondaryVpn: Int { shade15Vpn }
    private var separatorNormVpn: Int { shade20Vpn }
    private var notificationErrorVpn: Int { mauvelous }
    private var notificationWarningVpn: Int { texasRose }
    private var notificationSuccessVpn: Int { puertoRico }
    private var notificationNormVpn: Int { shade100Vpn }
    private var sidebarBackgroundVpn: Int { cinder }
    private var sidebarInteractionWeakNormVpn: Int { blackcurrant }
    private var sidebarInteractionWeakPressedVpn: Int { gunPowder }
    private var sidebarSeparatorVpn: Int { blackcurrant }
    private var sidebarTextNormVpn: Int { white }
    private var sidebarTextWeakVpn: Int { cadetBlue }
    private var sidebarIconNormVpn: Int { shade100Vpn }
    private var sidebarIconWeakVpn: Int { cadetBlue }
}
