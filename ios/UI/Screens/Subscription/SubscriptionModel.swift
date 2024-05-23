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

final class SubscriptionModel: @unchecked Sendable, ObservableObject {
    @Published private(set) var state: State
    private let domain: String = "proton.me"
    private let dependencies: Dependencies

    init(dependencies: Dependencies = .init()) {
        self.state = .forkingSession
        self.dependencies = dependencies
    }

    func generateSubscriptionUrl() {
        guard let activeUser = dependencies.appContext.activeUserSession else { return }
        Task {
            await updateState(.forkingSession)
            do {
                let selectorToken = try await activeUser.fork()
                await updateState(.urlReady(url: subscriptionUrl(domain: domain, selector: selectorToken)))
            } catch {
                AppLogger.log(error: error)
                await updateState(.error(error))
            }
        }
    }

    func pollEvents() {
        dependencies.appContext.pollEvents()
    }

    @MainActor
    private func updateState(_ newState: State) {
        state = newState
    }

    private func subscriptionUrl(domain: String, selector: String) -> URL {
        URL(string:"https://account.\(domain)/lite?action=subscription-details#selector=\(selector)")!
    }
}

extension SubscriptionModel {

    enum State {
        case forkingSession
        case urlReady(url: URL)
        case error(Error)
    }
}

extension SubscriptionModel {

    struct Dependencies {
        let appContext: AppContext

        init(appContext: AppContext = .shared) {
            self.appContext = appContext
        }
    }
}
