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
import Network
import ProtonCoreDoh

protocol CheckProtonServerStatusUseCase {
    func execute() async -> ServerStatus
}

enum ServerStatus {
    case serverUp
    case serverDown
    case unknown
}

final class CheckProtonServerStatus: CheckProtonServerStatusUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies = Dependencies()) {
        self.dependencies = dependencies
    }

    func execute() async -> ServerStatus {
        let isProtonPingSuccessful = await isPingSuccessful()
        let isInternetAvailable = dependencies.internetConnectionStatus.status.isConnected

        switch (isProtonPingSuccessful, isInternetAvailable) {
        case (true, _):
            return .serverUp
        case (false, true):
            return .serverDown
        case (false, false):
            return .unknown
        }
    }

    private func isPingSuccessful() async -> Bool {
        let request = PingRequestHelper.protonServer.urlRequest(doh: dependencies.doh)
        do {
            let response: URLResponse = try await dependencies.session.data(for: request).1
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            SystemLogger.log(error: error)
            return false
        }
    }
}

extension CheckProtonServerStatus {
    struct Dependencies {
        let session: URLSessionProtocol
        let doh: DoHInterface
        let internetConnectionStatus: InternetConnectionStatusProviderProtocol

        init(
            session: URLSessionProtocol = URLSession.shared,
            doh: DoHInterface = BackendConfiguration.shared.doh,
            internetConnectionStatus: InternetConnectionStatusProviderProtocol = InternetConnectionStatusProvider.shared
        ) {
            self.session = session
            self.doh = doh
            self.internetConnectionStatus = internetConnectionStatus
        }
    }
}
