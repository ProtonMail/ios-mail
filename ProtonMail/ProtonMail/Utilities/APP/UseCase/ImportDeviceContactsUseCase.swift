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

import class ProtonCoreDataModel.Key
import typealias ProtonCoreCrypto.Passphrase
import ProtonCoreUtilities

protocol ImportDeviceContactsUseCase {
    func execute(params: ImportDeviceContacts.Params)
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
    & HasContactsSyncQueueProtocol

    // Suggested batch size for creating contacts in backend
    private let contactBatchSize = 10
    private let maxNumberOfVCardsToDownload = 100
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
    private let mergeStrategy = AutoImportStrategy()
    private unowned let dependencies: Dependencies

    weak var delegate: ImportDeviceContactsDelegate?

    init(userID: UserID, dependencies: Dependencies) {
        self.userID = userID
        self.dependencies = dependencies
    }

    func execute(params: Params) {
        SystemLogger.log(message: "ImportDeviceContacts call for user \(userID.rawValue.redacted)", category: .contacts)
        guard backgroundTask == nil else { return }

        dependencies.contactSyncQueue.start()
        backgroundTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            defer { taskFinished() }
            let isFirstImport = contactsHistoryToken == nil
            let contactIDsToImport = fetchDeviceContactIdentifiersToImport()
            guard !contactIDsToImport.isEmpty else { return }
            delegate?.onProgressUpdate(count: 0, total: contactIDsToImport.count)

            let triagedContacts = triageContacts(identifiers: contactIDsToImport)
            if !isFirstImport { // more info: MAILIOS-4176
                await downloadProtonVCardsIfNeeded(
                    contactsMatchedByUuid: triagedContacts.toUpdateByUuidMatch,
                    contactsMatchedByEmail: triagedContacts.toUpdateByEmailMatch
                )
            }

            do {
                try saveNewProtonContacts(from: triagedContacts.toCreate, params: params)
                try updateProtonContacts(
                    fromUuidMatch: triagedContacts.toUpdateByUuidMatch,
                    fromEmailMatch: triagedContacts.toUpdateByEmailMatch,
                    params: params
                )
            } catch {
                SystemLogger.log(message: "ImportDeviceContacts catch \(error)", category: .contacts, isError: true)
            }
        }
    }

    func cancel() {
        SystemLogger.log(message: "ImportDeviceContacts cancelled", category: .contacts)
        backgroundTask?.cancel()
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

    /// Returns which contacts have to be created and which have to be updated by uuid match and which have to be updated by email match.
    private func triageContacts(identifiers: [DeviceContactIdentifier]) -> DeviceContactsToImport {
        let matcher = ProtonContactMatcher(contactProvider: dependencies.contactService)
        let (matchByUuid, matchByEmail) = matcher.matchProtonContacts(with: identifiers)
        let allDeviceContactsToUpdate = matchByUuid + matchByEmail
        let toCreate = identifiers.filter { deviceContact in
            !allDeviceContactsToUpdate
                .map(\.uuidNormalisedForAutoImport)
                .contains(deviceContact.uuidNormalisedForAutoImport)
        }
        let deviceContactsToImport = DeviceContactsToImport(
            toCreate: toCreate,
            toUpdateByUuidMatch: matchByUuid,
            toUpdateByEmailMatch: matchByEmail
        )
        SystemLogger.log(message: deviceContactsToImport.description, category: .contacts)
        return deviceContactsToImport
    }

    /**
     Given some `DeviceContactIdentifier` for specific matches, it checks if the matching Proton contacts
     in the local database have the vCards property downloaded. If it does not, it requests the contacts details to fetch them.
     */
    private func downloadProtonVCardsIfNeeded(
        contactsMatchedByUuid: [DeviceContactIdentifier],
        contactsMatchedByEmail: [DeviceContactIdentifier]
    ) async {
        let uuids = contactsMatchedByUuid.map(\.uuidNormalisedForAutoImport)
        let contactIDByUuid = dependencies.contactService.getContactsByUUID(uuids).map(\.contactID)
        let emails = contactsMatchedByEmail.flatMap(\.emails)
        let contactIDByEmail = dependencies.contactService.getContactsByEmailAddress(emails).map(\.contactID)

        let contactIDs = contactIDByUuid + contactIDByEmail
        let idsWithMissingVCards = getLimitedMissingVCardIds(from: contactIDs)
        guard !idsWithMissingVCards.isEmpty else { return }

        let message = "fetching vCards for \(idsWithMissingVCards.count) Proton contacts"
        SystemLogger.log(message: message, category: .contacts)

        await withTaskGroup(of: Bool.self) { [weak self] group in
            guard let contactService = self?.dependencies.contactService else { return }
            for id in idsWithMissingVCards {
                group.addTask {
                    do {
                        _ = try await contactService.fetchContact(contactID: id)
                        return true
                    } catch {
                        return false
                    }
                }
            }

            var numFailedFetches = 0
            for await fetchSucceed in group {
                numFailedFetches += fetchSucceed ? 0 : 1
            }
            if numFailedFetches > 0 {
                let message = "\(numFailedFetches) contact detail requests failed"
                SystemLogger.log(message: message, category: .contacts, isError: true)
            }
        }
    }

    private func getLimitedMissingVCardIds(from contactIDs: [ContactID]) -> [ContactID] {
        var result = dependencies.contactService.getContactsWithoutVCards(from: contactIDs)
        if result.count > maxNumberOfVCardsToDownload {
            result = Array(result[0..<maxNumberOfVCardsToDownload])
        }
        return result
    }
}

// MARK: create new contacts

extension ImportDeviceContacts {

    private func saveNewProtonContacts(from identifiers: [DeviceContactIdentifier], params: Params) throws {
        let batches = identifiers.chunked(into: contactBatchSize)
        for batch in batches {
            try Task.checkCancellation()
            autoreleasepool {
                do {
                    let uuids = batch.map(\.uuidInDevice)
                    let deviceContacts = try dependencies.deviceContacts.fetchContactBatch(with: uuids)
                    saveProtonContacts(from: deviceContacts, params: params)
                } catch {
                    SystemLogger
                        .log(message: "createProtonContacts error: \(error)", category: .contacts, isError: true)
                }
            }
        }
    }

    private func saveProtonContacts(from deviceContacts: [DeviceContact], params: Params) {
        guard let key = params.userKeys.first else {
            SystemLogger.log(message: "createProtonContacts no user key found", category: .contacts, isError: true)
            return
        }

        var contactsVCards = [[CardData]]()
        for deviceContact in deviceContacts {
            do {
                let parsedData = try DeviceContactParser.parseDeviceContact(
                    deviceContact,
                    userKey: key,
                    userPassphrase: params.mailboxPassphrase
                )
                contactsVCards.append(parsedData.cards)

            } catch {
                let msg = "createProtonContacts error: \(error) for contact: \(deviceContact.fullName?.redacted ?? "-")"
                SystemLogger.log(message: msg, category: .contacts, isError: true)
            }
        }
        enqueueAddContactsAction(for: contactsVCards)
    }

    private func enqueueAddContactsAction(for contactsVCards: [[CardData]]) {
        guard !contactsVCards.isEmpty else { return }
        let contactVCards = contactsVCards.map(ContactObjectVCards.init(vCards:))
        let task = ContactTask(taskID: UUID(), command: .create(contacts: contactVCards))
        dependencies.contactSyncQueue.addTask(task)
    }
}

// MARK: update contacts

extension ImportDeviceContacts {

    private func updateProtonContacts(
        fromUuidMatch uuidMatch: [DeviceContactIdentifier],
        fromEmailMatch emailMatch: [DeviceContactIdentifier],
        params: Params
    ) throws {
        let contactMerger = try ContactMerger(
            strategy: mergeStrategy,
            userKeys: params.userKeys,
            mailboxPassphrase: params.mailboxPassphrase
        )

        let uuidMatchBatches = uuidMatch.chunked(into: contactBatchSize)
        var totalContactsUpdatedByUuidMatch = 0
        for batch in uuidMatchBatches {
            try Task.checkCancellation()
            autoreleasepool {
                let mergedContactsByUuid = mergeContactsMatchByUuid(identifiers: batch, merger: contactMerger)
                totalContactsUpdatedByUuidMatch += mergedContactsByUuid.count
                for contact in mergedContactsByUuid {
                    enqueueUpdateContactAction(for: contact, cards: contact.cardDatas)
                }
            }
        }

        let emailMatchBatches = emailMatch.chunked(into: contactBatchSize)
        var totalContactsUpdatedByEmailMatch = 0
        for batch in emailMatchBatches {
            try Task.checkCancellation()
            autoreleasepool {
                let mergedContactsByEmail = mergeContactsMatchByEmail(identifiers: batch, merger: contactMerger)
                totalContactsUpdatedByEmailMatch += mergedContactsByEmail.count
                for contact in mergedContactsByEmail {
                    enqueueUpdateContactAction(for: contact, cards: contact.cardDatas)
                }
            }
        }

        let totalNumber = totalContactsUpdatedByUuidMatch + totalContactsUpdatedByEmailMatch
        let finalUpdatesNumberMsg = "Final number of contacts updated \(totalNumber)"
        let byUuidMsg = "by uuid: \(totalContactsUpdatedByUuidMatch)"
        let byEmailMsg = "by email: \(totalContactsUpdatedByEmailMatch)"
        SystemLogger.log(message: "\(finalUpdatesNumberMsg) (\(byUuidMsg) \(byEmailMsg))", category: .contacts)
    }

    private func mergeContactsMatchByUuid(
        identifiers: [DeviceContactIdentifier],
        merger: ContactMerger
    ) -> [ContactEntity] {
        let deviceUuidIdentifiers = identifiers.map(\.uuidInDevice)
        let normalisedIdentifiers = identifiers.map(\.uuidNormalisedForAutoImport)
        let uuidMatchContacts = dependencies.contactService.getContactsByUUID(normalisedIdentifiers)
        let deviceContacts: [DeviceContact]
        do {
            deviceContacts = try dependencies.deviceContacts.fetchContactBatch(with: deviceUuidIdentifiers)
        } catch {
            SystemLogger.log(message: "mergeContactsMatchedByUuid error: \(error)", category: .contacts, isError: true)
            return []
        }

        var resultingMergedContacts = [ContactEntity]()
        for deviceContact in deviceContacts {
            let normalisedContactUuid = deviceContact.identifier.uuidNormalisedForAutoImport
            do {
                guard let protonContact = uuidMatchContacts.first(where: { $0.uuid == normalisedContactUuid }) else {
                    throw ImportDeviceContactsError.protonContactNotFoundByUuid
                }

                let mergeResult = try merger.merge(deviceContact: deviceContact, protonContact: protonContact)
                if mergeResult.hasContactBeenUpdated {
                    if let mergedContactEntity = mergeResult.resultingContact.contactEntity {
                        resultingMergedContacts.append(mergedContactEntity)
                    } else {
                        throw ImportDeviceContactsError.mergedContactEntityIsNil
                    }
                }
            } catch {
                let message = "mergeContactsMatchedByUuid uuid \(normalisedContactUuid.redacted) error: \(error)"
                SystemLogger.log(message: message, category: .contacts, isError: true)
                continue
            }
        }
        return resultingMergedContacts
    }

    private func mergeContactsMatchByEmail(
        identifiers: [DeviceContactIdentifier],
        merger: ContactMerger
    ) -> [ContactEntity] {
        let deviceIdentifiers = identifiers.map(\.uuidInDevice)
        let deviceEmails = identifiers.flatMap(\.emails)
        let emailMatchContacts = dependencies.contactService.getContactsByEmailAddress(deviceEmails)
        let deviceContacts: [DeviceContact]
        do {
            deviceContacts = try dependencies.deviceContacts.fetchContactBatch(with: deviceIdentifiers)
        } catch {
            SystemLogger.log(message: "mergeContactsMatchedByEmail error: \(error)", category: .contacts, isError: true)
            return []
        }

        var resultingMergedContacts = [ContactEntity]()
        for deviceContact in deviceContacts {
            let deviceContactUuid = deviceContact.identifier.uuidInDevice
            do {
                let matcher = ProtonContactMatcher(contactProvider: dependencies.contactService)
                let protonContact = matcher.findContactToMergeMatchingEmail(with: deviceContact, in: emailMatchContacts)

                guard let protonContact else { continue }
                let mergeResult = try merger.merge(deviceContact: deviceContact, protonContact: protonContact)
                if mergeResult.hasContactBeenUpdated {
                    if let mergedContactEntity = mergeResult.resultingContact.contactEntity {
                        resultingMergedContacts.append(mergedContactEntity)
                    } else {
                        throw ImportDeviceContactsError.mergedContactEntityIsNil
                    }
                }
            } catch {
                let message = "mergeContactsMatchByEmail uuid \(deviceContactUuid.redacted) error: \(error)"
                SystemLogger.log(message: message, category: .contacts, isError: true)
                continue
            }
        }
        return resultingMergedContacts
    }

    private func enqueueUpdateContactAction(for contact: ContactEntity, cards: [CardData]) {
        let task = ContactTask(taskID: UUID(), command: .update(contactID: contact.contactID, vCards: cards))
        dependencies.contactSyncQueue.addTask(task)
    }
}

enum ImportDeviceContactsError: Error {
    case protonContactNotFoundByUuid
    case mergedContactEntityIsNil
}

extension ImportDeviceContacts {
    struct Params {
        let userKeys: [Key]
        let mailboxPassphrase: Passphrase
    }

    private struct DeviceContactsToImport {
        let toCreate: [DeviceContactIdentifier]
        let toUpdateByUuidMatch: [DeviceContactIdentifier]
        let toUpdateByEmailMatch: [DeviceContactIdentifier]

        var description: String {
            let msgCreate = "Device contacts with no match (to create): \(toCreate.count)"
            let msgUpdateUuid = "with uuid match (update): \(toUpdateByUuidMatch.count)"
            let msgUpdateEmail = "with email match (update): \(toUpdateByEmailMatch.count)"
            return "\(msgCreate), \(msgUpdateUuid), \(msgUpdateEmail)"
        }
    }
}

extension Either<DeviceContact, ContactEntity> {
    var contactEntity: ContactEntity? {
        switch self {
        case .right(let result):
            return result
        case .left:
            return nil
        }
    }
}
