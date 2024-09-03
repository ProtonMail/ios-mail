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

import Combine
import Foundation

@MainActor
final class AppRouteState: ObservableObject, Sendable {
    @Published private(set) var route: Route
    var onSelectedMailboxChange: AnyPublisher<SelectedMailbox, Never> {
        selectedMailbox.eraseToAnyPublisher()
    }
    private let selectedMailbox: PassthroughSubject<SelectedMailbox, Never> = .init()
    private var cancellables = Set<AnyCancellable>()

    init(route: Route) {
        self.route = route

        $route
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRoute in
                if let newSelectedMailbox = newRoute.selectedMailbox {
                    self?.selectedMailbox.send(newSelectedMailbox)
                }
            }
            .store(in: &cancellables)
    }

    func updateRoute(to newRoute: Route) {
        AppLogger.log(message: "new app route [\(newRoute)]", category: .appRoute)
        route = newRoute
    }
}

extension AppRouteState {

    static var initialState: Self {
        .init(route: .mailbox(selectedMailbox: .inbox))
    }

}

enum Route: Equatable, CustomStringConvertible {
    case mailbox(selectedMailbox: SelectedMailbox)
    case mailboxOpenMessage(seed: MailboxMessageSeed)

    /// Determines if the route has a selected mailbox with inbox instead of a local label
    var isInboxHardcoded: Bool {
        switch selectedMailbox {
        case .inbox:
            return true
        case .none, .label:
            return false
        }
    }

    var selectedMailbox: SelectedMailbox? {
        if case .mailbox(let selectedMailbox) = self {
            return selectedMailbox
        }
        return nil
    }

    var description: String {
        switch self {
        case .mailbox(let label):
            "mailbox \(label.name.string)"
        case .mailboxOpenMessage:
            "mailboxOpenMessage"
        }
    }
}
