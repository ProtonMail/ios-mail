//
//  ProtonColorPallete.swift
//  ProtonCore-UIFoundations - Created on 04.11.20.
//
//  Copyright (c) 2020 Proton Technologies AG
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

public struct ProtonColorPallete {
    static let instance = ProtonColorPallete()
    public static var brand: Brand = .proton

    private init() {}

    // MARK: Brand
    public var BrandDarken40: ProtonColor {
        switch ProtonColorPallete.brand {
        case .proton: return ProtonColor(name: "BrandDarken40")
        case .vpn: return ProtonColor(name: "BrandDarken40Vpn")
        }
    }
    public var BrandDarken20: ProtonColor {
        switch ProtonColorPallete.brand {
        case .proton: return ProtonColor(name: "BrandDarken20")
        case .vpn: return ProtonColor(name: "BrandDarken20Vpn")
        }
    }
    public var BrandNorm: ProtonColor {
        switch ProtonColorPallete.brand {
        case .proton: return ProtonColor(name: "BrandNorm")
        case .vpn: return ProtonColor(name: "BrandNormVpn")
        }
    }
    public var BrandLighten20: ProtonColor {
        switch ProtonColorPallete.brand {
        case .proton: return ProtonColor(name: "BrandLighten20")
        case .vpn: return ProtonColor(name: "BrandLighten20Vpn")
        }
    }
    public var BrandLighten40: ProtonColor {
        switch ProtonColorPallete.brand {
        case .proton: return ProtonColor(name: "BrandLighten40")
        case .vpn: return ProtonColor(name: "BrandLighten40Vpn")
        }
    }

    // MARK: Notification
    public let NotificationError = ProtonColor(name: "NotificationError")
    public let NotificationWarning = ProtonColor(name: "NotificationWarning")
    public let NotificationSuccess = ProtonColor(name: "NotificationSuccess")
    public var NotificationNorm: ProtonColor {
        ProtonColor(name: "NotificationNorm", vpnFallbackRgb: notificationNormVpn)
    }

    // MARK: Interaction norm
    public var InteractionNorm: ProtonColor {
        switch ProtonColorPallete.brand {
        case .proton: return ProtonColor(name: "InteractionNorm")
        case .vpn: return ProtonColor(name: "InteractionNormVpn")
        }
    }
    public var InteractionNormPressed: ProtonColor {
        switch ProtonColorPallete.brand {
        case .proton: return ProtonColor(name: "InteractionNormPressed")
        case .vpn: return ProtonColor(name: "InteractionNormPressedVpn")
        }
    }
    public var InteractionNormDisabled: ProtonColor {
        switch ProtonColorPallete.brand {
        case .proton: return ProtonColor(name: "InteractionNormDisabled")
        case .vpn: return ProtonColor(name: "InteractionNormDisabledVpn")
        }
    }
    
    // MARK: Shade
    public var Shade100: ProtonColor {
        ProtonColor(name: "Shade100", vpnFallbackRgb: shade100Vpn)
    }
    public var Shade80: ProtonColor {
        ProtonColor(name: "Shade80", vpnFallbackRgb: shade80Vpn)
    }
    public var Shade60: ProtonColor {
        ProtonColor(name: "Shade60", vpnFallbackRgb: shade60Vpn)
    }
    public var Shade50: ProtonColor {
        ProtonColor(name: "Shade50", vpnFallbackRgb: shade50Vpn)
    }
    public var Shade40: ProtonColor {
        ProtonColor(name: "Shade40", vpnFallbackRgb: shade40Vpn)
    }
    public var Shade20: ProtonColor {
        ProtonColor(name: "Shade20", vpnFallbackRgb: shade20Vpn)
    }
    public var Shade10: ProtonColor {
        ProtonColor(name: "Shade10", vpnFallbackRgb: shade10Vpn)
    }
    public var Shade0: ProtonColor {
        ProtonColor(name: "Shade0", vpnFallbackRgb: shade0Vpn)
    }

    // MARK: Text
    public var TextNorm: ProtonColor {
        ProtonColor(name: "TextNorm", vpnFallbackRgb: textNormVpn)
    }
    public var TextWeak: ProtonColor {
        ProtonColor(name: "TextWeak", vpnFallbackRgb: textWeakVpn)
    }
    public var TextHint: ProtonColor {
        ProtonColor(name: "TextHint", vpnFallbackRgb: textHintVpn)
    }
    public var TextDisabled: ProtonColor {
        ProtonColor(name: "TextDisabled", vpnFallbackRgb: textDisabledVpn)
    }
    public var TextInverted: ProtonColor {
        ProtonColor(name: "TextInverted", vpnFallbackRgb: textInvertedVpn)
    }

    // MARK: Icon
    public var IconNorm: ProtonColor {
        ProtonColor(name: "IconNorm", vpnFallbackRgb: iconNormVpn)
    }
    public var IconWeak: ProtonColor {
        ProtonColor(name: "IconWeak", vpnFallbackRgb: iconWeakVpn)
    }
    public var IconHint: ProtonColor {
        ProtonColor(name: "IconHint", vpnFallbackRgb: iconHintVpn)
    }
    public var IconDisabled: ProtonColor {
        ProtonColor(name: "IconDisabled", vpnFallbackRgb: iconDisabledVpn)
    }
    public var IconInverted: ProtonColor {
        ProtonColor(name: "IconInverted", vpnFallbackRgb: iconInvertedVpn)
    }
    
    // MARK: Interaction
    public var InteractionWeak: ProtonColor {
        ProtonColor(name: "InteractionWeak", vpnFallbackRgb: interactionWeakVpn)
    }
    public var InteractionWeakPressed: ProtonColor {
        ProtonColor(name: "InteractionWeakPressed", vpnFallbackRgb: interactionWeakPressedVpn)
    }
    public var InteractionWeakDisabled: ProtonColor {
        ProtonColor(name: "InteractionWeakDisabled", vpnFallbackRgb: interactionWeakDisabledVpn)
    }
    public var InteractionStrong: ProtonColor {
        ProtonColor(name: "InteractionStrong", vpnFallbackRgb: interactionStrongVpn)
    }
    public var InteractionStrongPressed: ProtonColor {
        ProtonColor(name: "InteractionStrongPressed", vpnFallbackRgb: interactionStrongPressedVpn)
    }

    // MARK: Floaty
    public let FloatyBackground = ProtonColor(name: "FloatyBackground")
    public let FloatyPressed = ProtonColor(name: "FloatyPressed")
    public let FloatyText = ProtonColor(name: "FloatyText")
    
    // MARK: Background
    public var BackgroundNorm: ProtonColor {
        ProtonColor(name: "BackgroundNorm", vpnFallbackRgb: backgroundNormVpn)
    }
    public var BackgroundSecondary: ProtonColor {
        ProtonColor(name: "BackgroundSecondary", vpnFallbackRgb: backgroundSecondaryVpn)
    }

    // MARK: Separator
    public var SeparatorNorm: ProtonColor {
        ProtonColor(name: "SeparatorNorm", vpnFallbackRgb: separatorNormVpn)
    }

    // MARK: Sidebar
    public var SidebarBackground: ProtonColor {
        ProtonColor(name: "SidebarBackground", vpnFallbackRgb: sidebarBackgroundVpn)
    }
    public var SidebarInteractionWeakNorm: ProtonColor {
        ProtonColor(name: "SidebarInteractionWeakNorm", vpnFallbackRgb: sidebarInteractionWeakNormVpn)
    }
    public var SidebarInteractionWeakPressed: ProtonColor {
        ProtonColor(name: "SidebarInteractionWeakPressed", vpnFallbackRgb: sidebarInteractionWeakPressedVpn)
    }
    public var SidebarSeparator: ProtonColor {
        ProtonColor(name: "SidebarSeparator", vpnFallbackRgb: sidebarSeparatorVpn)
    }
    public let SidebarTextNorm = ProtonColor(name: "SidebarTextNorm")
    public let SidebarTextWeak = ProtonColor(name: "SidebarTextWeak")
    public let SidebarIconNorm = ProtonColor(name: "SidebarIconNorm")
    public let SidebarIconWeak = ProtonColor(name: "SidebarIconWeak")
    public let SidebarInteractionPressed = ProtonColor(name: "SidebarInteractionPressed")

    // MARK: Blenders
    public let BlenderNorm = ProtonColor(name: "BlenderNorm")
}

extension ProtonColorPallete {
    private var woodsmoke: Int { 0x17181C }
    private var charade: Int { 0x25272C }
    private var tuna: Int { 0x303239 }
    private var abbey: Int { 0x494D55 }
    private var stormGray: Int { 0x727680 }
    private var santasGray: Int { 0x9CA0AA }
    private var portGore: Int { 0x1C223D }
    private var pickledBluewood: Int { 0x29304D }
    private var rhino: Int { 0x353E60 }
    private var frenchGray: Int { 0xBABDC6 }
    private var mischka: Int { 0xDADCE3 }
    private var athensGray: Int { 0xEAECF1 }
    private var whisper: Int { 0xF5F6FA }
    private var white: Int { 0xFFFFFF }
    
    private var shade100Vpn: Int { white }
    private var shade80Vpn: Int { santasGray }
    private var shade60Vpn: Int { stormGray }
    private var shade50Vpn: Int { abbey }
    private var shade40Vpn: Int { abbey }
    private var shade20Vpn: Int { tuna }
    private var shade10Vpn: Int { charade }
    private var shade0Vpn: Int { woodsmoke }
    private var textNormVpn: Int { shade100Vpn }
    private var textWeakVpn: Int { shade80Vpn }
    private var textHintVpn: Int { shade60Vpn }
    private var textDisabledVpn: Int { shade50Vpn }
    private var textInvertedVpn: Int { shade0Vpn }
    private var iconNormVpn: Int { shade100Vpn }
    private var iconWeakVpn: Int { shade80Vpn }
    private var iconHintVpn: Int { shade60Vpn }
    private var iconDisabledVpn: Int { shade50Vpn }
    private var iconInvertedVpn: Int { shade0Vpn }
    private var interactionWeakVpn: Int { shade20Vpn }
    private var interactionWeakPressedVpn: Int { shade40Vpn }
    private var interactionWeakDisabledVpn: Int { shade10Vpn }
    private var interactionStrongVpn: Int { shade100Vpn }
    private var interactionStrongPressedVpn: Int { shade80Vpn }
    private var backgroundNormVpn: Int { shade0Vpn }
    private var backgroundSecondaryVpn: Int { shade10Vpn }
    private var separatorNormVpn: Int { shade20Vpn }
    private var notificationNormVpn: Int { shade100Vpn }
    private var sidebarBackgroundVpn: Int { woodsmoke }
    private var sidebarInteractionWeakNormVpn: Int { tuna }
    private var sidebarInteractionWeakPressedVpn: Int { abbey }
    private var sidebarSeparatorVpn: Int { tuna }
}

#if canImport(UIKit)

// MARK: Internal core colors

extension ProtonColorPallete {
    
    // MARK: Global
    static var White: UIColor {
        UIColor(rgb: ProtonColorPallete().white)
    }

    // MARK: Splash
    enum Splash {
        static var Background: UIColor {
            switch brand {
            case .proton:
                // LIGHT mode: White, DARK mode: Port Gore
                return UIColor.dynamic(light: ProtonColorPallete.White, dark: UIColor(rgb: ProtonColorPallete().portGore))
            case .vpn:
                // Woodsmoke
                return UIColor(rgb: ProtonColorPallete().woodsmoke)
            }
        }

        static var TextNorm: UIColor {
            switch brand {
            case .proton:
                // LIGHT mode: Woodsmoke, DARK mode: White
                return UIColor.dynamic(light: UIColor(rgb: ProtonColorPallete().woodsmoke), dark: ProtonColorPallete.White)
            case .vpn:
                // LIGHT, DARK mode: White
                return ProtonColorPallete.White
            }
        }

        static var TextHint: UIColor {
            switch brand {
            case .proton:
                return ColorProvider.TextHint
            case .vpn:
                // Storm Gray
                return UIColor(rgb: ProtonColorPallete().stormGray)
            }
        }
    }
}
#endif
