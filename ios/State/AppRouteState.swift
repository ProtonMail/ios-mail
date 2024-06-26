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
    static let shared = AppRouteState(route: .appLaunching)

    @Published private(set) var route: Route
    var selectedMailbox: AnyPublisher<SelectedMailbox, Never> {
        _selectedMailbox.eraseToAnyPublisher()
    }
    private let _selectedMailbox: PassthroughSubject<SelectedMailbox, Never> = .init()
    private var cancellables = Set<AnyCancellable>()

    init(route: Route) {
        self.route = route

        $route
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRoute in
                if let newSelectedMailbox = newRoute.selectedMailbox {
                    self?._selectedMailbox.send(newSelectedMailbox)
                }
            }
            .store(in: &cancellables)
    }

    func updateRoute(to newRoute: Route) {
        AppLogger.log(message: "new app route [\(newRoute)]", category: .appRoute)
        route = newRoute
    }
}

enum Route: Equatable, CustomStringConvertible {
    case appLaunching
    case mailbox(label: SelectedMailbox)
    case mailboxOpenMessage(seed: MailboxMessageSeed)
    case settings
    case subscription

    var selectedMailbox: SelectedMailbox? {
        if case .mailbox(let label) = self {
            return label
        }
        return nil
    }

    var localLabelId: PMLocalLabelId? {
        if case .mailbox(let label) = self {
            return label.localId
        }
        return nil
    }

    var description: String {
        switch self {
        case .appLaunching:
            "appLaunching"
        case .mailbox(let label):
            "mailbox \(label.name)"
        case .settings:
            "settings"
        case .subscription:
            "subscription"
        case .mailboxOpenMessage:
            "openMailboxItem"
        }
    }
}
