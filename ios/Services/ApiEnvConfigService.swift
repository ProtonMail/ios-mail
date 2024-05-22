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
import proton_mail_uniffi

final class ApiEnvConfigService: Sendable {
    static let shared: ApiEnvConfigService = .init()
    private var apiEnvConfig: ApiEnvConfig? = nil
    
    func getConfiguration() -> ApiEnvConfig? {
        apiEnvConfig
    }
}

#if !UITESTS
extension ApiEnvConfigService: ApplicationServiceSetUp {
    func setUpService() {}
}
#endif

#if UITESTS
extension ApiEnvConfigService: ApplicationServiceSetUp {
    
    func setUpService() {
        setupMockServerIfNecessary()
    }
    
    private func setupMockServerIfNecessary() {
        if let serverPort = UserDefaults.standard.string(forKey: "mockServerPort") {
            apiEnvConfig = ApiEnvConfig(
                appVersion: "ios-mail@0.0.1",
                baseUrl: "http://localhost:\(serverPort)",
                userAgent: "Mozilla/5.0",
                allowHttp: true,
                skipSrpProofValidation: true
            )
        }
    }
}
#endif
