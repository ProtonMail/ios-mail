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
import proton_app_uniffi

final class AppConfigService: Sendable {
    static let shared: AppConfigService = .init()

    let appConfig: AppConfig = {
        #if UITESTS
            let environment: ApiEnvId

            // The `mockServerPort` value is computed by the UI Tests runner at runtime,
            // it can't be read from project.yml as a static value as it would prevent concurrent runs.
            if let mockServerPort = UserDefaults.standard.string(forKey: "mockServerPort") {
                environment = .custom("https://localhost:\(mockServerPort)")
            } else {
                environment = .custom("https://proton.pink")
            }

            return AppConfig(environment: environment)
        #else
            return .default
        #endif
    }()
}
