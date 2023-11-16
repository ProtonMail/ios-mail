//
//  Networking+Translations.swift
//  ProtonCore-Networking - Created on 01.08.23.
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation
import ProtonCoreUtilities

private class Handler {}

public enum NWTranslation: TranslationsExposing {

    public static var bundle: Bundle {
        #if SPM
        return Bundle.module
        #else
        return Bundle(path: Bundle(for: Handler.self).path(forResource: "Translations-Networking", ofType: "bundle")!)!
        #endif
    }

    public static var prefixForMissingValue: String = ""

    case connection_error
    case insecure_connection_error

    public var l10n: String {
        switch self {
        case .connection_error:
            return localized(key: "Network connection error", comment: "Networking connection error")
        case .insecure_connection_error:
            return localized(key: "The TLS certificate validation failed when trying to connect to the Proton API. Your current Internet connection may be monitored. To keep your data secure, we are preventing the app from accessing the Proton API.\nTo log in or access your account, switch to a new network and try to connect again.", comment: "Networking insecure connection error")
        }
    }
}
