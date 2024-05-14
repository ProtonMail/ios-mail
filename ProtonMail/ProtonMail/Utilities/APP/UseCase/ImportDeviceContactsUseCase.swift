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
    & HasTelemetryServiceProtocol
    & HasNotificationCenter

    /// This is the limit of number of contacts in Proton, for any kind of user.
    /// To help with memory management in extreme cases where the device
    /// contains dozens of thousands of contacts, we will cap the number of
    /// enqueued operations to this number.
    private let maxNumberOfContactsInProton = 10_000

    // Suggested batch size for creating contacts in backend
    private let contactBatchSize = 10
    private let maxVCardsDownloadsAllowed = 100
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
        self.observeNotifications()
    }

    private func observeNotifications() {
        dependencies
            .notificationCenter
            .addObserver(
                forName: .cancelImportContactsTask,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                self?.cancel()
            }
    }

    func execute(params: Params) {
        SystemLogger.log(message: "ImportDeviceContacts call for user \(userID.rawValue.redacted)", category: .contacts)
        guard backgroundTask == nil else { return }

        dependencies.contactSyncQueue.setup()
        backgroundTask = Task.detached(priority: .medium) { [weak self] in
            guard let self = self else { return }
            defer { taskFinished() }
            let isFirstImport = contactsHistoryToken == nil
            let (contactIDsToImport, newHistoryToken) = fetchDeviceContactIdentifiersToImport()
            guard !contactIDsToImport.isEmpty else {
                // we start for potential previously persisted operations
                dependencies.contactSyncQueue.start()
                return
            }
            delegate?.onProgressUpdate(count: 0, total: contactIDsToImport.count)

            guard !Task.isCancelled else { return }
            let triagedContacts = triageContacts(identifiers: contactIDsToImport)
                .capNumberOfContactsIfNeeded(maxAllowed: maxNumberOfContactsInProton)
            var numOfSkippedVCardsDownloads: Int = 0

            guard !Task.isCancelled else { return }
            await downloadProtonVCardsIfNeeded(
                isFirstImport: isFirstImport,
                contactsMatchedByUuid: triagedContacts.toUpdateByUuidMatch,
                contactsMatchedByEmail: triagedContacts.toUpdateByEmailMatch,
                numOfSkippedVCardsDownloads: &numOfSkippedVCardsDownloads
            )
            contactsHistoryToken = newHistoryToken

            do {
                var numContactsToUpdate = 0
                try saveNewProtonContacts(from: triagedContacts.toCreate, params: params)
                try updateProtonContacts(
                    fromUuidMatch: triagedContacts.toUpdateByUuidMatch,
                    fromEmailMatch: triagedContacts.toUpdateByEmailMatch,
                    params: params,
                    numContactsToUpdate: &numContactsToUpdate
                )

                // once everything is enqueued we start the sync
                dependencies.contactSyncQueue.start()

                await reportTelemetryIfNeeded(
                    isFirstImport: isFirstImport,
                    numContactsToCreate: triagedContacts.toCreate.count,
                    numContactsToUpdate: numContactsToUpdate,
                    numOfSkippedVCardsDownloads: numOfSkippedVCardsDownloads
                )
            } catch {
                SystemLogger.log(message: "ImportDeviceContacts catch \(error)", category: .contacts, isError: true)
            }
        }
    }

    func cancel() {
        SystemLogger.log(message: "ImportDeviceContacts cancelled", category: .contacts)
        guard let backgroundTask else {
            SystemLogger.log(message: "No task was found to be cancelled", category: .contacts)
            return
        }
        backgroundTask.cancel()
    }
}

extension ImportDeviceContacts {

    private func taskFinished() {
        backgroundTask = nil
        delegate?.onFinish()
    }

    /// Returns the identifiers of the contacts that have to be imported and the contact history token
    private func fetchDeviceContactIdentifiersToImport() -> ([DeviceContactIdentifier], Data?) {
        do {
            if let contactsHistoryToken {
                return try fetchChangedContactsIdentifiers(historyToken: contactsHistoryToken)
            } else {
                return try fetchAllContactsIdentifiers()
            }
        } catch {
            SystemLogger.log(error: error, category: .contacts)
            return ([], nil)
        }
    }

    private func fetchAllContactsIdentifiers() throws -> ([DeviceContactIdentifier], Data?) {
        let (newContactHistoryToken, contactIDs) = try dependencies.deviceContacts.fetchAllContactIdentifiers()
        SystemLogger.log(message: "fetch all device contacts: found \(contactIDs.count)", category: .contacts)
        return (contactIDs, newContactHistoryToken)
    }

    private func fetchChangedContactsIdentifiers(historyToken: Data) throws -> ([DeviceContactIdentifier], Data?) {
        let (newContactHistoryToken, contactIDs) = try dependencies
            .deviceContacts
            .fetchEventsContactIdentifiers(historyToken: historyToken)
        SystemLogger.log(message: "fetch device changed contacts: found \(contactIDs.count)", category: .contacts)
        return (contactIDs, newContactHistoryToken)
    }

    /// Returns which contacts have to be created and which have to be updated by uuid match and which have to be updated by email match.
    private func triageContacts(identifiers: [DeviceContactIdentifier]) -> DeviceContactsToImport {
        let matcher = ProtonContactMatcher(contactProvider: dependencies.contactService)
        let (matchByUuid, matchByEmail) = matcher.matchProtonContacts(with: identifiers)
        let allDeviceContactsToUpdate = matchByUuid + matchByEmail

        let tempAllDeviceContactsUUIDSet = Set(allDeviceContactsToUpdate.map(\.uuidNormalisedForAutoImport))
        let toCreate = identifiers.filter { deviceContact in
            !tempAllDeviceContactsUUIDSet.contains(deviceContact.uuidNormalisedForAutoImport)
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
        isFirstImport: Bool,
        contactsMatchedByUuid: [DeviceContactIdentifier],
        contactsMatchedByEmail: [DeviceContactIdentifier],
        numOfSkippedVCardsDownloads: inout Int
    ) async {
        let uuids = contactsMatchedByUuid.map(\.uuidNormalisedForAutoImport)
        let contactIDByUuid = dependencies.contactService.getContactsByUUID(uuids).map(\.contactID)
        let emails = contactsMatchedByEmail.flatMap(\.emails)
        let contactIDByEmail = dependencies.contactService.getContactsByEmailAddress(emails).map(\.contactID)

        let contactIDs = contactIDByUuid + contactIDByEmail
        var numOfContactsWithoutVCard = 0
        let idsWithMissingVCards = getLimitedMissingVCardIds(
            from: contactIDs,
            numOfContactsWithoutVCard: &numOfContactsWithoutVCard
        )
        guard
            !isFirstImport, // more info: MAILIOS-4176
            !idsWithMissingVCards.isEmpty
        else {
            numOfSkippedVCardsDownloads = numOfContactsWithoutVCard
            return
        }
        numOfSkippedVCardsDownloads = max(0, numOfContactsWithoutVCard - maxVCardsDownloadsAllowed)

        let message = "fetching vCards for \(idsWithMissingVCards.count) Proton contacts"
        SystemLogger.log(message: message, category: .contacts)

        await dependencies.contactService.fetchContactsInParallel(contactIDs: idsWithMissingVCards)
    }

    private func reportTelemetryIfNeeded(
        isFirstImport: Bool,
        numContactsToCreate: Int,
        numContactsToUpdate: Int,
        numOfSkippedVCardsDownloads: Int
    ) async {
        guard isFirstImport else { return }
        await dependencies.telemetryService.sendEvent(
            .autoImportContacts(
                contactsToCreate: numContactsToCreate,
                contactsToUpdate: numContactsToUpdate,
                skippedVCardDownloads: numOfSkippedVCardsDownloads
            )
        )
    }

    private func getLimitedMissingVCardIds(
        from contactIDs: [ContactID],
        numOfContactsWithoutVCard: inout Int
    ) -> [ContactID] {
        let result = dependencies.contactService.getContactsWithoutVCards(from: contactIDs)
        numOfContactsWithoutVCard = result.count
        return Array(result.prefix(maxVCardsDownloadsAllowed))
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
        dependencies.contactSyncQueue.saveQueueToDisk()
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
        params: Params,
        numContactsToUpdate: inout Int
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
        dependencies.contactSyncQueue.saveQueueToDisk()

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
        dependencies.contactSyncQueue.saveQueueToDisk()

        numContactsToUpdate = totalContactsUpdatedByUuidMatch + totalContactsUpdatedByEmailMatch
        let finalUpdatesNumberMsg = "Final number of contacts to update \(numContactsToUpdate)"
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
        var errorCount = 0
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
                errorCount += 1
                if errorCount < 2 {
                    let msg = "mergeContactsMatchedByUuid uuid \(normalisedContactUuid.redacted) first error in batch"
                    SystemLogger.log(message: "\(msg): \(error)", category: .contacts, isError: true)
                }
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
        var errorCount = 0
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
                errorCount += 1
                if errorCount < 2 {
                    let message = "mergeContactsMatchByEmail uuid \(deviceContactUuid.redacted) first error in batch"
                    SystemLogger.log(message: "\(message): \(error)", category: .contacts, isError: true)
                }
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

    struct DeviceContactsToImport {
        let toCreate: [DeviceContactIdentifier]
        let toUpdateByUuidMatch: [DeviceContactIdentifier]
        let toUpdateByEmailMatch: [DeviceContactIdentifier]

        var toUpdateCount: Int {
            toUpdateByUuidMatch.count + toUpdateByEmailMatch.count
        }

        var description: String {
            let msgCreate = "Device contacts with no match (to create): \(toCreate.count)"
            let msgUpdateUuid = "with uuid match (update): \(toUpdateByUuidMatch.count)"
            let msgUpdateEmail = "with email match (update): \(toUpdateByEmailMatch.count)"
            return "\(msgCreate), \(msgUpdateUuid), \(msgUpdateEmail)"
        }

        /// Limits the number of contact tasks to be enqueued to the max number of contacts that Proton allows to create.
        /// The function will give priority to operations to update contacts since those already exist in Proton.
        func capNumberOfContactsIfNeeded(maxAllowed: Int) -> DeviceContactsToImport {
            let count = toCreate.count + toUpdateCount
            guard count > maxAllowed else { return self }

            // we will cap the number of tasks
            var newToCreate = toCreate
            var newToUpdateByUuidMatch = toUpdateByUuidMatch
            var newToUpdateByEmailMatch = toUpdateByEmailMatch

            if toUpdateCount > maxAllowed {
                newToCreate = []
                if toUpdateByUuidMatch.count > maxAllowed {
                    newToUpdateByEmailMatch = []
                    newToUpdateByUuidMatch = Array(toUpdateByUuidMatch.prefix(maxAllowed))
                }
                let remainingToUpdateAllowed = max(maxAllowed - newToUpdateByUuidMatch.count, 0)
                newToUpdateByEmailMatch = Array(toUpdateByEmailMatch.prefix(remainingToUpdateAllowed))
            }

            let newTotalToUpdate = newToUpdateByUuidMatch.count + newToUpdateByEmailMatch.count
            let remainingAllowed = max(maxAllowed - newTotalToUpdate, 0)
            newToCreate = Array(toCreate.prefix(remainingAllowed))

            let result = DeviceContactsToImport(
                toCreate: newToCreate,
                toUpdateByUuidMatch: newToUpdateByUuidMatch,
                toUpdateByEmailMatch: newToUpdateByEmailMatch
            )
            let message = "Number of contact operations capped at \(maxAllowed): \(result.description)"
            SystemLogger.log(message: message, category: .contacts)
            return result
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
