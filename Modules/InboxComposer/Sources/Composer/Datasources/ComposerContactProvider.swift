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
import InboxContacts
import proton_app_uniffi

public final class ComposerContactProvider {
    typealias FilterResult = (text: String, matchingContacts: [ComposerContact])

    let protonContactsDatasource: ComposerContactsDatasource
    private(set) var contacts: [ComposerContact] = []
    private var task: Task<Void, Never>?

    init(protonContactsDatasource: ComposerContactsDatasource) {
        self.protonContactsDatasource = protonContactsDatasource
    }

    func loadContacts() async {
        contacts = await protonContactsDatasource.allContacts()
    }

    /**
     Returns the filtered contacts that match the `text` input.

     If this functions is called multiple times in a short interval, any ongoing task will be cancelled and
     only the latest one will finish. Only finished tasks will call the `completion` block.
     */
    func filter(with text: String, completion: @escaping (FilterResult) -> Void) {
        task?.cancel()
        task = Task {
            let textForMatching = text.toContactMatchFormat()
            var matchingContacts = [ComposerContact]()

            for contact in contacts {
                guard !Task.isCancelled else { return }
                let isMatch = contact.toMatch.contains { elementToMatch in elementToMatch.contains(textForMatching) }
                if isMatch {
                    matchingContacts.append(contact)
                }
            }
            guard !Task.isCancelled else { return }
            completion((text: text, matchingContacts: matchingContacts))
        }
    }
}

public extension ComposerContactProvider {

    static var mockInstance: ComposerContactProvider {
        .init(protonContactsDatasource: ComposerMockContactsDatasource())
    }

    static func productionInstance(mailUserSession: MailUserSession) -> ComposerContactProvider {
        let protonContactsProvider = ComposerProtonContactsDatasource(
            mailUserSession: mailUserSession,
            contactsProvider: .productionInstance()
        )
        return .init(protonContactsDatasource: protonContactsProvider)
    }
}
