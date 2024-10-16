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

import proton_app_uniffi

struct GroupedContacts: Hashable, Identifiable {
    let groupedBy: String
    let contacts: [ContactType]

    // MARK: - Identifiable

    var id: String {
        groupedBy
    }
}

struct ContactEmailItem: Hashable {
    let id: UInt64
    let email: String
}

struct ContactGroupItem: Hashable, Identifiable {
    let id: UInt64
    let name: String
    let avatarColor: String
    let emails: [ContactEmailItem]
}

struct ContactItem: Hashable, Identifiable {
    let id: UInt64
    let name: String
    let avatarInformation: AvatarInformation
    let emails: [ContactEmailItem]
}

enum ContactType: Hashable, Identifiable {
    case contact(ContactItem)
    case group(ContactGroupItem)

    // MARK: - Identifiable

    var id: UInt64 {
        switch self {
        case .contact(let contactItem):
            return contactItem.id
        case .group(let contactGroupItem):
            return contactGroupItem.id
        }
    }
}
