// Copyright (c) 2025 Proton Technologies AG
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

import Network
import proton_app_uniffi

@MainActor
final class NetworkMonitoringService: ApplicationServiceSetUp {
    private let mailSession: () -> MailSessionProtocol
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")

    init(mailSession: @escaping () -> MailSessionProtocol) {
        self.mailSession = mailSession
    }

    func setUpService() {
        startMonitoring()
    }

    private func startMonitoring() {
        let mailSession = mailSession()

        monitor.pathUpdateHandler = { [weak mailSession] path in
            mailSession?.updateOsNetworkStatus(osNetworkStatus: path.status.uniffiEquivalent)
        }

        monitor.start(queue: queue)
    }
}

private extension NWPath.Status {
    var uniffiEquivalent: OsNetworkStatus {
        switch self {
        case .satisfied: .online
        case .unsatisfied, .requiresConnection: .offline
        @unknown default: .offline
        }
    }
}
