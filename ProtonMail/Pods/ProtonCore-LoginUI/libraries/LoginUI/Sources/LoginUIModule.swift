//
//  LoginUIModule.swift
//  ProtonCore-Login - Created on 08/05/2024.
//
//  Copyright (c) 2024 Proton AG
//
//  This file is part of Proton AG and ProtonCore.
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


#if os(iOS)

import Foundation
import ProtonCoreDataModel
import ProtonCoreServices
import SwiftUI

public enum LoginUIModule {
    /// Resource bundle for the LoginUI module
    public static var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        let resourceBundle = Bundle.module
        return resourceBundle
        #else
        let podBundle = Bundle(for: LoginUIClass.self)
        if let bundleURL = podBundle.url(forResource: "Resources-LoginUI", withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                return bundle
            }
        }
        return podBundle
        #endif
    }

    public static func makeSecurityKeysViewController(apiService: APIService, clientApp: ClientApp) -> SecurityKeysViewController {
        return SecurityKeysViewController(apiService: apiService, clientApp: clientApp)
    }
}

#endif

private class LoginUIClass {}
