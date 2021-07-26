//
//  PMColors.swift
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

import SwiftUI

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension ColorManager {

	// MARK: Global
    private static let Chambray = Color("Chambray", bundle: PMUIFoundations.bundle)
    private static let SanMarino = Color("SanMarino", bundle: PMUIFoundations.bundle)
    private static let CornflowerBlue = Color("CornflowerBlue", bundle: PMUIFoundations.bundle)
    private static let Portage = Color("Portage", bundle: PMUIFoundations.bundle)
    private static let Perano = Color("Perano", bundle: PMUIFoundations.bundle)

    private static let GreenPea = Color("GreenPea", bundle: PMUIFoundations.bundle)
    private static let Goblin = Color("Goblin", bundle: PMUIFoundations.bundle)
    private static let FruitSalad = Color("FruitSalad", bundle: PMUIFoundations.bundle)
    private static let Mantis = Color("Mantis", bundle: PMUIFoundations.bundle)
    private static let Fern = Color("Fern", bundle: PMUIFoundations.bundle)

    private static let Woodsmoke = Color("Woodsmoke", bundle: PMUIFoundations.bundle)
    private static let Charade = Color("Charade", bundle: PMUIFoundations.bundle)
    private static let Tuna = Color("Tuna", bundle: PMUIFoundations.bundle)
    private static let Abbey = Color("Abbey", bundle: PMUIFoundations.bundle)
    private static let StormGray = Color("StormGray", bundle: PMUIFoundations.bundle)
    private static let SantasGray = Color("SantasGray", bundle: PMUIFoundations.bundle)

    private static let FrenchGray = Color("FrenchGray", bundle: PMUIFoundations.bundle)
    private static let Mischka = Color("Mischka", bundle: PMUIFoundations.bundle)
    private static let AthensGray = Color("AthensGray", bundle: PMUIFoundations.bundle)
    private static let Whisper = Color("Whisper", bundle: PMUIFoundations.bundle)
    private static let White = Color("White", bundle: PMUIFoundations.bundle)

    private static let Pomegranate = Color("Pomegranate", bundle: PMUIFoundations.bundle)
    private static let Sunglow = Color("Sunglow", bundle: PMUIFoundations.bundle)
    private static let Apple = Color("Apple", bundle: PMUIFoundations.bundle)

    // MARK: Brand
    public static var BrandDarken40: Color {
        switch brand {
        case .proton: return Chambray
        case .vpn: return GreenPea
        }
    }
    public static var BrandDarken20: Color {
        switch brand {
        case .proton: return SanMarino
        case .vpn: return Goblin
        }
    }
    public static var BrandNorm: Color {
        switch brand {
        case .proton: return CornflowerBlue
        case .vpn: return FruitSalad
        }
    }
    public static var BrandLighten20: Color {
        switch brand {
        case .proton: return Portage
        case .vpn: return Mantis
        }
    }
    public static var BrandLighten40: Color {
        switch brand {
        case .proton: return Perano
        case .vpn: return Fern
        }
    }

    // MARK: Notification
    public static let NotificationError = Pomegranate
    public static let NotificationWarning = Sunglow
    public static let NotificationSuccess = Apple

    // MARK: Interaction
    public static let InteractionNorm = BrandNorm
    public static let InteractionNormPressed = BrandDarken20
    public static let InteractionNormDisabled = BrandLighten40

    // MARK: Shade
    public static let Shade100 = Color(UIColor.dynamic(light: UIColor(named: "Woodsmoke", in: PMUIFoundations.bundle, compatibleWith: nil)!, dark: UIColor(named: "White", in: PMUIFoundations.bundle, compatibleWith: nil)!))
    public static let Shade80 = Color(UIColor.dynamic(light: UIColor(named: "StormGray", in: PMUIFoundations.bundle, compatibleWith: nil)!, dark: UIColor(named: "SantasGray", in: PMUIFoundations.bundle, compatibleWith: nil)!))
    public static let Shade60 = Color(UIColor.dynamic(light: UIColor(named: "SantasGray", in: PMUIFoundations.bundle, compatibleWith: nil)!, dark: UIColor(named: "StormGray", in: PMUIFoundations.bundle, compatibleWith: nil)!))
    public static let Shade50 = Color(UIColor.dynamic(light: UIColor(named: "FrenchGray", in: PMUIFoundations.bundle, compatibleWith: nil)!, dark: UIColor(named: "Abbey", in: PMUIFoundations.bundle, compatibleWith: nil)!))
    public static let Shade40 = Color(UIColor.dynamic(light: UIColor(named: "Mischka", in: PMUIFoundations.bundle, compatibleWith: nil)!, dark: UIColor(named: "Abbey", in: PMUIFoundations.bundle, compatibleWith: nil)!))
    public static let Shade20 = Color(UIColor.dynamic(light: UIColor(named: "AthensGray", in: PMUIFoundations.bundle, compatibleWith: nil)!, dark: UIColor(named: "Tuna", in: PMUIFoundations.bundle, compatibleWith: nil)!))
    public static let Shade10 = Color(UIColor.dynamic(light: UIColor(named: "Whisper", in: PMUIFoundations.bundle, compatibleWith: nil)!, dark: UIColor(named: "Charade", in: PMUIFoundations.bundle, compatibleWith: nil)!))
    public static let Shade0 = Color(UIColor.dynamic(light: UIColor(named: "White", in: PMUIFoundations.bundle, compatibleWith: nil)!, dark: UIColor(named: "Woodsmoke", in: PMUIFoundations.bundle, compatibleWith: nil)!))

    // MARK: Text
    public static let TextNorm = Shade100
    public static let TextWeak = Shade80
    public static let TextHint = Shade60
    public static let TextDisabled = Shade50
    public static let TextInverted = Shade0

    // MARK: Icon
    public static let IconNorm = Shade100
    public static let IconWeak = Shade80
    public static let IconHint = Shade60
    public static let IconDisabled = Shade50
    public static let IconInverted = Shade0

    // MARK: Interaction
    public static let InteractionWeak = Shade20
    public static let InteractionWeakPressed = Shade40
    public static let InteractionWeakDisabled = Shade10
    public static let InteractionStrong = Shade100
    public static let InteractionStrongPressed = Shade80

    // MARK: Background
    public static let BackgroundNorm = Shade0
    public static let BackgroundSecondary = Shade10

    // MARK: Separator
    public static let SeparatorNorm = Shade20

	// MARK: Blenders
	public static let BlenderNorm = Color("BlenderNorm", bundle: PMUIFoundations.bundle)
}
