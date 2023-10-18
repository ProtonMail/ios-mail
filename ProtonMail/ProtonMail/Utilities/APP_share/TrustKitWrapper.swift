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

import ProtonCoreEnvironment
import ProtonCoreServices
import TrustKit

extension TrustKitWrapper {
    // Prefer this over `setUp`, this covers `PMAPIService` configuration
    static func start(delegate: TrustKitUIDelegate, hardfail: Bool = true) {
        silenceTrustKitOutput()
        setUp(delegate: delegate, customConfiguration: Environment.pinningConfigs(hardfail: hardfail))
        PMAPIService.trustKit = current
    }

    private static func silenceTrustKitOutput() {
        TrustKit.setLoggerBlock { message in
            if message.range(of: "Error", options: .caseInsensitive) != nil {
                SystemLogger.log(message: message, isError: true)
            }
        }
    }
}
