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

import Contacts

// sourcery: mock
/// Protocol to abstract any reference to `Contacts`
protocol DeviceContactsProvider {

    /// Function to get the identifiers of all existing contacts in the device
    /// - Returns: the history token to use in future requests and the identifiers for every existing contact
    func fetchAllContactIdentifiers() throws -> (historyToken: Data, identifiers: [DeviceContactIdentifier])

    /// Function to get the identifiers of the contacts that have been modified
    /// - Parameter historyToken: token to get changed events from a point in time
    /// - Returns: the new historyToken and the identifiers of the Contacts
    func fetchEventsContactIdentifiers(
        historyToken: Data
    ) throws -> (historyToken: Data, identifiers: [DeviceContactIdentifier])

    /// Returns a `DeviceContact` for every identifier passed if it exists
    func fetchContactBatch(with identifiers: [String]) throws -> [DeviceContact]
}

final class DeviceContacts: DeviceContactsProvider {
    private let protonAuthorIdentifier: String = {
        // swiftlint:disable:next force_unwrapping
        Bundle.main.bundleIdentifier!
    }()
    private let contactStore: CNContactStore

    private let identifierContactKeys = [CNContactIdentifierKey, CNContactEmailAddressesKey] as [CNKeyDescriptor]
    private var fullContactKeys: [CNKeyDescriptor] {
        [
            CNContactIdentifierKey,
            CNContactEmailAddressesKey,
            CNContactPhoneNumbersKey,
            CNContactImageDataAvailableKey,
            CNContactImageDataKey,
            CNContactThumbnailImageDataKey
        ] as [CNKeyDescriptor]
        +
        [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactVCardSerialization.descriptorForRequiredKeys()
        ]
    }

    init() {
        self.contactStore = CNContactStore()
    }

    func fetchAllContactIdentifiers() throws -> (historyToken: Data, identifiers: [DeviceContactIdentifier]) {
        let result = try changeHistoryResult(historyToken: nil, keys: identifierContactKeys)
        let identifiers: [DeviceContactIdentifier] = result
            .value
            .compactMap { $0 as? CNChangeHistoryEvent }
            .compactMap(\.deviceContactIdentifier)
        return (result.currentHistoryToken, identifiers)
    }

    func fetchEventsContactIdentifiers(
        historyToken: Data
    ) throws -> (historyToken: Data, identifiers: [DeviceContactIdentifier]) {
        let result = try changeHistoryResult(historyToken: historyToken, keys: identifierContactKeys)
        let identifiers: [DeviceContactIdentifier] = result
            .value
            .compactMap { $0 as? CNChangeHistoryEvent }
            .compactMap(\.deviceContactIdentifier)
        return (result.currentHistoryToken, identifiers)
    }

    func fetchContactBatch(with identifiers: [String]) throws -> [DeviceContact] {
        let predicate = CNContact.predicateForContacts(withIdentifiers: identifiers)
        let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: fullContactKeys)
        return contacts.compactMap(\.deviceContact)
    }

    private func changeHistoryResult(historyToken: Data?, keys: [CNKeyDescriptor]) throws -> ChangeHistoryResult {
        let request = CNChangeHistoryFetchRequest()
        request.shouldUnifyResults = true
        request.includeGroupChanges = false
        request.startingToken = historyToken
        request.additionalContactKeyDescriptors = keys
        request.excludedTransactionAuthors = [protonAuthorIdentifier]

        var error: NSError?
        let result = contactStore.eventsEnumerator(for: request, error: &error)
        if let error { throw error }
        return result
    }
}

extension CNChangeHistoryEvent {

    var deviceContactIdentifier: DeviceContactIdentifier? {
        guard let identifier else { return nil }
        return DeviceContactIdentifier(uuidInDevice: identifier, emails: emails)
    }

    var identifier: String? {
        switch self {
        case let event as CNChangeHistoryAddContactEvent:
            return event.contact.identifier
        case let event as CNChangeHistoryUpdateContactEvent:
            return event.contact.identifier
        case let event as CNChangeHistoryDeleteContactEvent:
            return event.contactIdentifier
        default:
            return nil
        }
    }

    var emails: [String] {
        switch self {
        case let event as CNChangeHistoryAddContactEvent:
            return event.contact.emailAddressesAsString
        case let event as CNChangeHistoryUpdateContactEvent:
            return event.contact.emailAddressesAsString
        default:
            return []
        }
    }

//    var toDeviceContactEvent: DeviceContactEvent? {
//        switch self {
//        case let event as CNChangeHistoryAddContactEvent:
//            guard let contact = event.contact.deviceContact else { return nil }
//            return DeviceContactEvent(contactIdentifier: event.contact.identifier, type: .addContact(contact: contact))
//        case let event as CNChangeHistoryUpdateContactEvent:
//            guard let contact = event.contact.deviceContact else { return nil }
//            let identifier = event.contact.identifier
//            return DeviceContactEvent(contactIdentifier: identifier, type: .updateContact(contact: contact))
//        case let event as CNChangeHistoryDeleteContactEvent:
//            return DeviceContactEvent(contactIdentifier: event.contactIdentifier, type: .deleteContact)
//        default:
//            return nil
//        }
//    }
}

extension CNContact {

    var fullName: String? {
        CNContactFormatter.string(from: self, style: .fullName)
    }

    var emailAddressesAsString: [String] {
        emailAddresses.map { $0.value as String }
    }

    var deviceContact: DeviceContact? {
        guard let vCard = try? vCard() else { return nil }
        return DeviceContact(
            identifier: .init(uuidInDevice: identifier, emails: emailAddressesAsString),
            fullName: fullName,
            vCard: vCard
        )
    }

    func vCard() throws -> String? {
        do {
            let data = try CNContactVCardSerialization.data(with: [self])
            return String(data: data, encoding: .utf8)
        } catch {
            SystemLogger.log(
                message: "Error converting CNContact with identifier \(identifier) to vCard: \(error)",
                category: .contacts,
                isError: true
            )
            throw error
        }
    }
}
