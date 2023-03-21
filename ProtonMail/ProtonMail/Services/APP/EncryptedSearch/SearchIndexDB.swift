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
import SQLite

extension SearchIndexDB {
    private struct DatabaseEntries {
        var messageID: Expression<String> = Expression(value: "")
        var time: Expression<Int> = Expression(value: 0)
        var order: Expression<Int> = Expression(value: 0)
        var labelIDs: Expression<String> = Expression(value: "")
        var encryptionIV: Expression<String?> = Expression(value: nil)
        var encryptedContent: Expression<String?> = Expression(value: nil)
        var encryptedContentFile: Expression<String?> = Expression(value: nil)
        var encryptedContentSize: Expression<Int> = Expression(value: 0)
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

    enum IndexError: Error {
        case encryptedSearchDisabled
        case connectionNotExist
        case databasePathNotFound
        case searchIndexNotExist
        case unexpectedOperationResult
        case insertError(Error)
        case deleteError(Error)
        case updateError(Error)
        case databaseDeleteError(Error)
    }
}

final class SearchIndexDB {
    private let fileManager: FileManagerProtocol
    private let userID: UserID
    /// Don't use this var directly, use `connectionToDB()` instead
    private var connection: Connection?
    /// This field stores the definition of the ES database entry.
    private var databaseSchema: DatabaseEntries = DatabaseEntries()
    private var messagesTable: Table

    init(
        fileManager: FileManagerProtocol = FileManager.default,
        userID: UserID
    ) {
        self.fileManager = fileManager
        self.userID = userID
        self.messagesTable = Table(DatabaseConstants.TableSearchableMessages)
        createDatabaseSchema()
    }

    /// - Returns: `true` create a DB, `false` DB already exists
    func createIfNeeded() {
        if !dbExists {
            log(message: "Create search index table")
            createDB()
        }
    }

    var size: ByteCount? {
        guard let path = dbPath,
              fileManager.fileExists(atPath: path.relativePath) else { return nil }
        return path.fileSize as ByteCount
    }

    var dbExists: Bool {
        guard let path = dbPath else { return false }
        return fileManager.fileExists(atPath: path.relativePath)
    }

    func numberOfEntries() throws -> Int {
        let connection = try connectionToDB()
        let numberOfEntries = try connection.scalar(messagesTable.count)
        return numberOfEntries
    }

    func shrinkSearchIndex(expectedSize: ByteCount) throws {
        guard expectedSize > 0, let size = size, size > expectedSize else { return }
        var sizeOfDeletedMessages: ByteCount = 0
        var continueShrinking = true
        while continueShrinking {
            let messageSize = try estimateSizeOfOldestRowInSearchIndex()
            sizeOfDeletedMessages += messageSize
            let deletedRowID = try removeOldestRowInSearchIndex()
            let isDatabaseStillTooBig = size - sizeOfDeletedMessages > expectedSize
            continueShrinking = deletedRowID > 0 && isDatabaseStillTooBig
        }
    }

    // swiftlint:disable:next function_parameter_count
    func addNewEntryToSearchIndex(
        messageID: MessageID,
        time: Int,
        order: Int,
        labelIDs: [LabelID],
        encryptionIV: String?,
        encryptedContent: String?,
        encryptedContentFile: String,
        encryptedContentSize: Int
    ) throws -> Int? {
        let labels = labelIDs.map { $0.rawValue }.uniqued

        do {
            let insert: Insert = messagesTable.insert(
                databaseSchema.messageID <- messageID.rawValue,
                databaseSchema.time <- time,
                databaseSchema.order <- order,
                databaseSchema.labelIDs <- labels.joined(separator: ";"),
                databaseSchema.encryptionIV <- encryptionIV,
                databaseSchema.encryptedContent <- encryptedContent,
                databaseSchema.encryptedContentFile <- encryptedContentFile,
                databaseSchema.encryptedContentSize <- encryptedContentSize
            )
            let connection = try connectionToDB()
            // An ID to represent new adding data is saved to which row
            let rowID = Int(try connection.run(insert))
            return rowID
        } catch {
            log(message: "Insert in Table. Unexpected error: \(error).", isError: true)
            throw IndexError.insertError(error)
        }
    }

    /// - Returns: `true` if a record has been updated, `false` otherwise
    func updateEntryInSearchIndex(
        messageID: MessageID,
        encryptedContent: String,
        encryptionIV: String,
        encryptedContentSize: Int
    ) throws -> Bool {
        let messageToUpdate = messagesTable.filter(databaseSchema.messageID == messageID.rawValue)
        do {
            let query = messageToUpdate.update(
                databaseSchema.encryptedContent <- encryptedContent,
                databaseSchema.encryptionIV <- encryptionIV,
                databaseSchema.encryptedContentSize <- encryptedContentSize
            )

            let connection = try connectionToDB()
            let numOfUpdatedRows = try connection.run(query)
            if numOfUpdatedRows <= 0 {
                log(
                    message: "Update entry failed, no match entry, messageID: \(messageID.rawValue)",
                    isError: true
                )
                return false
            } else {
                return true
            }
        } catch {
            log(message: "Update entry failed, error: \(error)", isError: true)
            throw IndexError.updateError(error)
        }
    }

    // TODO isEncryptedSearchOn and currentState shouldn't be part of this class, better to move to buildSearchIndex
    /// - Returns: `Bool`, `true` found target entry and delete it, `false` otherwise
    func removeEntryFromSearchIndex(
        isEncryptedSearchOn: Bool,
        currentState: EncryptedSearchIndexState,
        messageID: MessageID
    ) throws -> Bool {
        if isEncryptedSearchOn == false || currentState == .disabled {
            throw IndexError.encryptedSearchDisabled
        }
        let filter = messagesTable.filter(databaseSchema.messageID == messageID.rawValue)
        do {
            let connection = try connectionToDB()
            let numOfRowToRemoved = try connection.run(filter.delete())
            // MessageID is a primaryKey. There cannot be more than one.
            return numOfRowToRemoved == 1
        } catch {
            log(message: "Error: deleting messages from search index failed: \(error)", isError: true)
            throw IndexError.deleteError(error)
        }
    }

    func getDBParams() -> EncryptedSearchDBParams? {
        guard let path = dbPath else { return nil }
        return EncryptedSearchDBParams(
            path.relativePath,
            table: DatabaseConstants.TableSearchableMessages,
            id: DatabaseConstants.messageID,
            time: DatabaseConstants.messageTime,
            order: DatabaseConstants.messageOrder,
            labels: DatabaseConstants.messageLabels,
            initVector: DatabaseConstants.messageEncryptionIV,
            content: DatabaseConstants.messageEncryptedContent,
            contentFile: DatabaseConstants.messageEncryptedContentFile
        )
    }

    /// - Returns: timestamp
    func oldestMessageTime() -> Int? {
        var timeStamp: Int?
        do {
            let time: Expression<CLong> = databaseSchema.time
            let query = messagesTable.select(time).order(time.asc).limit(1)
            let connection = try connectionToDB()
            for result in try connection.prepare(query) {
                timeStamp = result[time]
                break
            }
        } catch {
            log(message: "Get oldest message time failed: \(error)", isError: true)
        }
        return timeStamp
    }

    func deleteSearchIndex() throws {
        forceCloseConnection()
        guard let path = dbPath else { return }
        guard fileManager.fileExists(atPath: path.relativePath) else {
            log(message: "Can't find search index at \(path)", isError: true)
            return
        }
        do {
            try fileManager.removeItem(atPath: path.relativePath)
        } catch {
            log(message: "Error when deleting the search index: \(error)", isError: true)
            throw IndexError.databaseDeleteError(error)
        }
    }
}

// MARK: - Helper
extension SearchIndexDB {
    private var dbName: String {
        let dbName = "encryptedSearchIndex"
        let fileExtension = "sqlite3"
        return "\(dbName)_\(userID.rawValue).\(fileExtension)"
    }

    private var dbPath: URL? {
        let documentsDirectoryURL = try? fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        let urlToSearchIndex = documentsDirectoryURL?.appendingPathComponent(dbName)
        return urlToSearchIndex
    }

    private func log(message: String, isError: Bool = false) {
        SystemLogger.log(message: message, category: .encryptedSearch, isError: isError)
    }
}

// MARK: - Create DB
extension SearchIndexDB {
    private func createDB() {
        createDatabaseSchema()

        do {
            let connection = try connectionToDB()
            try connection.run(messagesTable.create(ifNotExists: true) { table in
                table.column(databaseSchema.messageID, primaryKey: true)
                table.column(databaseSchema.time, defaultValue: 0)
                table.column(databaseSchema.order, defaultValue: 0)
                table.column(databaseSchema.labelIDs)
                table.column(databaseSchema.encryptionIV, defaultValue: nil)
                table.column(databaseSchema.encryptedContent, defaultValue: nil)
                table.column(databaseSchema.encryptedContentFile, defaultValue: nil)
                table.column(databaseSchema.encryptedContentSize, defaultValue: -1)
            })
        } catch {
            log(message: "Create Table. Unexpected error: \(error).", isError: true)
        }
    }

    private func createDatabaseSchema() {
        databaseSchema = DatabaseEntries(
            messageID: Expression<String>(DatabaseConstants.messageID),
            time: Expression<Int>(DatabaseConstants.messageTime),
            order: Expression<Int>(DatabaseConstants.messageOrder),
            labelIDs: Expression<String>(DatabaseConstants.messageLabels),
            encryptionIV: Expression<String?>(DatabaseConstants.messageEncryptionIV),
            encryptedContent: Expression<String?>(DatabaseConstants.messageEncryptedContent),
            encryptedContentFile: Expression<String?>(DatabaseConstants.messageEncryptedContentFile),
            encryptedContentSize: Expression<Int>(DatabaseConstants.messageEncryptedContentSize)
        )
    }

    private func connectionToDB() throws -> Connection {
        if let connection = self.connection {
            return connection
        }
        guard let path = dbPath else {
            throw IndexError.databasePathNotFound
        }
        let connection = try Connection(path.relativePath)
        connection.busyTimeout = 5 // Database locked after 5 seconds - retry multiple times
        self.connection = connection
        return connection
    }
}

// MARK: - Shrink the size of the local db
extension SearchIndexDB {
    /// - Returns: row size
    private func estimateSizeOfOldestRowInSearchIndex() throws -> Int {
        var sizeOfRow: Int = 0
        let time: Expression<CLong> = databaseSchema.time
        let size: Expression<Int> = databaseSchema.encryptedContentSize
        let query = messagesTable.select(size).order(time.asc).limit(1)

        let connection = try connectionToDB()
        for result in try connection.prepare(query) {
            sizeOfRow = result[size]
        }
        return sizeOfRow
    }

    /// - Returns: number of delete rows
    private func removeOldestRowInSearchIndex() throws -> Int {
        let connection = try connectionToDB()
        if try connection.scalar(messagesTable.count) == 0 { return 0 }

        let time: Expression<CLong> = databaseSchema.time
        let query = messagesTable.select(time).order(time.asc).limit(1)

        let numOfDeletedRow = try connection.run(query.delete())

        try connection.vacuum()
        // Flush the db cache to make the size measure more precise
        // Blocks all write statements until delete is done
        // Details here: https://sqlite.org/pragma.html#pragma_wal_checkpoint
        try connection.run("pragma wal_checkpoint(full)")
        return numOfDeletedRow
    }
}

// MARK: - Delete DB
extension SearchIndexDB {
    private func forceCloseConnection() {
        guard let connection = self.connection else {
            log(message: "Error when closing db connection. Connection is nil!", isError: true)
            return
        }
        // https://www.sqlite.org/c3ref/close.html
        sqlite3_close_v2(connection.handle)
        self.connection = nil
    }
}
