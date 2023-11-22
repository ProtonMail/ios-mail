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

protocol ImportDeviceContactsUseCase {
    func execute() async
    func cancel()
}

protocol ImportDeviceContactsDelegate: AnyObject {
    func onProgressUpdate(count: Int, total: Int)
    func onFinish()
}

final class ImportDeviceContacts: ImportDeviceContactsUseCase {
    typealias Dependencies = AnyObject & HasContactsSyncCache & HasDeviceContactsProvider & HasContactDataService

    // Suggested batch size for creating contacts in backend
    private let contactBatchSize = 10
    private var backgroundTask: Task<Void, Never>?
    private let userID: UserID
    private unowned let dependencies: Dependencies

    weak var delegate: ImportDeviceContactsDelegate?

    init(userID: UserID, dependencies: Dependencies) {
        self.userID = userID
        self.dependencies = dependencies
    }

    func execute() async {
        SystemLogger.log(message: "ImportDeviceContacts execute", category: .contacts)
        guard backgroundTask == nil else { return }

        backgroundTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            defer { taskFinished() }

            let contactIDsToImport = fetchDeviceContactIdentifiersToImport()
            guard !contactIDsToImport.isEmpty else { return }
            delegate?.onProgressUpdate(count: 0, total: contactIDsToImport.count)

            let (contactsToCreate, contactsToUpdate) = triageContacts(identifiers: contactIDsToImport)

            // PENDING:
            // 1. Addition strategy for contactsToUpdate
            // 2. Encrypt resulting merged contact
            // 3. Save / Update all contacts to import
            // 4. Sync contacts with backend

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
            if let token = dependencies.contactsSyncCache.historyToken(for: userID) {
                return try fetchChangedContactsIdentifiers(historyToken: token)
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
        dependencies.contactsSyncCache.setHistoryToken(newToken, for: userID)
        SystemLogger.log(message: "fetch all device contacts: found \(contactIDs.count)", category: .contacts)
        return contactIDs
    }

    private func fetchChangedContactsIdentifiers(historyToken: Data) throws -> [DeviceContactIdentifier] {
        let (newToken, contactIDs) = try dependencies
            .deviceContacts
            .fetchEventsContactIdentifiers(historyToken: historyToken)
        dependencies.contactsSyncCache.setHistoryToken(newToken, for: userID)
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
