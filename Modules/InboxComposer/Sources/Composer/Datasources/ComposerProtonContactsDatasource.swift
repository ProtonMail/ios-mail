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

import InboxContacts
import InboxCoreUI
import proton_app_uniffi
import UIKit
import SwiftUI

struct ComposerContactsResult {
    let contacts: [ComposerContact]
    let filter: (String) -> [ComposerContact]
}

struct ComposerProtonContactsDatasource: ComposerContactsDatasource {
    let repository: ContactSuggestionsRepository

    func allContacts() async -> ComposerContactsResult {
        guard let suggestions = await repository.allContacts() else {
            return .init(contacts: [], filter: { _ in [] })
        }

        return ComposerContactsResult(
            contacts: suggestions.all().compactMap(\.toComposerContact),
            filter: { query in suggestions.filtered(query: query).compactMap(\.toComposerContact) }
        )
    }
}

private extension ContactSuggestion {

    var toComposerContact: ComposerContact? {
        switch kind {
        case .contactGroup(let contacts):
            return composerContact(type: .group(.init(name: name, totalMembers: contacts.count)))
        case .contact(let emailItem):
            return single(email: emailItem.email)
        case .deviceContact(let deviceItem):
            return single(email: deviceItem.email)
        }
    }

    private func single(email: String) -> ComposerContact {
        composerContact(type: .single(.init(initials: avatarInformation.text, name: name, email: email)))
    }

    private func composerContact(type: ComposerContactType) -> ComposerContact {
        .init(id: key, type: type, avatarColor: Color(UIColor(hex: avatarInformation.color)))
    }

}
