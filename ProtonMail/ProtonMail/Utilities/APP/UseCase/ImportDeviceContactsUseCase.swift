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
import class ProtonCoreDataModel.Key
import typealias ProtonCoreCrypto.Passphrase

protocol ImportDeviceContactsUseCase {
    func execute(params: ImportDeviceContacts.Params) async
    func cancel()
}

protocol ImportDeviceContactsDelegate: AnyObject {
    func onProgressUpdate(count: Int, total: Int)
    func onFinish()
}

final class ImportDeviceContacts: ImportDeviceContactsUseCase {
    typealias Dependencies = AnyObject
    & HasUserDefaults
    & HasDeviceContactsProvider
    & HasContactDataService
    & HasQueueManager

    // Suggested batch size for creating contacts in backend
    private let contactBatchSize = 10
    private var backgroundTask: Task<Void, Never>?
    private let userID: UserID
    private var contactsHistoryToken: Data? {
        get {
            let historyTokens = dependencies.userDefaults[.contactsHistoryTokenPerUser]
            return historyTokens[userID.rawValue]
        }
        set {
            var historyTokens = dependencies.userDefaults[.contactsHistoryTokenPerUser]
            historyTokens[userID.rawValue] = newValue
            dependencies.userDefaults[.contactsHistoryTokenPerUser] = historyTokens
        }
    }

    private unowned let dependencies: Dependencies

    weak var delegate: ImportDeviceContactsDelegate?

    init(userID: UserID, dependencies: Dependencies) {
        self.userID = userID
        self.dependencies = dependencies
    }

    func execute(params: Params) async {
        SystemLogger.log(message: "ImportDeviceContacts execute", category: .contacts)
        guard backgroundTask == nil else { return }

        backgroundTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            defer { taskFinished() }

            let contactIDsToImport = fetchDeviceContactIdentifiersToImport()
            guard !contactIDsToImport.isEmpty else { return }
            delegate?.onProgressUpdate(count: 0, total: contactIDsToImport.count)

            let (contactsToCreate, contactsToUpdate) = triageContacts(identifiers: contactIDsToImport)
            createProtonContacts(from: contactsToCreate, params: params)
            updateProtonContacts(from: contactsToUpdate)
        }
    }

    func cancel() {
        SystemLogger.log(message: "ImportDeviceContacts cancelled", category: .contacts)
        backgroundTask?.cancel()
        taskFinished()
    }
}

extension ImportDeviceContacts {

    private func taskFinished() {
        backgroundTask = nil
        delegate?.onFinish()
    }

    /// Returns the identifiers of the contacts that have to be imported
    private func fetchDeviceContactIdentifiersToImport() -> [DeviceContactIdentifier] {
        do {
            if let contactsHistoryToken {
                return try fetchChangedContactsIdentifiers(historyToken: contactsHistoryToken)
            } else {
                return try fetchAllContactsIdentifiers()
            }
        } catch {
            SystemLogger.log(error: error, category: .contacts)
            return []
        }
    }

    private func fetchAllContactsIdentifiers() throws -> [DeviceContactIdentifier] {
        let (newToken, contactIDs) = try dependencies.deviceContacts.fetchAllContactIdentifiers()
        contactsHistoryToken = newToken
        SystemLogger.log(message: "fetch all device contacts: found \(contactIDs.count)", category: .contacts)
        return contactIDs
    }

    private func fetchChangedContactsIdentifiers(historyToken: Data) throws -> [DeviceContactIdentifier] {
        let (newToken, contactIDs) = try dependencies
            .deviceContacts
            .fetchEventsContactIdentifiers(historyToken: historyToken)
        contactsHistoryToken = newToken
        SystemLogger.log(message: "fetch device changed contacts: found \(contactIDs.count)", category: .contacts)
        return contactIDs
    }

    /// Returns which contacts have to be created and which ones have to be updated
    private func triageContacts(
        identifiers: [DeviceContactIdentifier]
    ) -> (toCreate: [DeviceContactIdentifier], toUpdate: [DeviceContactIdentifier]) {

        let matcher = ProtonContactMatcher(contactProvider: dependencies.contactService)
        let toUpdate = matcher.matchProtonContacts(with: identifiers)
        let toCreate = identifiers.filter { deviceContact in
            !toUpdate.map(\.uuid).contains(deviceContact.uuid)
        }

        let message = "Proton contacts to create: \(toCreate.count), to update: \(toUpdate.count)"
        SystemLogger.log(message: message, category: .contacts)

        return (toCreate, toUpdate)
    }

}

// MARK: create new contacts

extension ImportDeviceContacts {

    private func createProtonContacts(from identifiers: [DeviceContactIdentifier], params: Params) {
        let batches = identifiers.chunked(into: contactBatchSize)
        for batch in batches {
            guard !Task.isCancelled else { break }
            autoreleasepool {
                do {
                    let deviceContacts = try dependencies.deviceContacts.fetchContactBatch(with: batch.map(\.uuid))
                    createProtonContacts(from: deviceContacts, params: params)
                } catch {
                    SystemLogger
                        .log(message: "createProtonContacts error: \(error)", category: .contacts, isError: true)
                }
            }
        }
    }

    private func createProtonContacts(from deviceContacts: [DeviceContact], params: Params) {
        for deviceContact in deviceContacts {
            do {
                let parsedData = try DeviceContactParser.parseDeviceContact(
                    deviceContact,
                    userKey: params.userKey,
                    userPassphrase: params.mailboxPassphrase
                )
                let objectID = try dependencies.contactService.createLocalContact(
                    name: parsedData.name,
                    emails: parsedData.emails,
                    cards: parsedData.cards
                )
                enqueueAddContactAction(for: objectID, cards: parsedData.cards)

            } catch {
                let msg = "createProtonContacts error: \(error) for contact: \(deviceContact.fullName?.redacted ?? "-")"
                SystemLogger.log(message: msg, category: .contacts, isError: true)
            }
        }
    }

    // TODO: create a queue to run tasks in parallel
    private func enqueueAddContactAction(for objectID: String, cards: [CardData]) {
        let action = MessageAction.addContact(objectID: objectID, cardDatas: cards, importFromDevice: true)
        let task = QueueManager
            .Task(messageID: "", action: action, userID: userID, dependencyIDs: [], isConversation: false)
        dependencies.queueManager.addTask(task)
    }
}

// MARK: update contacts

extension ImportDeviceContacts {

    private func updateProtonContacts(from identifiers: [DeviceContactIdentifier]) {

        // TODO: coming

        // PENDING:
        // 1. Addition strategy for contactsToUpdate
        // 2. Update contacts to import
        // 3. Sync modified contacts with backend

    }
}

extension ImportDeviceContacts {
    struct Params {
        let userKey: Key
        let mailboxPassphrase: Passphrase
    }
}
