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

struct AppConfig: Sendable {
    let appVersion: String
    let environment: Environment
    
    struct Environment {
        let domain: String
        let apiBaseUrl: String
        let userAgent: String
        let isSrpProofSkipped: Bool
        let isHttpAllowed: Bool
    }
}

extension AppConfig {

    var apiEnvConfig: ApiConfig {
        let environment = self.environment

        return .init(
            appVersion: appVersion,
            userAgent: environment.userAgent
        )

//        return ApiConfig(
//            allowHttp: environment.isHttpAllowed, 
//            appVersion: appVersion,
//            baseUrl: environment.apiBaseUrl,
//            skipSrpProofValidation: environment.isSrpProofSkipped, 
//            userAgent: environment.userAgent
//        )
    }
}
