// Copyright (c) 2022 Proton Technologies AG
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
import SQLite

protocol ESIndexingStateProvider {
    func getESState(userID: UserID) -> EncryptedSearchIndexState
}

protocol ESFeatureStatusProvider {
    var isEncryptedSearchOn: Bool { get }
}

/// Temporary class for this file to able to be compiled.
/// This needs to be changed to load the actual ES state.
class TempEsStateProvider: ESIndexingStateProvider {
    func getESState(userID: UserID) -> EncryptedSearchIndexState {
        return .paused(nil)
    }
}

/// Temporary class for this file to able to be compiled.
/// This needs to be changed to load the actual ES enable status like user default.
class TempESEnableStatusProvider: ESFeatureStatusProvider {
    var isEncryptedSearchOn: Bool = false
}

/// This struct is used to store the cached index data fetched from the db.
struct IndexCacheData {
    let messageID: String
    let time: Int
    let order: Int
    let labelIDs: String
    let encryptionIV: String?
    let encryptedContent: String?
    let encryptedContentSize: Int
}

enum EncryptedSearchIndexError: Error {
    case encryptedSearchDisabled
    case searchIndexNotExist
    case indexInsertError(Error)
    case indexDeleteError(Error)
    case indexUpdateError(Error)
    case databaseDeleteError(Error)
}

// swiftlint:disable type_body_length
final class EncryptedSearchIndexService {
    private var databaseConnections = [UserID: Connection]()
    /// This field stores the definition of the ES database entry.
    private var databaseSchema: DatabaseEntries
    private var searchableMessages: Table
    private let fileByteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useAll
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()
    private let userID: UserID

    private let esStateProvider: ESIndexingStateProvider
    private let esEnableStatusProvider: ESFeatureStatusProvider

    struct DatabaseEntries {
        var messageID: Expression<String> = Expression(value: "")
        var time: Expression<Int> = Expression(value: 0)
        var order: Expression<Int> = Expression(value: 0)
        var labelIDs: Expression<String> = Expression(value: "")
        var encryptionIV: Expression<String?> = Expression(value: nil)
        var encryptedContent: Expression<String?> = Expression(value: nil)
        var encryptedContentFile: Expression<String?> = Expression(value: nil)
        var encryptedContentSize: Expression<Int> = Expression(value: 0)
    }

    struct Constant {
        static let expectedESState: [EncryptedSearchIndexState] = [
            .downloading,
            .refresh,
            .background,
            .complete,
            .partial,
            .paused(nil),
            .lowstorage,
            .metadataIndexing
        ]
    }

    init(
        userID: UserID,
        esStateProvider: ESIndexingStateProvider = TempEsStateProvider(),
        esEnableStatusProvider: ESFeatureStatusProvider = TempESEnableStatusProvider()
    ) {
        self.userID = userID
        databaseSchema = DatabaseEntries()
        searchableMessages = Table(DatabaseConstants.TableSearchableMessages)
        self.esStateProvider = esStateProvider
        self.esEnableStatusProvider = esEnableStatusProvider
        self.createDatabaseSchema()
    }

    func connectToSearchIndex() -> Connection? {
        if self.databaseConnections[userID] != nil {
            return self.databaseConnections[userID]
        }

        // If there is not a connection yet, we create one
        let dbName: String = Self.getSearchIndexName(userID)
        let pathToDB: String = Self.getSearchIndexPathToDB(dbName)
        do {
            let handleToSQliteDB = try Connection(pathToDB)
            handleToSQliteDB.busyTimeout = 5 // Database locked after 5 seconds - retry multiple times
            self.databaseConnections[userID] = handleToSQliteDB
            return self.databaseConnections[userID]
        } catch {
            SystemLogger.log(
                message: "Error: Create database connection. Unexpected error: \(error).",
                category: .encryptedSearch,
                isError: true
            )
            return nil
        }
    }

    func forceCloseDatabaseConnection() {
        guard self.databaseConnections[userID] != nil else {
            SystemLogger.log(
                message: "Error when closing db connection. Connection is nil!",
                category: .encryptedSearch,
                isError: true
            )
            return
        }

        // Deallocating the connection should close any pointer to the database
        sqlite3_close_v2(self.databaseConnections[userID]?.handle)
        self.databaseConnections[userID] = nil
    }

    private enum DatabaseConstants {
        static let TableSearchableMessages = "SearchableMessage"
        static let messageID = "ID"
        static let messageTime = "Time"
        static let messageOrder = "MessageOrder"
        static let messageLabels = "LabelIDs"
        static let messageLocation = "Location"
        static let messageDecryptionFailed = "DecryptionFailed"
        static let messageEncryptedContent = "EncryptedContent"
        static let messageEncryptedContentFile = "EncryptedContentFile"
        static let messageEncryptionIV = "EncryptionIV"
        static let messageEncryptedContentSize = "Size"
    }

    @discardableResult
    func createSearchIndexDBIfNotExisting() -> Bool {
        guard !Self.checkIfSearchIndexExists(for: userID) else {
            SystemLogger.log(
                message: "Search index already exists.",
                category: .encryptedSearch
            )
            return false
        }
        SystemLogger.log(
            message: "Create search index table.",
            category: .encryptedSearch
        )
        self.createSearchIndexTable()
        return true
    }

    private func createDatabaseSchema() {
        databaseSchema =
            DatabaseEntries(
                messageID: Expression<String>(DatabaseConstants.messageID),
                time: Expression<Int>(DatabaseConstants.messageTime),
                order: Expression<Int>(DatabaseConstants.messageOrder),
                labelIDs: Expression<String>(DatabaseConstants.messageLabels),
                encryptionIV: Expression<String?>(DatabaseConstants.messageEncryptionIV),
                encryptedContent: Expression<String?>(
                    DatabaseConstants.messageEncryptedContent),
                encryptedContentFile: Expression<String?>(
                    DatabaseConstants.messageEncryptedContentFile),
                encryptedContentSize: Expression<Int>(
                    DatabaseConstants.messageEncryptedContentSize)
            )
    }

    private func createSearchIndexTable() {
        self.createDatabaseSchema()

        do {
            let connection = self.connectToSearchIndex()
            try connection?.run(self.searchableMessages.create(ifNotExists: true) { table in
                table.column(self.databaseSchema.messageID, primaryKey: true)
                table.column(self.databaseSchema.time, defaultValue: 0)
                table.column(self.databaseSchema.order, defaultValue: 0)
                table.column(self.databaseSchema.labelIDs)
                table.column(self.databaseSchema.encryptionIV, defaultValue: nil)
                table.column(self.databaseSchema.encryptedContent, defaultValue: nil)
                table.column(self.databaseSchema.encryptedContentFile, defaultValue: nil)
                table.column(self.databaseSchema.encryptedContentSize, defaultValue: -1)
            })
        } catch {
            SystemLogger.log(
                message: "Create Table. Unexpected error: \(error).",
                category: .encryptedSearch,
                isError: true
            )
        }
    }

    // swiftlint:disable function_parameter_count
    func addNewEntryToSearchIndex(
        messageID: MessageID,
        time: Int,
        order: Int,
        labelIDs: [LabelEntity],
        encryptionIV: String?,
        encryptedContent: String?,
        encryptedContentFile: String,
        encryptedContentSize: Int
    ) throws -> Int? {
        guard Constant.expectedESState.containsCase(
            esStateProvider.getESState(userID: userID)
        ) else {
            throw EncryptedSearchIndexError.encryptedSearchDisabled
        }

        var labels: Set<String> = Set()
        labelIDs.forEach { label in
            labels.insert(label.labelID.rawValue)
        }
        do {
            let insert: Insert = self.searchableMessages.insert(
                self.databaseSchema.messageID <- messageID.rawValue,
                self.databaseSchema.time <- time,
                self.databaseSchema.order <- order,
                self.databaseSchema.labelIDs <- labels.joined(separator: ";"),
                self.databaseSchema.encryptionIV <- encryptionIV,
                self.databaseSchema.encryptedContent <- encryptedContent,
                self.databaseSchema.encryptedContentFile <- encryptedContentFile,
                self.databaseSchema.encryptedContentSize <- encryptedContentSize
            )
            let connection = self.connectToSearchIndex()
            let rowID = try connection?.run(insert)

            if let rowID = rowID, rowID != -1 {
                return Int(rowID)
            } else {
                return nil
            }
        } catch {
            SystemLogger.log(
                message: "Insert in Table. Unexpected error: \(error).",
                category: .encryptedSearch,
                isError: true
            )
            throw EncryptedSearchIndexError.indexInsertError(error)
        }
    }

    func removeEntryFromSearchIndex(message messageID: MessageID) throws -> Int? {
        guard shouldIndexActionContinue() else {
            throw EncryptedSearchIndexError.encryptedSearchDisabled
        }

        let filter = self.searchableMessages.filter(self.databaseSchema.messageID == messageID.rawValue)
        var rowID: Int? = -1
        do {
            let connection = self.connectToSearchIndex()
            rowID = try connection?.run(filter.delete())
        } catch {
            SystemLogger.log(
                message: "Error: deleting messages from search index failed: \(error)",
                category: .encryptedSearch,
                isError: true
            )
            throw EncryptedSearchIndexError.indexDeleteError(error)
        }
        return rowID
    }

    func updateEntryInSearchIndex(
        messageID: MessageID,
        encryptedContent: String,
        encryptionIV: String,
        encryptedContentSize: Int
    ) {
        guard shouldIndexActionContinue() else {
            return
        }

        let messageToUpdate = self.searchableMessages.filter(self.databaseSchema.messageID == messageID.rawValue)

        do {
            let query = messageToUpdate.update(self.databaseSchema.encryptedContent <- encryptedContent,
                                               self.databaseSchema.encryptionIV <- encryptionIV,
                                               self.databaseSchema.encryptedContentSize <- encryptedContentSize)
            var connection = self.connectToSearchIndex()
            let updatedRows: Int? = try connection?.run(query)
            connection = nil
            if let updatedRows = updatedRows {
                if updatedRows <= 0 {
                    SystemLogger.log(
                        message: "Error: Message not found in search index - less than 0 results found",
                        category: .encryptedSearch,
                        isError: true
                    )
                }
            } else {
                SystemLogger.log(
                    message: "Error: Message not found in search index - updated row nil",
                    category: .encryptedSearch,
                    isError: true
                )
            }
        } catch {
            SystemLogger.log(
                message: "Error: updating message in search index failed: \(error)",
                category: .encryptedSearch,
                isError: true
            )
        }
    }

    // TODO: Uncomment this part after importing the crypto with ES support.
//    func getDBParams(_ userID: UserID) -> EncryptedsearchDBParams? {
//        let dbName: String = self.getSearchIndexName(userID)
//        let pathToDB: String = self.getSearchIndexPathToDB(dbName)
//
//        return EncryptedsearchNewDBParams(pathToDB,
//                                          DatabaseConstants.TableSearchableMessages,
//                                          DatabaseConstants.ColumnSearchableMessageId,
//                                          DatabaseConstants.ColumnSearchableMessageTime,
//                                          DatabaseConstants.ColumnSearchableMessageOrder,
//                                          DatabaseConstants.ColumnSearchableMessageLabels,
//                                          DatabaseConstants.ColumnSearchableMessageEncryptionIV,
//                                          DatabaseConstants.ColumnSearchableMessageEncryptedContent,
//                                          DatabaseConstants.ColumnSearchableMessageEncryptedContentFile)
//    }

    func getNumberOfEntriesInSearchIndex() -> Int {
        // If there is no search index for an user, then the number of entries is zero
        if Self.checkIfSearchIndexExists(for: userID) == false {
            return -2
        }

        guard shouldIndexActionContinue() else {
            return -1
        }

        var numberOfEntries: Int = -1
        do {
            let connection = self.connectToSearchIndex()
            numberOfEntries = try connection?.scalar(self.searchableMessages.count) ?? 0
        } catch {
            SystemLogger.log(
                message: "Error when getting the number of entries in the search index: \(error)",
                category: .encryptedSearch,
                isError: true
            )
        }

        return numberOfEntries
    }

    func deleteSearchIndex() throws {
        self.forceCloseDatabaseConnection()

        // Delete database on file
        let dbName: String = Self.getSearchIndexName(userID)
        let pathToDB: String = Self.getSearchIndexPathToDB(dbName)

        if FileManager.default.fileExists(atPath: pathToDB) {
            do {
                try FileManager.default.removeItem(atPath: pathToDB)
            } catch {
                SystemLogger.log(
                    message: "Error when deleting the search index: \(error)",
                    category: .encryptedSearch,
                    isError: true
                )
                throw EncryptedSearchIndexError.databaseDeleteError(error)
            }
        } else {
            SystemLogger.log(
                message: "Error: cannot find search index at path: \(pathToDB)",
                category: .encryptedSearch,
                isError: true
            )
        }
    }

    func shrinkSearchIndex(expectedSize: Int) -> Bool {
        guard shouldIndexActionContinue() else {
            return false
        }
        SystemLogger.log(
            message: "ES: shrink search index!",
            category: .encryptedSearch
        )

        let sizeOfSearchIndex = self.getSizeOfSearchIndex().size ?? 0
        SystemLogger.log(
            message: "size of search index: \(sizeOfSearchIndex)",
            category: .encryptedSearch
        )

        var sizeOfDeletedMessages = 0
        // in a loop delete messages until it fits the expected size
        var stopResizing = false
        while true {
            // Get the size of the encrypted content for the oldest message
            let messageSize = self.estimateSizeOfRowToDelete()
            SystemLogger.log(
                message: "message size: \(messageSize)",
                category: .encryptedSearch
            )
            sizeOfDeletedMessages += messageSize

            if sizeOfSearchIndex - sizeOfDeletedMessages < expectedSize {
                stopResizing = true
            }

            // remove last message in the search index
            let deletedRow = self.removeLastEntryInSearchIndex()
            let sizeOfIndex = getSizeOfSearchIndex().size ?? 0
            SystemLogger.log(
                message: "successfully deleted row: \(deletedRow), size of index: \(sizeOfIndex)",
                category: .encryptedSearch
            )
            if deletedRow == -1 || stopResizing {
                break
            }
        }
        return true
    }

    private func removeLastEntryInSearchIndex() -> Int {
        var rowID: Int? = -1
        do {
            // Check if there are still entries in the db
            var connection = self.connectToSearchIndex()
            let numberOfEntries = try connection?.scalar(self.searchableMessages.count)
            connection = nil
            if numberOfEntries == 0 {
                return -1
            }

            let time: Expression<Int> = self.databaseSchema.time
            let query = self.searchableMessages.select(time).order(time.asc).limit(1)
            connection = self.connectToSearchIndex()
            rowID = try connection?.run(query.delete())

            try connection?.vacuum()
            // Flush the db cache to make the size measure more precise
            // Blocks all write statements until delete is done
            // Details here: https://sqlite.org/pragma.html#pragma_wal_checkpoint
            try connection?.run("pragma wal_checkpoint(full)")
            connection = nil
        } catch {
            SystemLogger.log(
                message: "Deleting the oldest message from search index failed: \(error)",
                category: .encryptedSearch,
                isError: true
            )
        }
        return rowID ?? -1
    }

    private func estimateSizeOfRowToDelete() -> Int {
        var sizeOfRow: Int = -1
        do {
            let time: Expression<Int> = self.databaseSchema.time
            let size: Expression<Int> = self.databaseSchema.encryptedContentSize
            let query = self.searchableMessages.select(size).order(time.asc).limit(1)

            if let connection = self.connectToSearchIndex() {
                for result in try connection.prepare(query) {
                    sizeOfRow = result[size]
                }
            }
        } catch {
            SystemLogger.log(
                message: "Deleting the oldest message from search index failed: \(error)",
                category: .encryptedSearch,
                isError: true
            )
        }
        return sizeOfRow
    }

    func getSizeOfSearchIndex() -> (size: Int?, asString: String) {
        let dbName: String = Self.getSearchIndexName(userID)
        let pathToDB: String = Self.getSearchIndexPathToDB(dbName)

        var size = ""
        var sizeOfIndex: Int? = 0
        if FileManager.default.fileExists(atPath: pathToDB) {
            // Check size of file
            let dbUrl = URL(fileURLWithPath: pathToDB)
            sizeOfIndex = dbUrl.fileSize
            size = (fileByteCountFormatter.string(fromByteCount: Int64(sizeOfIndex ?? 0)))
        } else {
            SystemLogger.log(
                message: "Error: cannot find search index at path: \(pathToDB)",
                category: .encryptedSearch,
                isError: true
            )
        }

        return (sizeOfIndex, size)
    }

    func getOldestMessageInSearchIndex() -> (asInt: Int, asString: String) {
        guard shouldIndexActionContinue() else {
            return (0, "")
        }

        let time: Expression<Int> = self.databaseSchema.time
        let query = self.searchableMessages.select(time).order(time.asc).limit(1)

        var timeInSeconds = 0
        do {
            if let connection = self.connectToSearchIndex() {
                for result in try connection.prepare(query) {
                    timeInSeconds = result[time]
                }
            }
        } catch {
            SystemLogger.log(
                message: "Error when querying oldest message in search index: \(error)",
                category: .encryptedSearch,
                isError: true
            )
        }
        return (timeInSeconds, Self.timeToDateString(time: timeInSeconds))
    }

    func getListOfMessagesInSearchIndex(endDate: Date) -> [IndexCacheData] {
        var cachedData: [IndexCacheData] = []

        let endDateAsUnixTimeStamp = Int(endDate.timeIntervalSince1970)
        let query = searchableMessages.select(
            databaseSchema.messageID,
            databaseSchema.time,
            databaseSchema.order,
            databaseSchema.labelIDs,
            databaseSchema.encryptionIV,
            databaseSchema.encryptedContent,
            databaseSchema.encryptedContentSize
        ).order(
            databaseSchema.time.desc
        ).where(
            databaseSchema.time >= endDateAsUnixTimeStamp
        )

        do {
            if let connection = connectToSearchIndex() {
                for result in try connection.prepare(query) {
                    let data = IndexCacheData(
                        messageID: result[databaseSchema.messageID],
                        time: result[databaseSchema.time],
                        order: result[databaseSchema.order],
                        labelIDs: result[databaseSchema.labelIDs],
                        encryptionIV: result[databaseSchema.encryptionIV],
                        encryptedContent: result[databaseSchema.encryptedContent],
                        encryptedContentSize: result[databaseSchema.encryptedContentSize]
                    )
                    cachedData.append(data)
                }
            }
        } catch {
            SystemLogger.log(
                message: "Error when querying list of message ids in search index: \(error)",
                category: .encryptedSearch,
                isError: true
            )
        }

        return cachedData
    }

    func getMessageIDOfOldestMessageInSearchIndex() -> String? {
        guard shouldIndexActionContinue() else {
            return nil
        }

        let time: Expression<Int> = self.databaseSchema.time
        let id: Expression<String> = self.databaseSchema.messageID
        let query = self.searchableMessages.select(id).order(time.asc).limit(1)

        var idOfOldestMessage: String?
        do {
            if let connection = self.connectToSearchIndex() {
                for result in try connection.prepare(query) {
                    idOfOldestMessage = result[id]
                }
            }
        } catch {
            SystemLogger.log(
                message: "Error when querying oldest message in search index: \(error)",
                category: .encryptedSearch,
                isError: true
            )
        }
        return idOfOldestMessage
    }

    private func shouldIndexActionContinue() -> Bool {
        if esEnableStatusProvider.isEncryptedSearchOn == false ||
            esStateProvider.getESState(userID: userID) == .disabled {
            return false
        }
        return true
    }

    // MARK: - Static methods

    static func timeToDateString(time: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(time))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter.string(from: date)
    }

    static func getSearchIndexName(_ userID: UserID) -> String {
        let dbName = "encryptedSearchIndex"
        let fileExtension = "sqlite3"
        return dbName + "_" + userID.rawValue + "." + fileExtension
    }

    static func getSearchIndexPathToDB(_ dbName: String) -> String {
        let documentsDirectoryURL = try? FileManager.default.url(for: .documentDirectory,
                                                                 in: .userDomainMask,
                                                                 appropriateFor: nil,
                                                                 create: false)
        let urlToSearchIndex = documentsDirectoryURL?.appendingPathComponent(dbName)
        return urlToSearchIndex?.relativePath ?? ""
    }

    static func checkIfSearchIndexExists(for userID: UserID) -> Bool {
        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)

        if FileManager.default.fileExists(atPath: pathToDB) {
            return true
        }

        return false
    }
}

#if DEBUG
extension EncryptedSearchIndexService {
    func getDBConnectionsDictionary() -> [UserID: Connection] {
        return databaseConnections
    }

    func getSearchableMessagesTable() -> Table {
        return searchableMessages
    }

    func getDatabaseSchema() -> DatabaseEntries {
        return databaseSchema
    }
}
#endif
