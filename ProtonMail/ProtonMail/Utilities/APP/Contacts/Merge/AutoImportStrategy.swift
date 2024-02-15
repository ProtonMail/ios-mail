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

/**
 The auto import merge strategy will apply the information of `deviceContact` over `protonContact`. This strategy at most
 will overwrite some information but never delete it.

 For each difference between the two cards:
 1. If the vCard field compared can only have one value, the value of `deviceContact` will prevail in the resulting vCard over the
 value of `protonContact` (e.g. last name)
 2. If the vCard field compared can have multiple values, the resulting vCard will contain all `protonContact` values plus the
 ones from `deviceContact` that are different (e.g. emails)

 Contact field types are not considered when comparing fields in this strategy. The type of `deviceContact` will always prevail.
 */
struct AutoImportStrategy: ContactMergeStrategy {
    let mergeDestination: ContactMergeDestination = .protonContact

    func merge(deviceContact: VCardObject, protonContact: ProtonVCards) throws -> Bool {
        try protonContact.read()

        var isProtonContactModified = false
        if case let .merge(result) = mergeName(device: deviceContact.name(), proton: protonContact.name()) {
            protonContact.replaceName(with: result)
            isProtonContactModified = true
        }

        if case let .merge(result) = mergeFormattedName(
            device: deviceContact.formattedName(),
            proton: protonContact.formattedName()
        ) {
            protonContact.replaceFormattedName(with: result)
            isProtonContactModified = true
        }

        if case let .merge(result) = mergeEmails(device: deviceContact.emails(), proton: protonContact.emails()) {
            protonContact.replaceEmails(with: result)
            isProtonContactModified = true
        }

        if case let .merge(result) = mergeAddresses(
            device: deviceContact.addresses(),
            proton: protonContact.addresses()
        ) {
            protonContact.replaceAddresses(with: result)
            isProtonContactModified = true
        }

        if case let .merge(result) = mergePhoneNumbers(
            device: deviceContact.phoneNumbers(),
            proton: protonContact.phoneNumbers()
        ) {
            protonContact.replacePhoneNumbers(with: result)
            isProtonContactModified = true
        }

        if case let .merge(result) = mergeUrls(device: deviceContact.urls(), proton: protonContact.urls()) {
            protonContact.replaceUrls(with: result)
            isProtonContactModified = true
        }

        let otherInfoType: [InformationType] = [.nickname, .organization, .title, .birthday, .anniversary, .gender]
        for infoType in otherInfoType {
            guard let deviceInfo = deviceContact.otherInfo(infoType: infoType).first else {
                continue
            }
            guard let protonInfo = protonContact.otherInfo(infoType: infoType).first else {
                protonContact.replaceOtherInfo(infoType: infoType, with: [deviceInfo])
                isProtonContactModified = true
                continue
            }
            if case let .merge(result) = mergeOtherInfo(device: deviceInfo, proton: protonInfo) {
                protonContact.replaceOtherInfo(infoType: infoType, with: [result])
                isProtonContactModified = true
            }
        }
        return isProtonContactModified
    }
}

// MARK: field specific functions

extension AutoImportStrategy {

    func mergeName(
        device: ContactField.Name,
        proton: ContactField.Name
    ) -> FieldMergeResult<ContactField.Name> {
        device == proton ? .noChange : .merge(result: device)
    }

    func mergeFormattedName(device: String, proton: String) -> FieldMergeResult<String> {
        device == proton ? .noChange : .merge(result: device)
    }

    func mergeEmails(
        device: [ContactField.Email],
        proton: [ContactField.Email]
    ) -> FieldMergeResult<[ContactField.Email]> {
        let deviceEmailsVCardGroupStripped = device.map {
            ContactField.Email(type: $0.type, emailAddress: $0.emailAddress, vCardGroup: "")
        }

        let emailMerger = FieldTypeMerger<ContactField.Email>()
        emailMerger.merge(device: deviceEmailsVCardGroupStripped, proton: proton)

        guard emailMerger.resultHasChanges else {
            return .noChange
        }
        // we have to provide a vCardGroup for those emails missing one
        let result = emailMerger.result
        let vCardGroupPrefix = "item"
        var highestExistingItemIndex: Int = result
            .compactMap { Int($0.vCardGroup.trim().dropFirst(vCardGroupPrefix.count)) }
            .max() ?? 0

        let finalResult = result.map { emailField in
            let vCardGroup: String
            if emailField.vCardGroup.trim().isEmpty {
                highestExistingItemIndex += 1
                vCardGroup = "\(vCardGroupPrefix)\(highestExistingItemIndex)"
            } else {
                vCardGroup = emailField.vCardGroup
            }
            return ContactField.Email(
                type: emailField.type,
                emailAddress: emailField.emailAddress,
                vCardGroup: vCardGroup
            )
        }
        return .merge(result: finalResult)
    }

    func mergeAddresses(
        device: [ContactField.Address],
        proton: [ContactField.Address]
    ) -> FieldMergeResult<[ContactField.Address]> {

        // obtaining the addresses only found in the device
        let newDeviceAddresses = device.filter { deviceAddress in
            !proton.contains(deviceAddress)
        }
        return newDeviceAddresses.isEmpty ? .noChange : .merge(result: proton + newDeviceAddresses)
    }

    func mergePhoneNumbers(
        device: [ContactField.PhoneNumber],
        proton: [ContactField.PhoneNumber]
    ) -> FieldMergeResult<[ContactField.PhoneNumber]> {
        let phoneMerger = FieldTypeMerger<ContactField.PhoneNumber>()
        phoneMerger.merge(device: device, proton: proton)
        return phoneMerger.resultHasChanges ? .merge(result: phoneMerger.result) : .noChange
    }

    func mergeUrls(
        device: [ContactField.Url],
        proton: [ContactField.Url]
    ) -> FieldMergeResult<[ContactField.Url]> {
        let urlMerger = FieldTypeMerger<ContactField.Url>()
        urlMerger.merge(device: device, proton: proton)
        return urlMerger.resultHasChanges ? .merge(result: urlMerger.result) : .noChange
    }

    func mergeOtherInfo(
        device: ContactField.OtherInfo,
        proton: ContactField.OtherInfo
    ) -> FieldMergeResult<ContactField.OtherInfo> {
        device.value == proton.value ? .noChange : .merge(result: device)
    }
}

enum FieldMergeResult<T> {
    case merge(result: T)
    case noChange
}
