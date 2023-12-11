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

enum ContactField {}

extension ContactField {

    struct Name: Equatable {
        let firstName: String
        let lastName: String
    }
}

extension ContactField {

    struct Email: Equatable {
        let type: ContactFieldType
        let emailAddress: String
        let vCardGroup: String

        func copy(changingTypeTo type: ContactFieldType) -> Email {
            Email(type: type, emailAddress: self.emailAddress, vCardGroup: self.vCardGroup)
        }
    }
}

extension ContactField {

    struct Address: Equatable {
        let type: ContactFieldType
        let street: String
        let streetTwo: String
        let locality: String
        let region: String
        let postalCode: String
        let country: String
        let poBox: String
    }
}

extension ContactField {

    struct PhoneNumber: Equatable {
        let type: ContactFieldType
        let number: String

        func copy(changingTypeTo type: ContactFieldType) -> ContactField.PhoneNumber {
            PhoneNumber(type: type, number: self.number)
        }
    }
}

extension ContactField {

    struct Url: Equatable {
        let type: ContactFieldType
        let url: String

        func copy(changingTypeTo type: ContactFieldType) -> ContactField.Url {
            Url(type: type, url: self.url)
        }
    }
}

extension ContactField {

    struct OtherInfo: Equatable {
        let type: InformationType
        let value: String
    }
}
