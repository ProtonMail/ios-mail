//
//  ForceUpgrade+Translations.swift
//  ProtonCore-ForceUpgrade - Created on 01/08/23.
//
//  Copyright (c) 2023 Proton Technologies AG
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
import ProtonCoreUtilities

private class Handler {}

public enum FUTranslation: TranslationsExposing {
    
    public static var bundle: Bundle {
        #if SPM
        return Bundle.module
        #else
        return Bundle(path: Bundle(for: Handler.self).path(forResource: "Translations-ForceUpgrade", ofType: "bundle")!)!
        #endif
    }
    
    public static var prefixForMissingValue: String = ""
    
    case alert_title
    case alert_learn_more_button
    case alert_update_button
    case alert_quit_button
    
    public var l10n: String {
        switch self {
        case .alert_title:
            return localized(key: "Update required", comment: "alert title")
        case .alert_learn_more_button:
            return localized(key: "Learn more", comment: "learn more button")
        case .alert_update_button:
            return localized(key: "Update", comment: "update button")
        case .alert_quit_button:
            return localized(key: "Quit", comment: "quit button")
        }
    }
}
