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

struct ComposerProtonContactsDatasource: ComposerContactsDatasource {
    let mailUserSession: MailUserSession
    let contactsProvider: GroupedContactsProvider

    func allContacts() async -> [ComposerContact] {
        switch await contactsProvider.allContacts(mailUserSession) {
        case .ok(let groupedContacts):
            let composerContacts = groupedContacts.flatMap { group in
                group.item.flatMap { item in
                    switch item {
                    case .contact(let single):
                        return single.toComposerContacts()

                    case .group(let group):
                        return [group.toComposerContact()]
                    }
                }
            }
            return composerContacts
        case .error(let error):
            // AppLogger. // FIXME: move logger to InboxCore
            return []
        }
    }
}

private extension ContactItem {

    func toComposerContacts() -> [ComposerContact] {
        emails.map { emailItem in
            let contact = ComposerContactSingle(
                initials: avatarInformation.text,
                name: name,
                email: emailItem.email
            )
            return ComposerContact(
                type: .single(contact),
                avatarColor: Color(UIColor(hex: avatarInformation.color))
            )
        }
    }
}

private extension ContactGroupItem {

    func toComposerContact() -> ComposerContact {
        return ComposerContact(
            type: .group(.init(name: name, totalMembers: emails.count)),
            avatarColor: Color(UIColor(hex: avatarColor))
        )
    }
}
