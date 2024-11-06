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

struct ContactDeleterAdapter {
    private let mailUserSession: MailUserSession
    private let contactDeleter: ContactDeleter

    init(mailUserSession: MailUserSession, contactDeleter: ContactDeleter) {
        self.mailUserSession = mailUserSession
        self.contactDeleter = contactDeleter
    }

    func delete(contactID: Id) async throws {
        try await contactDeleter.delete(contactID, mailUserSession)
    }
}

struct ContactDeleter {
    let delete: (_ contactID: Id, _ session: MailUserSession) async throws -> Void
}

extension ContactDeleter {

    static func productionInstance() -> Self {
        .init(delete: { _, _ in }) // FIXME: Use RustSDK's implementation here
    }

}
