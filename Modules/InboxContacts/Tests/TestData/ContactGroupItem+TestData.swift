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

@testable import InboxContacts

extension ContactGroupItem {
    static var advisorsGroup: Self {
        .init(
            id: 3,
            name: "Advisors Group: Comprehensive Wealth Management and Strategic Financial Solutions",
            avatarColor: "#A1FF33",
            contactEmails: [
                .init(id: 4, email: "group.advisor@pm.me", name: "Work"),
                .init(id: 5, email: "group.advisor@protonmail.com", name: "Main"),
                .init(id: 6, email: "advisor.group@yahoo.com", name: "Private"),
            ]
        )
    }

    static var businessGroup: Self {
        .init(
            id: 2,
            name: "Business Group",
            avatarColor: "#A1FF33",
            contactEmails: [
                .init(id: 21, email: "business.group@proton.me")
            ]
        )
    }
}
