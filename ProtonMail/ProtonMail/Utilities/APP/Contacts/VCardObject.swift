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

import VCard

struct VCardObject {
    private let object: PMNIVCard

    init(object: PMNIVCard) {
        self.object = object
    }

    // MARK: read methods

    func name() -> ContactField.Name {
        guard let name = object.getStructuredName() else {
            return ContactField.Name(firstName: "", lastName: "")
        }
        return ContactField.Name(firstName: name.getGiven(), lastName: name.getFamily())
    }

    func formattedName() -> String {
        return object.getFormattedName()?.getValue() ?? ""
    }

    func emails() -> [ContactField.Email] {
        object
            .getEmails()
            .map { email in
                ContactField.Email(
                    type: email.getTypes().mapToContactFieldType(),
                    emailAddress: email.getValue(),
                    vCardGroup: email.getGroup()
                )
            }
    }

    func addresses() -> [ContactField.Address] {
        object
            .getAddresses()
            .map { address in
                ContactField.Address(
                    type: address.getTypes().mapToContactFieldType(),
                    street: address.getStreetAddress(),
                    streetTwo: address.getExtendedAddress(),
                    locality: address.getLocality(),
                    region: address.getRegion(),
                    postalCode: address.getPostalCode(),
                    country: address.getCountry(),
                    poBox: address.getPoBoxes().asCommaSeparatedList(trailingSpace: false)
                )
            }
    }

    func phoneNumbers() -> [ContactField.PhoneNumber] {
        object
            .getTelephoneNumbers()
            .map { number in
                ContactField.PhoneNumber(
                    type: number.getTypes().mapToContactFieldType(),
                    number: number.getText()
                )
            }
    }

    func urls() -> [ContactField.Url] {
        object
            .getUrls()
            .map { url in
                ContactField.Url(
                    type: ContactFieldType.get(raw: url.getType()),
                    url: url.getValue()
                )
            }
    }

    func otherInfo(infoType: InformationType) -> [ContactField.OtherInfo] {
        info(from: object, ofType: infoType).map {
            ContactField.OtherInfo(type: infoType, value: $0)
        }
    }

    private func info(from object: PMNIVCard, ofType info: InformationType) -> [String] {
        var result: [String] = []
        switch info {
        case .birthday:
            result = object.getBirthdays().map(\.formattedBirthday)
        case .anniversary:
            result = object.getBirthdays().map { $0.getDate() }
        case .nickname:
            result = object.getNicknames().map { $0.getNickname() }
        case .title:
            result = object.getTitles().map { $0.getTitle() }
        case .organization:
            result = object.getOrganizations().map { $0.getValue() }
        case .gender:
            if let gender = object.getGender()?.getGender() { result = [gender] }
        default:
            PMAssertionFailure("VCardObject reader: \(info) not implemented")
        }
        return result
    }

    // MARK: write methods

    func replaceEmails(with emails: [ContactField.Email]) {
        let newEmails = emails.compactMap { email in
            PMNIEmail.createInstance(email.type.rawString, email: email.emailAddress, group: email.vCardGroup)
        }
        object.clearEmails()
        object.setEmails(newEmails)
    }
}

private extension Array where Element == String {

    func mapToContactFieldType() -> ContactFieldType {
        first.map(ContactFieldType.init(raw:)) ?? .custom("")
    }
}
