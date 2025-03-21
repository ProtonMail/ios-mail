// Copyright (c) 2024 Proton Technologies AG
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
import proton_app_uniffi

public struct AppConfig: Sendable {
    public let appVersion: String
    public let environment: Environment

    public struct Environment: Sendable {
        public let domain: String
        public let apiBaseUrl: String
        public let userAgent: String
        public let isSrpProofSkipped: Bool
        public let isHttpAllowed: Bool

        public init(domain: String, apiBaseUrl: String, userAgent: String, isSrpProofSkipped: Bool, isHttpAllowed: Bool) {
            self.domain = domain
            self.apiBaseUrl = apiBaseUrl
            self.userAgent = userAgent
            self.isSrpProofSkipped = isSrpProofSkipped
            self.isHttpAllowed = isHttpAllowed
        }
    }

    public init(appVersion: String, environment: Environment) {
        self.appVersion = appVersion
        self.environment = environment
    }
}

public extension AppConfig {

    static let `default`: Self = {
        let domain = Bundle.main.infoDictionary?["PMApiHost"] as? String ?? "proton.me"
        let appVersion = "ios-mail@\(Bundle.main.effectiveAppVersion)"
        let environment = AppConfig.Environment(
            domain: domain,
            apiBaseUrl: "https://mail-api.\(domain)",
            userAgent: "Mozilla/5.0",
            isSrpProofSkipped: false,
            isHttpAllowed: false
        )

        return .init(appVersion: appVersion, environment: environment)
    }()

    var apiEnvConfig: ApiConfig {
        let environment = self.environment

        // FIXME: muon removed arguments to config for UI tests!
//        return ApiConfig(
//            allowHttp: environment.isHttpAllowed, 
//            appVersion: appVersion,
//            baseUrl: environment.apiBaseUrl,
//            skipSrpProofValidation: environment.isSrpProofSkipped, 
//            userAgent: environment.userAgent
//        )
        return ApiConfig(appVersion: appVersion, userAgent: environment.userAgent, envId: .prod)
    }
}
