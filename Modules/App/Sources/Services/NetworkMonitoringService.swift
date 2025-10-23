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

import Combine
import Network

@MainActor
final class NetworkMonitoringService: ApplicationServiceSetUp {
    static let shared = NetworkMonitoringService()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")

    private let isConnectedSubject: CurrentValueSubject<Bool?, Never> = .init(nil)

    /// Emits events when the status changes. Only returns `nil` before we receive
    /// the first connection status value from the system.
    var isConnected: AnyPublisher<Bool?, Never> {
        isConnectedSubject.removeDuplicates().eraseToAnyPublisher()
    }

    func setUpService() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            Task { @MainActor in
                self?.isConnectedSubject.value = isConnected
            }
        }
        monitor.start(queue: queue)
    }
}
