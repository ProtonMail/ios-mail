// Copyright (c) 2023 Proton Technologies AG
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

/// Abstraction of the native `CNContact`
struct DeviceContact {
    let identifier: DeviceContactIdentifier
    let fullName: String?
    let vCard: String
}

/// Attributes used to identify a contact when trying to match Proton contacts
struct DeviceContactIdentifier {
    /**
     Identifier used by a contact in the Contacts app. Use this value for queries in
     the native `Contacts` framework.

     This value comes from the `CNContact` object. As per when writing this code, there is no
     globally unique identifier (`CNContact.id` is documented as globally unique but
     it's not cross device and actually has the same value as `CNContact.identifier`) .
     */
    let uuidInDevice: String
    let emails: [String]

    /**
     Identifier computed to get the uuid used for Proton contacts. Use this
     value to query Proton contacts.

     The value looks like: "protonmail-ios-autoimport-0323ACF3-22EA-4167-9A25-2BFA1CBC3764"
     */
    var uuidNormalisedForAutoImport: String {
        // this prefix documents where the contact was originated from
        let autoImportContactPrefix = "protonmail-ios-autoimport-"
        // It's not clear when ":ABPerson" appears as a suffix in the UUID value of a device contact. However
        // we remove it to sanitise the UUID to remove any unexpected value.
        let sanitisedUUID: String = uuidInDevice.replacingOccurrences(of: ":ABPerson", with: "")
        return autoImportContactPrefix.appending(sanitisedUUID)
    }
}
