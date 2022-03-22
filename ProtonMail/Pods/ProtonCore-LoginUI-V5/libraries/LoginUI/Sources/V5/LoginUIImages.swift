//
//  LoginUIImages.swift
//  ProtonCore-LoginUI - Created on 11/03/2022.
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

import ProtonCore_UIFoundations
import ProtonCore_DataModel

enum LoginUIImages {
    
    static var brandIconForProton: UIImage? {
        nil
    }
    
    static var brandIconForVPN: UIImage? {
        nil
    }
    
    static var summaryImage: UIImage? {
        nil
    }
    
    static var summaryWhole: UIImage? {
        IconProvider.summary
    }
    
    static var brandLogo: UIImage? {
        IconProvider.masterBrandGlyph
    }
    
    static var animationFile: String {
        "sign-up-create-account-V5"
    }
    
    static func welcomeAnimationFile(variant: WelcomeScreenVariant) -> String {
        switch variant {
        case .mail, .custom: return "welcome_animation_mail"
        case .vpn: return "welcome_animation_vpn"
        case .calendar: return "welcome_animation_calendar"
        case .drive: return "welcome_animation_drive"
        }
    }
}

public extension SignupParameters {
    
    init(separateDomainsButton: Bool = true,
         passwordRestrictions: SignupPasswordRestrictions,
         summaryScreenVariant: SummaryScreenVariant) {
        self.init(separateDomainsButton, passwordRestrictions, summaryScreenVariant)
    }
}
