// Copyright (c) 2021 Proton AG
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
@testable import ProtonMail
import UIKit

final class ContactParserResultViewMock: ContactParserResultDelegate {
    private(set) var emails: [ContactEditEmail] = []
    private(set) var addresses: [ContactEditAddress] = []
    private(set) var telephones: [ContactEditPhone] = []
    private(set) var informations: [ContactEditInformation] = []
    private(set) var fields: [ContactEditField] = []
    private(set) var notes: [ContactEditNote] = []
    private(set) var urls: [ContactEditUrl] = []
    private(set) var profilePicture: UIImage?
    private(set) var verifyType2: Bool = true
    private(set) var verifyType3: Bool = true
    private(set) var decryptError: Bool = false

    func append(emails: [ContactEditEmail]) {
        self.emails.append(contentsOf: emails)
    }

    func append(addresses: [ContactEditAddress]) {
        self.addresses.append(contentsOf: addresses)
    }

    func append(telephones: [ContactEditPhone]) {
        self.telephones.append(contentsOf: telephones)
    }

    func append(informations: [ContactEditInformation]) {
        self.informations.append(contentsOf: informations)
    }

    func append(fields: [ContactEditField]) {
        self.fields.append(contentsOf: fields)
    }

    func append(notes: [ContactEditNote]) {
        self.notes.append(contentsOf: notes)
    }

    func append(urls: [ContactEditUrl]) {
        self.urls.append(contentsOf: urls)
    }

    func update(verifyType3: Bool) {
        self.verifyType3 = verifyType3
    }

    func update(decryptionError: Bool) {
        self.decryptError = decryptionError
    }

    func update(profilePicture: UIImage?) {
        self.profilePicture = profilePicture
    }
}
