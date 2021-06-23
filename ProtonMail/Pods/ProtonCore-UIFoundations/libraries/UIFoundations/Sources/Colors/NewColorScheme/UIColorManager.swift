//
//  PMColors.swift
//  ProtonMail - Created on 04.11.20.
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
//

import UIKit

@available(iOS 11.0, *)
extension UIColorManager {

	// MARK: Global
	private static let Chambray = UIColor(named: "Chambray", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let SanMarino = UIColor(named: "SanMarino", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let CornflowerBlue = UIColor(named: "CornflowerBlue", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let Portage = UIColor(named: "Portage", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let Perano = UIColor(named: "Perano", in: PMUIFoundations.bundle, compatibleWith: nil)!

    private static let GreenPea = UIColor(named: "GreenPea", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let Goblin = UIColor(named: "Goblin", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let FruitSalad = UIColor(named: "FruitSalad", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let Mantis = UIColor(named: "Mantis", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let Fern = UIColor(named: "Fern", in: PMUIFoundations.bundle, compatibleWith: nil)!

    public static let Woodsmoke = UIColor(named: "Woodsmoke", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let Charade = UIColor(named: "Charade", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let Tuna = UIColor(named: "Tuna", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let Abbey = UIColor(named: "Abbey", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let StormGray = UIColor(named: "StormGray", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let SantasGray = UIColor(named: "SantasGray", in: PMUIFoundations.bundle, compatibleWith: nil)!

    private static let FrenchGray = UIColor(named: "FrenchGray", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let Mischka = UIColor(named: "Mischka", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let AthensGray = UIColor(named: "AthensGray", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let Whisper = UIColor(named: "Whisper", in: PMUIFoundations.bundle, compatibleWith: nil)!
    public static let White = UIColor(named: "White", in: PMUIFoundations.bundle, compatibleWith: nil)!

    private static let Pomegranate = UIColor(named: "Pomegranate", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let Sunglow = UIColor(named: "Sunglow", in: PMUIFoundations.bundle, compatibleWith: nil)!
    private static let Apple = UIColor(named: "Apple", in: PMUIFoundations.bundle, compatibleWith: nil)!

    // MARK: Brand
    public static var BrandDarken40: UIColor {
        switch brand {
        case .proton: return Chambray
        case .vpn: return GreenPea
        }
    }
    public static var BrandDarken20: UIColor {
        switch brand {
        case .proton: return SanMarino
        case .vpn: return Goblin
        }
    }
    public static var BrandNorm: UIColor {
        switch brand {
        case .proton: return CornflowerBlue
        case .vpn: return FruitSalad
        }
    }
    public static var BrandLighten20: UIColor {
        switch brand {
        case .proton: return Portage
        case .vpn: return Mantis
        }
    }
    public static var BrandLighten40: UIColor {
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
    public static let Shade100 = UIColor.dynamic(light: Woodsmoke, dark: White)
    public static let Shade80 = UIColor.dynamic(light: StormGray, dark: SantasGray)
    public static let Shade60 = UIColor.dynamic(light: SantasGray, dark: StormGray)
    public static let Shade50 = UIColor.dynamic(light: FrenchGray, dark: Abbey)
    public static let Shade40 = UIColor.dynamic(light: Mischka, dark: Abbey)
    public static let Shade20 = UIColor.dynamic(light: AthensGray, dark: Tuna)
    public static let Shade10 = UIColor.dynamic(light: Whisper, dark: Charade)
    public static let Shade0 = UIColor.dynamic(light: White, dark: Woodsmoke)

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

    // MARK: Background
    public enum Splash {
        public static var Background: UIColor {
            switch brand {
            case .proton:
                return UIColor(named: "SplashBackgroundColorForProton", in: PMUIFoundations.bundle, compatibleWith: nil)!
            case .vpn:
                return UIColor(named: "SplashBackgroundColorForVPN", in: PMUIFoundations.bundle, compatibleWith: nil)!
            }
        }

        public static var TextNorm: UIColor {
            switch brand {
            case .proton:
                return UIColor(named: "SplashTextNormForProton", in: PMUIFoundations.bundle, compatibleWith: nil)!
            case .vpn:
                return UIColor(named: "SplashTextNormForVPN", in: PMUIFoundations.bundle, compatibleWith: nil)!
            }
        }

        public static var TextHint: UIColor {
            switch brand {
            case .proton:
                return UIColor(named: "SplashTextHintForProton", in: PMUIFoundations.bundle, compatibleWith: nil)!
            case .vpn:
                return UIColor(named: "SplashTextHintForVPN", in: PMUIFoundations.bundle, compatibleWith: nil)!
            }
        }
    }

    // MARK: Separator
    public static let SeparatorNorm = Shade20

	// MARK: Blenders
	public static let BlenderNorm = UIColor(named: "BlenderNorm", in: PMUIFoundations.bundle, compatibleWith: nil)!

    // MARK: Floaty
    public static let FloatyBackground = Tuna
    public static let FloatyPressed = Woodsmoke
    public static let FloatyText = White
}
