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
    public let Shade100 = ProtonColor(name: "Shade100")
    public let Shade80 = ProtonColor(name: "Shade80")
    public let Shade60 = ProtonColor(name: "Shade60")
    public let Shade50 = ProtonColor(name: "Shade50")
    public let Shade40 = ProtonColor(name: "Shade40")
    public let Shade20 = ProtonColor(name: "Shade20")
    public let Shade10 = ProtonColor(name: "Shade10")
    public let Shade0 = ProtonColor(name: "Shade0")

    // MARK: Text
    public let TextNorm = ProtonColor(name: "TextNorm")
    public let TextWeak = ProtonColor(name: "TextWeak")
    public let TextHint = ProtonColor(name: "TextHint")
    public let TextDisabled = ProtonColor(name: "TextDisabled")
    public let TextInverted = ProtonColor(name: "TextInverted")

    // MARK: Icon
    public let IconNorm = ProtonColor(name: "IconNorm")
    public let IconWeak = ProtonColor(name: "IconWeak")
    public let IconHint = ProtonColor(name: "IconHint")
    public let IconDisabled = ProtonColor(name: "IconDisabled")
    public let IconInverted = ProtonColor(name: "IconInverted")
    
    // MARK: Interaction
    public let InteractionWeak = ProtonColor(name: "InteractionWeak")
    public let InteractionWeakPressed = ProtonColor(name: "InteractionWeakPressed")
    public let InteractionWeakDisabled = ProtonColor(name: "InteractionWeakDisabled")
    public let InteractionStrong = ProtonColor(name: "InteractionStrong")
    public let InteractionStrongPressed = ProtonColor(name: "InteractionStrongPressed")

    // MARK: Floaty
    public let FloatyBackground = ProtonColor(name: "FloatyBackground")
    public let FloatyPressed = ProtonColor(name: "FloatyPressed")
    public let FloatyText = ProtonColor(name: "FloatyText")
    
    // MARK: Background
    public let BackgroundNorm = ProtonColor(name: "BackgroundNorm")
    public let BackgroundSecondary = ProtonColor(name: "BackgroundSecondary")

    // MARK: Separator
    public let SeparatorNorm = ProtonColor(name: "SeparatorNorm")

    // MARK: Sidebar
    public let SidebarBackground = ProtonColor(name: "SidebarBackground")
    public let SidebarBackgroundAccount = ProtonColor(name: "SidebarBackgroundAccount")
    public let SidebarPressed = ProtonColor(name: "SidebarPressed")
    public let SidebarSeparator = ProtonColor(name: "SidebarSeparator")
    public let SidebarTextNorm = ProtonColor(name: "SidebarTextNorm")
    public let SidebarTextWeak = ProtonColor(name: "SidebarTextWeak")

    // MARK: Blenders
    public let BlenderNorm = ProtonColor(name: "BlenderNorm")
}

#if canImport(UIKit)

// MARK: Internal core colors

extension ProtonColorPallete {
    
    // MARK: Global
    static var White: UIColor {
        UIColor(rgb: 0xffffff)
    }

    // MARK: Splash
    enum Splash {
        static var Background: UIColor {
            switch brand {
            case .proton:
                // LIGHT mode: White, DARK mode: Port Gore
                return UIColor.dynamic(light: ProtonColorPallete.White, dark: UIColor(rgb: 0x1C223D))
            case .vpn:
                // Woodsmoke
                return UIColor(rgb: 0x17181C)
            }
        }

        static var TextNorm: UIColor {
            switch brand {
            case .proton:
                // LIGHT mode: Woodsmoke, DARK mode: White
                return UIColor.dynamic(light: UIColor(rgb: 0x17181C), dark: ProtonColorPallete.White)
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
                return UIColor(rgb: 0x727680)
            }
        }
    }
}
#endif
