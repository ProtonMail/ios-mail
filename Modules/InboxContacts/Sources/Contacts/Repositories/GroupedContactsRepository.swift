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

public protocol GroupedContactsProviding {
    func allContacts() async -> [GroupedContacts]
}

public struct GroupedContactsRepository: GroupedContactsProviding {
    private let mailUserSession: MailUserSession
    private let allContacts: (_ userSession: MailUserSession) async throws -> [GroupedContacts]

    public init(
        mailUserSession: MailUserSession,
        allContacts: @escaping (_ userSession: MailUserSession) async throws -> [GroupedContacts]
    ) {
        self.mailUserSession = mailUserSession
        self.allContacts = allContacts
    }

    // MARK: - GroupedContactsProviding

    public func allContacts() async -> [GroupedContacts] {
        try! await allContacts(mailUserSession)
    }
}
