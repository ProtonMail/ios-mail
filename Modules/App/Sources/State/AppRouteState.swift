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
import InboxCore
import proton_app_uniffi

@MainActor
final class AppRouteState: ObservableObject, Sendable {
    @Published private(set) var route: Route
    var onSelectedMailboxChange: AnyPublisher<SelectedMailbox, Never> {
        _route.projectedValue.map(\.selectedMailbox).dropFirst().eraseToAnyPublisher()
    }

    var openedMailboxItem: AnyPublisher<MailboxMessageSeed, Never> {
        _route.projectedValue
            .compactMap {
                switch $0 {
                case .mailbox, .composerFromShareExtension: nil
                case .mailboxOpenMessage(let seed): seed
                }
            }
            .eraseToAnyPublisher()
    }

    var openedDraft: AnyPublisher<DraftCreateMode, Never> {
        _route.projectedValue
            .compactMap {
                switch $0 {
                case .composerFromShareExtension: .fromIosShareExtension
                default: nil
                }
            }
            .eraseToAnyPublisher()
    }

    init(route: Route) {
        self.route = route
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
    case composerFromShareExtension

    var selectedMailbox: SelectedMailbox {
        switch self {
        case .mailbox(let selectedMailbox):
            selectedMailbox
        case .mailboxOpenMessage, .composerFromShareExtension:
            SelectedMailbox.inbox
        }
    }

    var description: String {
        switch self {
        case .mailbox(let label):
            "mailbox \(label.name.string)"
        case .mailboxOpenMessage:
            "mailboxOpenMessage"
        case .composerFromShareExtension:
            "composerFromShareExtension"
        }
    }
}
