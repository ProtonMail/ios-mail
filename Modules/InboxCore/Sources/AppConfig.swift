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
    public let environment: ApiEnvId

    public init(environment: ApiEnvId) {
        self.environment = environment
    }
}

public extension AppConfig {

    static let `default`: Self = {
        return .init(environment: .prod)
    }()

    var apiEnvConfig: ApiConfig {
        let appVersion = "ios-mail@\(Bundle.main.effectiveAppVersion)"
        return .init(appVersion: appVersion, userAgent: "Mozilla/5.0", envId: environment, proxy: nil)
    }
}

public extension ApiEnvId {
    static func localhost(port: String) -> Self {
        .custom("http://localhost:\(port)")
    }
}
