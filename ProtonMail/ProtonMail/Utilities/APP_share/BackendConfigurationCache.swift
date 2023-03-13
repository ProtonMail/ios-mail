// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCore_Environment

// sourcery: mock
protocol BackendConfigurationCacheProtocol {
    func readEnvironment() -> Environment?
    func write(environment: Environment)
}

struct BackendConfigurationCache: BackendConfigurationCacheProtocol {
    private let userDefaults: UserDefaults

    private enum Key: String {
        case environment
        case environmentCustomDomain
    }

    // swiftlint:disable:next force_unwrapping
    init(userDefaults: UserDefaults = UserDefaults(suiteName: Constants.AppGroup)!) {
        self.userDefaults = userDefaults
    }

    func readEnvironment() -> Environment? {
        guard let environment = userDefaults.string(forKey: Key.environment.rawValue) else { return nil }
        let customDomain = userDefaults.string(forKey: Key.environmentCustomDomain.rawValue)
        return Environment(caseValue: environment, customDomain: customDomain)
    }

    func write(environment: Environment) {
        userDefaults.setValue(environment.caseValue, forKey: Key.environment.rawValue)
        userDefaults.setValue(environment.customDomain, forKey: Key.environmentCustomDomain.rawValue)
    }
}

/// Extension to help store the environment to UserDefaults. Once Encodable in Core conforms
/// to Codable, this extension should be removed.
private extension Environment {

    var caseValue: String {
        switch self {
        case .mailProd:
            return "mailProd"
        case .vpnProd:
            return "vpnProd"
        case .driveProd:
            return "driveProd"
        case .calendarProd:
            return "calendarProd"
        case .black:
            return "black"
        case .blackPayment:
            return "blackPayment"
        case .custom:
            return "custom"
        }
    }

    var customDomain: String? {
        switch self {
        case .mailProd, .vpnProd, .driveProd, .calendarProd, .black, .blackPayment:
            return nil
        case .custom(let customDomain):
            return customDomain
        }
    }

    init?(caseValue: String, customDomain: String?) {
        if caseValue == "custom", let customDomain = customDomain {
            self = .custom(customDomain)
        } else {
            // we only take into account meaningful environments for Mail
            switch caseValue {
            case "mailProd":
                self = .mailProd
            case "black":
                self = .black
            case "blackPayment":
                self = .blackPayment
            default:
                return nil
            }
        }
    }
}
