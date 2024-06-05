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
    let object: PMNIVCard

    // MARK: read methods

    func vCard() throws -> String {
        guard let result = try object.write() else {
            throw VCardObjectError.failedToGenerateVCardString
        }
        return result
    }

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
        case .nickname:
            result = object.getNicknames().map { $0.getNickname() }
        case .organization:
            result = object.getOrganizations().map { $0.getValue() }
        case .title:
            result = object.getTitles().map { $0.getTitle() }
        case .birthday:
            result = object.getBirthdays().map(\.formattedBirthday)
        case .anniversary:
            result = object.getAnniversaries().map { $0.getDate() }
        case .gender:
            if let gender = object.getGender()?.getGender() { result = [gender] }
        default:
            PMAssertionFailure("VCardObject reader: \(info) not implemented")
        }
        return result
    }

    // MARK: write methods

    func replaceName(with name: ContactField.Name) {
        let structuredName = PMNIStructuredName.createInstance()
        structuredName?.setGiven(name.firstName)
        structuredName?.setFamily(name.lastName)
        object.clearStructuredName()
        object.setStructuredName(structuredName)
    }

    func replaceFormattedName(with name: String) {
        let formattedName = PMNIFormattedName.createInstance(name)
        object.clearFormattedName()
        object.setFormattedName(formattedName)
    }

    func replaceEmails(with emails: [ContactField.Email]) {
        let newEmails = emails.compactMap { email in
            PMNIEmail.createInstance(email.type.rawString, email: email.emailAddress, group: email.vCardGroup)
        }
        object.clearEmails()
        object.setEmails(newEmails)
    }

    func replaceAddresses(with addresses: [ContactField.Address]) {
        let newAddresses = addresses.compactMap { address in
            PMNIAddress.createInstance(
                address.type.rawString,
                street: address.street,
                extendstreet: address.streetTwo,
                locality: address.locality,
                region: address.region,
                zip: address.postalCode,
                country: address.country,
                pobox: address.poBox
            )
        }
        object.clearAddresses()
        object.setAddresses(newAddresses)
    }

    func replacePhoneNumbers(with phoneNumbers: [ContactField.PhoneNumber]) {
        let newPhoneNumbers = phoneNumbers.compactMap { phoneNumber in
            PMNITelephone.createInstance(
                phoneNumber.type.rawString,
                number: phoneNumber.number
            )
        }
        object.clearTelephones()
        object.setTelephones(newPhoneNumbers)
    }

    func replaceUrls(with urls: [ContactField.Url]) {
        let newUrls = urls.compactMap { url in
            PMNIUrl.createInstance(url.type.rawString, value: url.url)
        }
        object.clearUrls()
        object.setUrls(newUrls)
    }

    func replaceOtherInfo(infoType: InformationType, with info: [ContactField.OtherInfo]) {
        switch infoType {
        case .birthday:
            let newBirthdays = info.compactMap { birthday in
                PMNIBirthday.createInstance("", date: birthday.value)
            }
            object.clearBirthdays()
            object.setBirthdays(newBirthdays)

        case .anniversary:
            let newAnniversary = info.compactMap { anniversary in
                PMNIAnniversary.createInstance("", date: anniversary.value)
            }
            object.clearAnniversaries()
            newAnniversary.forEach(object.add)

        case .nickname:
            let newNicknames = info.compactMap { nickname in
                PMNINickname.createInstance("", value: nickname.value)
            }
            object.clearNickname()
            newNicknames.forEach(object.add)

        case .title:
            let newTitles = info.compactMap { title in
                PMNITitle.createInstance("", value: title.value)
            }
            object.clearTitle()
            newTitles.forEach(object.add)

        case .organization:
            let newOrganizations = info.compactMap { organization in
                PMNIOrganization.createInstance("", value: organization.value)
            }
            object.clearOrganizations()
            object.setOrganizations(newOrganizations)

        case .gender:
            guard let gender = info.compactMap({ PMNIGender.createInstance("", text: $0.value) }).first else {
                return
            }
            object.clearGender()
            object.setGender(gender)

        default:
            PMAssertionFailure("VCardObject writer: \(info) not implemented")
        }
    }
}

enum VCardObjectError: Error {
    case failedToGenerateVCardString
}

private extension Array where Element == String {

    func mapToContactFieldType() -> ContactFieldType {
        first.map(ContactFieldType.init(raw:)) ?? .custom("")
    }
}
