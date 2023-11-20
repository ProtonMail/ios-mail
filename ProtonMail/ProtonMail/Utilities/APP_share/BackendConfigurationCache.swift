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
import ProtonCoreEnvironment

// sourcery: mock
protocol BackendConfigurationCacheProtocol {
    func readEnvironment() -> Environment?
}

struct BackendConfigurationCache: BackendConfigurationCacheProtocol {
    private let userDefaults: UserDefaults

    enum Key: String {
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
}

/// Extension to help store the environment to UserDefaults. Once Encodable in Core conforms
/// to Codable, this extension should be removed.
private extension Environment {
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
