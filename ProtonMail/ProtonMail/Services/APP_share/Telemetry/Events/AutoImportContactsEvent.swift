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

extension TelemetryEvent {

    static func autoImportContacts(contactsToCreate: Int, contactsToUpdate: Int, skippedVCardDownloads: Int) -> Self {
        let values: [String: Float] = [
            "numberOfProtonContactsToCreate": Float(contactsToCreate),
            "numberOfProtonContactsToUpdate": Float(contactsToUpdate),
            "numberOfSkippedVCardDownloads": Float(skippedVCardDownloads)
        ]

        return .init(
            measurementGroup: "mail.ios.auto_import_contacts",
            name: "first_import",
            values: values,
            dimensions: [:],
            frequency: .always
        )
    }
}
