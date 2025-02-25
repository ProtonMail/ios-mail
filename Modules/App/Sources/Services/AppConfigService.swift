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
import InboxCore

final class AppConfigService: Sendable {
    static let shared: AppConfigService = .init()

    let appConfig: AppConfig = {
#if UITESTS
        let appVersion = "Other"
        let environment: AppConfig.Environment

        // The `mockServerPort` value is computed by the UI Tests runner at runtime,
        // it can't be read from project.yml as a static value as it would prevent concurrent runs.
        if let mockServerPort = UserDefaults.standard.string(forKey: "mockServerPort") {
            let domain = "localhost:\(mockServerPort)"
            environment = AppConfig.Environment(
                domain: domain,
                apiBaseUrl: "http://\(domain)",
                userAgent: "Mozilla/5.0",
                isSrpProofSkipped: true,
                isHttpAllowed: true
            )
        } else {
            let domain = "proton.black"
            environment = AppConfig.Environment(
                domain: domain,
                apiBaseUrl: "https://mail-api.\(domain)",
                userAgent: "Mozilla/5.0",
                isSrpProofSkipped: false,
                isHttpAllowed: false
            )
        }

        return AppConfig(appVersion: appVersion, environment: environment)
#else
        let domain = Bundle.main.infoDictionary?["PMApiHost"] as? String ?? "proton.me"
        let appVersion = "ios-mail@7.0.0" // Read from config once "ios-mail@x.y.z" is supported.
        let environment = AppConfig.Environment(
            domain: domain,
            apiBaseUrl: "https://mail-api.\(domain)",
            userAgent: "Mozilla/5.0",
            isSrpProofSkipped: false,
            isHttpAllowed: false
        )

        return AppConfig(appVersion: appVersion, environment: environment)
#endif
    }()
}
