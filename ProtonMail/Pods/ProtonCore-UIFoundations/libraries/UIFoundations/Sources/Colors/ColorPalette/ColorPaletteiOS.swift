//
//  ColorPalette.swift
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

public protocol ColorPaletteiOS<T> {
    associatedtype T
    static var instance: T { get }

    // MARK: MobileBrand
    var BrandNorm: ProtonColor { get }
    var BrandDarken10: ProtonColor { get }
    var BrandDarken20: ProtonColor { get }
    var BrandDarken30: ProtonColor { get }
    var BrandDarken40: ProtonColor { get }
    var BrandLighten10: ProtonColor { get }
    var BrandLighten20: ProtonColor { get }
    var BrandLighten30: ProtonColor { get }
    var BrandLighten40: ProtonColor { get }

    // MARK: Notification
    var NotificationError: ProtonColor { get }
    var NotificationWarning: ProtonColor { get }
    var NotificationSuccess: ProtonColor { get }
    var NotificationNorm: ProtonColor { get }

    // MARK: Interaction norm
    var InteractionNorm: ProtonColor { get }
    var InteractionNormPressed: ProtonColor { get }
    var InteractionNormDisabled: ProtonColor { get }
    var InteractionNormMajor1PassTheme: ProtonColor { get }
    var InteractionNormMajor2PassTheme: ProtonColor { get }

    // MARK: Shade
    var Shade100: ProtonColor { get }
    var Shade80: ProtonColor { get }
    var Shade60: ProtonColor { get }
    var Shade50: ProtonColor { get }
    var Shade40: ProtonColor { get }
    var Shade20: ProtonColor { get }
    var Shade15: ProtonColor { get }
    var Shade10: ProtonColor { get }
    var Shade0: ProtonColor { get }

    // MARK: Text
    var TextNorm: ProtonColor { get }
    var TextWeak: ProtonColor { get }
    var TextHint: ProtonColor { get }
    var TextDisabled: ProtonColor { get }
    var TextInverted: ProtonColor { get }
    var TextAccent: ProtonColor { get }

    // MARK: Icon
    var IconNorm: ProtonColor { get }
    var IconWeak: ProtonColor { get }
    var IconHint: ProtonColor { get }
    var IconDisabled: ProtonColor { get }
    var IconInverted: ProtonColor { get }
    var IconAccent: ProtonColor { get }

    // MARK: Interaction
    var InteractionWeak: ProtonColor { get }
    var InteractionWeakPressed: ProtonColor { get }
    var InteractionWeakDisabled: ProtonColor { get }
    var InteractionStrong: ProtonColor { get }
    var InteractionStrongPressed: ProtonColor { get }

    // MARK: Floaty
    var FloatyBackground: ProtonColor { get }
    var FloatyPressed: ProtonColor { get }
    var FloatyText: ProtonColor { get }

    // MARK: Background
    var BackgroundNorm: ProtonColor { get }
    var BackgroundDeep: ProtonColor { get }
    var BackgroundSecondary: ProtonColor { get }

    // MARK: Separator
    var SeparatorNorm: ProtonColor { get }
    var SeparatorStrong: ProtonColor { get }

    // MARK: Sidebar
    var SidebarBackground: ProtonColor { get }
    var SidebarInteractionWeakNorm: ProtonColor { get }
    var SidebarInteractionWeakPressed: ProtonColor { get }
    var SidebarSeparator: ProtonColor { get }
    var SidebarTextNorm: ProtonColor { get }
    var SidebarTextWeak: ProtonColor { get }
    var SidebarIconNorm: ProtonColor { get }
    var SidebarIconWeak: ProtonColor { get }
    var SidebarInteractionPressed: ProtonColor { get }
    var SidebarInteractionSelected: ProtonColor { get }
    var SidebarInteractionAlternative: ProtonColor { get }

    // MARK: Blenders
    var BlenderNorm: ProtonColor { get }

    // MARK: Accent
    var PurpleBase: ProtonColor { get }
    var EnzianBase: ProtonColor { get }
    var PinkBase: ProtonColor { get }
    var PlumBase: ProtonColor { get }
    var StrawberryBase: ProtonColor { get }
    var CeriseBase: ProtonColor { get }
    var CarrotBase: ProtonColor { get }
    var CopperBase: ProtonColor { get }
    var SaharaBase: ProtonColor { get }
    var SoilBase: ProtonColor { get }
    var SlateblueBase: ProtonColor { get }
    var CobaltBase: ProtonColor { get }
    var PacificBase: ProtonColor { get }
    var OceanBase: ProtonColor { get }
    var ReefBase: ProtonColor { get }
    var PineBase: ProtonColor { get }
    var FernBase: ProtonColor { get }
    var ForestBase: ProtonColor { get }
    var OliveBase: ProtonColor { get }
    var PickleBase: ProtonColor { get }

    // MARK: Two special colors that consistently occur in designs even though they are not part af the palette
    var White: ProtonColor { get }
    var Black: ProtonColor { get }

    // MARK: Special banner colors
    var Ebb: ProtonColor { get }
    var Cloud: ProtonColor { get }
}

public extension ColorPaletteiOS {
    // MARK: Default colors

    // MARK: MobileBrand
    var BrandNorm: ProtonColor { ProtonColor(name: "MobileBrandNorm") }
    var BrandDarken10: ProtonColor { ProtonColor(name: "MoodyBlue") }
    var BrandDarken20: ProtonColor { ProtonColor(name: "MobileBrandDarken20") }
    var BrandDarken30: ProtonColor { ProtonColor(name: "Meteorite") }
    var BrandDarken40: ProtonColor { ProtonColor(name: "MobileBrandDarken40") }
    var BrandLighten10: ProtonColor { ProtonColor(name: "LavenderMist") }
    var BrandLighten20: ProtonColor { ProtonColor(name: "MobileBrandLighten20") }
    var BrandLighten30: ProtonColor { ProtonColor(name: "TitanWhite") }
    var BrandLighten40: ProtonColor { ProtonColor(name: "MobileBrandLighten40") }

    // MARK: Notification
    var NotificationError: ProtonColor { ProtonColor(name: "MobileNotificationError", vpnFallbackRgb: notificationErrorVpn) }
    var NotificationWarning: ProtonColor { ProtonColor(name: "MobileNotificationWarning", vpnFallbackRgb: notificationWarningVpn) }
    var NotificationSuccess: ProtonColor { ProtonColor(name: "MobileNotificationSuccess", vpnFallbackRgb: notificationSuccessVpn) }
    var NotificationNorm: ProtonColor { ProtonColor(name: "MobileNotificationNorm", vpnFallbackRgb: notificationNormVpn) }

    // MARK: Interaction norm
    var InteractionNorm: ProtonColor { ProtonColor(name: "MobileInteractionNorm") }
    var InteractionNormPressed: ProtonColor { ProtonColor(name: "MobileInteractionNormPressed") }
    var InteractionNormDisabled: ProtonColor { ProtonColor(name: "MobileInteractionNormDisabled") }
    var InteractionNormMajor1PassTheme: ProtonColor { ProtonColor(name: "MobileInteractionNormMajor1PassTheme") }
    var InteractionNormMajor2PassTheme: ProtonColor { ProtonColor(name: "MobileInteractionNormMajor2PassTheme") }

    // MARK: Shade
    var Shade100: ProtonColor { ProtonColor(name: "MobileShade100", vpnFallbackRgb: shade100Vpn) }
    var Shade80: ProtonColor { ProtonColor(name: "MobileShade80", vpnFallbackRgb: shade80Vpn) }
    var Shade60: ProtonColor { ProtonColor(name: "MobileShade60", vpnFallbackRgb: shade60Vpn) }
    var Shade50: ProtonColor { ProtonColor(name: "MobileShade50", vpnFallbackRgb: shade50Vpn) }
    var Shade40: ProtonColor { ProtonColor(name: "MobileShade40", vpnFallbackRgb: shade40Vpn) }
    var Shade20: ProtonColor { ProtonColor(name: "MobileShade20", vpnFallbackRgb: shade20Vpn) }
    var Shade15: ProtonColor { ProtonColor(name: "MobileShade15", vpnFallbackRgb: shade15Vpn) }
    var Shade10: ProtonColor { ProtonColor(name: "MobileShade10", vpnFallbackRgb: shade10Vpn) }
    var Shade0: ProtonColor { ProtonColor(name: "MobileShade0", vpnFallbackRgb: shade0Vpn) }

    // MARK: Text
    var TextNorm: ProtonColor { ProtonColor(name: "MobileTextNorm", vpnFallbackRgb: textNormVpn) }
    var TextWeak: ProtonColor { ProtonColor(name: "MobileTextWeak", vpnFallbackRgb: textWeakVpn) }
    var TextHint: ProtonColor { ProtonColor(name: "MobileTextHint", vpnFallbackRgb: textHintVpn) }
    var TextDisabled: ProtonColor { ProtonColor(name: "MobileTextDisabled", vpnFallbackRgb: textDisabledVpn) }
    var TextInverted: ProtonColor { ProtonColor(name: "MobileTextInverted", vpnFallbackRgb: textInvertedVpn) }
    var TextAccent: ProtonColor { ProtonColor(name: "MobileTextAccent", vpnFallbackRgb: textAccentVpn) }

    // MARK: Icon
    var IconNorm: ProtonColor { ProtonColor(name: "MobileIconNorm", vpnFallbackRgb: iconNormVpn) }
    var IconWeak: ProtonColor { ProtonColor(name: "MobileIconWeak", vpnFallbackRgb: iconWeakVpn) }
    var IconHint: ProtonColor { ProtonColor(name: "MobileIconHint", vpnFallbackRgb: iconHintVpn) }
    var IconDisabled: ProtonColor { ProtonColor(name: "MobileIconDisabled", vpnFallbackRgb: iconDisabledVpn) }
    var IconInverted: ProtonColor { ProtonColor(name: "MobileIconInverted", vpnFallbackRgb: iconInvertedVpn) }
    var IconAccent: ProtonColor { ProtonColor(name: "MobileIconAccent", vpnFallbackRgb: iconAccentVpn) }

    // MARK: Interaction
    var InteractionWeak: ProtonColor { ProtonColor(name: "MobileInteractionWeak", vpnFallbackRgb: interactionWeakVpn) }
    var InteractionWeakPressed: ProtonColor { ProtonColor(name: "MobileInteractionWeakPressed", vpnFallbackRgb: interactionWeakPressedVpn) }
    var InteractionWeakDisabled: ProtonColor { ProtonColor(name: "MobileInteractionWeakDisabled", vpnFallbackRgb: interactionWeakDisabledVpn) }
    var InteractionStrong: ProtonColor { ProtonColor(name: "MobileInteractionStrong", vpnFallbackRgb: interactionStrongVpn) }
    var InteractionStrongPressed: ProtonColor { ProtonColor(name: "MobileInteractionStrongPressed", vpnFallbackRgb: interactionStrongPressedVpn) }

    // MARK: Floaty
    var FloatyBackground: ProtonColor { ProtonColor(name: "MobileFloatyBackground") }
    var FloatyPressed: ProtonColor { ProtonColor(name: "MobileFloatyPressed") }
    var FloatyText: ProtonColor { ProtonColor(name: "MobileFloatyText") }

    // MARK: Background
    var BackgroundNorm: ProtonColor {
        switch Brand.currentBrand {
        case .proton, .vpn, .wallet:
            return ProtonColor(name: "MobileBackgroundNorm", vpnFallbackRgb: backgroundNormVpn)
        case .pass:
            return ProtonColor(name: "MobileBackgroundNormPassTheme", vpnFallbackRgb: backgroundNormVpn)
        }
    }
    var BackgroundDeep: ProtonColor { ProtonColor(name: "MobileBackgroundDeep", vpnFallbackRgb: backgroundDeepVpn) }
    var BackgroundSecondary: ProtonColor { ProtonColor(name: "MobileBackgroundSecondary", vpnFallbackRgb: backgroundSecondaryVpn) }

    // MARK: Separator
    var SeparatorNorm: ProtonColor { ProtonColor(name: "MobileSeparatorNorm", vpnFallbackRgb: separatorNormVpn) }
    var SeparatorStrong: ProtonColor { ProtonColor(name: "Mercury") }

    // MARK: Sidebar
    var SidebarBackground: ProtonColor { ProtonColor(name: "MobileSidebarBackground", vpnFallbackRgb: sidebarBackgroundVpn) }
    var SidebarInteractionWeakNorm: ProtonColor { ProtonColor(name: "MobileSidebarInteractionWeakNorm", vpnFallbackRgb: sidebarInteractionWeakNormVpn) }
    var SidebarInteractionWeakPressed: ProtonColor { ProtonColor(name: "MobileSidebarInteractionWeakPressed", vpnFallbackRgb: sidebarInteractionWeakPressedVpn) }
    var SidebarSeparator: ProtonColor { ProtonColor(name: "MobileSidebarSeparator", vpnFallbackRgb: sidebarSeparatorVpn) }
    var SidebarTextNorm: ProtonColor { ProtonColor(name: "MobileSidebarTextNorm", vpnFallbackRgb: sidebarTextNormVpn) }
    var SidebarTextWeak: ProtonColor { ProtonColor(name: "MobileSidebarTextWeak", vpnFallbackRgb: sidebarTextWeakVpn) }
    var SidebarIconNorm: ProtonColor { ProtonColor(name: "MobileSidebarIconNorm", vpnFallbackRgb: sidebarIconNormVpn) }
    var SidebarIconWeak: ProtonColor { ProtonColor(name: "MobileSidebarIconWeak", vpnFallbackRgb: sidebarIconWeakVpn) }
    var SidebarInteractionPressed: ProtonColor { ProtonColor(name: "MobileSidebarInteractionPressed") }

    var SidebarInteractionSelected: ProtonColor { ProtonColor(name: "DreamyBlue") }
    var SidebarInteractionAlternative: ProtonColor { ProtonColor(name: "TexasRose") }

    // MARK: Blenders
    var BlenderNorm: ProtonColor { ProtonColor(name: "MobileBlenderNorm") }
}

public extension ColorPaletteiOS {
    // MARK: Accent
    var PurpleBase: ProtonColor { ProtonColor(name: "SharedPurpleBase") }
    var EnzianBase: ProtonColor { ProtonColor(name: "SharedEnzianBase") }
    var PinkBase: ProtonColor { ProtonColor(name: "SharedPinkBase") }
    var PlumBase: ProtonColor { ProtonColor(name: "SharedPlumBase") }
    var StrawberryBase: ProtonColor { ProtonColor(name: "SharedStrawberryBase") }
    var CeriseBase: ProtonColor { ProtonColor(name: "SharedCeriseBase") }
    var CarrotBase: ProtonColor { ProtonColor(name: "SharedCarrotBase") }
    var CopperBase: ProtonColor { ProtonColor(name: "SharedCopperBase") }
    var SaharaBase: ProtonColor { ProtonColor(name: "SharedSaharaBase") }
    var SoilBase: ProtonColor { ProtonColor(name: "SharedSoilBase") }
    var SlateblueBase: ProtonColor { ProtonColor(name: "SharedSlateblueBase") }
    var CobaltBase: ProtonColor { ProtonColor(name: "SharedCobaltBase") }
    var PacificBase: ProtonColor { ProtonColor(name: "SharedPacificBase") }
    var OceanBase: ProtonColor { ProtonColor(name: "SharedOceanBase") }
    var ReefBase: ProtonColor { ProtonColor(name: "SharedReefBase") }
    var PineBase: ProtonColor { ProtonColor(name: "SharedPineBase") }
    var FernBase: ProtonColor { ProtonColor(name: "SharedFernBase") }
    var ForestBase: ProtonColor { ProtonColor(name: "SharedForestBase") }
    var OliveBase: ProtonColor { ProtonColor(name: "SharedOliveBase") }
    var PickleBase: ProtonColor { ProtonColor(name: "SharedPickleBase") }

    // MARK: Two special colors that consistently occur in designs even though they are not part af the palette
    var White: ProtonColor { ProtonColor(name: "White") }
    var Black: ProtonColor { ProtonColor(name: "Black") }

    // MARK: Special banner colors
    var Ebb: ProtonColor { ProtonColor(name: "Ebb") }
    var Cloud: ProtonColor { ProtonColor(name: "Cloud") }
}

extension ColorPaletteiOS {
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
