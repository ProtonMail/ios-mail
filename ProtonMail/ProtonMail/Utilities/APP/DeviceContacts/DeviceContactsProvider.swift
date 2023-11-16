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

    /// Returns the identifier for every existing contact
    func fetchAllContactIdentifiers() throws -> [String]

    /// Returns a `DeviceContact` for every identifier passed if it exists
    func fetchContactBatch(with identifiers: [String]) throws -> [DeviceContact]

    /// Returns all `DeviceContactEvent` after a point in history marked by `historyToken`
    func fetchHistoryEvents(historyToken: Data?) throws -> (historyToken: Data, events: [DeviceContactEvent])
}

final class DeviceContacts: DeviceContactsProvider {
    private let protonAuthorIdentifier: String = {
        // swiftlint:disable:next force_unwrapping
        Bundle.main.bundleIdentifier!
    }()
    private let contactStore: CNContactStore

    private var contactKeys: [CNKeyDescriptor] {
        [
            CNContactEmailAddressesKey,
            CNContactPhoneNumbersKey,
            CNContactImageDataAvailableKey,
            CNContactImageDataKey,
            CNContactThumbnailImageDataKey,
            CNContactIdentifierKey
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

    func fetchAllContactIdentifiers() throws -> [String] {
        let keysToFetch = [CNContactIdentifierKey] as [CNKeyDescriptor]
        let contacts = try contactStore.unifiedContacts(matching: NSPredicate(value: true), keysToFetch: keysToFetch)
        return contacts.map(\.identifier)
    }

    func fetchContactBatch(with identifiers: [String]) throws -> [DeviceContact] {
        let predicate = CNContact.predicateForContacts(withIdentifiers: identifiers)
        let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: contactKeys)
        return contacts.compactMap(\.deviceContact)
    }

    func fetchHistoryEvents(historyToken: Data?) throws -> (historyToken: Data, events: [DeviceContactEvent]) {
        let request = CNChangeHistoryFetchRequest()
        request.shouldUnifyResults = true
        request.includeGroupChanges = false
        request.startingToken = historyToken
        request.additionalContactKeyDescriptors = contactKeys
        request.excludedTransactionAuthors = [protonAuthorIdentifier]

        var error: NSError?
        let results = contactStore.eventsEnumerator(for: request, error: &error)
        if let error { throw error }

        let events = results.value.compactMap { ($0 as? CNChangeHistoryEvent)?.toDeviceContactEvent }
        return (results.currentHistoryToken, events)
    }
}

extension CNChangeHistoryEvent {

    var toDeviceContactEvent: DeviceContactEvent? {
        switch self {
        case let event as CNChangeHistoryAddContactEvent:
            guard let contact = event.contact.deviceContact else { return nil }
            return DeviceContactEvent(contactIdentifier: event.contact.identifier, type: .addContact(contact: contact))
        case let event as CNChangeHistoryUpdateContactEvent:
            guard let contact = event.contact.deviceContact else { return nil }
            let identifier = event.contact.identifier
            return DeviceContactEvent(contactIdentifier: identifier, type: .updateContact(contact: contact))
        case let event as CNChangeHistoryDeleteContactEvent:
            return DeviceContactEvent(contactIdentifier: event.contactIdentifier, type: .deleteContact)
        default:
            return nil
        }
    }
}

extension CNContact {

    var fullName: String {
        CNContactFormatter.string(from: self, style: .fullName) ?? "Unknown"
    }

    var deviceContact: DeviceContact? {
        guard let vCard = try? vCard() else { return nil }
        return DeviceContact(identifier: identifier, fullName: fullName, vCard: vCard)
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
