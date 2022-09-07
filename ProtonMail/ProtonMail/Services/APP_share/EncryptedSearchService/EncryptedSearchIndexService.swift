//
//  EncryptedSearchIndexService.swift
//  ProtonMail
//
//  Created by Ralph Ankele on 19.07.21.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import Crypto
import Foundation
import SQLite

public class EncryptedSearchIndexService {
    // instance of Singleton
    static let shared = EncryptedSearchIndexService()

    // set initializer to private - Singleton
    private init() {
        searchIndexSemaphore = DispatchSemaphore(value: 1)  // Semaphore to lock access to database
        databaseSchema = DatabaseEntries()
        searchableMessages = Table(DatabaseConstants.TableSearchableMessages)
        fileByteCountFormatter = ByteCountFormatter()
        fileByteCountFormatter?.allowedUnits = .useAll
        fileByteCountFormatter?.countStyle = .file
        fileByteCountFormatter?.includesUnit = true
        fileByteCountFormatter?.isAdaptive = true
        self.createDatabaseSchema()
    }

    internal var databaseConnections = [String: Connection]()
    internal var databaseSchema: DatabaseEntries
    internal var searchableMessages: Table

    private var fileByteCountFormatter: ByteCountFormatter?
    internal let searchIndexSemaphore: DispatchSemaphore
}

extension EncryptedSearchIndexService {
    struct DatabaseEntries {
        var messageID: Expression<String> = Expression(value: "")
        var time: Expression<CLong> = Expression(value: 0)
        var order: Expression<CLong> = Expression(value: 0)
        var labelIDs: Expression<String> = Expression(value: "")
        var encryptionIV: Expression<String?> = Expression(value: nil)
        var encryptedContent: Expression<String?> = Expression(value: nil)
        var encryptedContentFile: Expression<String?> = Expression(value: nil)
        var encryptedContentSize: Expression<Int> = Expression(value: 0)
    }

    func connectToSearchIndex(userID: String) -> Connection? {
        // If there is already a connection - return it
        if self.databaseConnections[userID] != nil {
            return self.databaseConnections[userID]
        }

        // If there is not a connection yet, we create one
        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)
        do {
            let handleToSQliteDB = try Connection(pathToDB)
            handleToSQliteDB.busyTimeout = 5 // Database locked after 5 seconds - retry multiple times
            self.databaseConnections[userID] = handleToSQliteDB
            return self.databaseConnections[userID]
        } catch {
            print("Error: Create database connection. Unexpected error: \(error).")
        }
        return nil
    }

    func forceCloseDatabaseConnection(userID: String) {
        guard self.databaseConnections[userID] != nil else {
            print("Error when closing db connection. Connection is nil!")
            return
        }

        // Deallocating the connection should close any pointer to the database
        sqlite3_close_v2(self.databaseConnections[userID]?.handle)
        self.databaseConnections[userID] = nil
    }

    enum DatabaseConstants {
        static let TableSearchableMessages = "SearchableMessage"
        static let ColumnSearchableMessageId = "ID"
        static let ColumnSearchableMessageTime = "Time"
        static let ColumnSearchableMessageOrder = "MessageOrder"
        static let ColumnSearchableMessageLabels = "LabelIDs"
        static let ColumnSearchableMessageLocation = "Location"
        static let ColumnSearchableMessageDecryptionFailed = "DecryptionFailed"
        static let ColumnSearchableMessageEncryptedContent = "EncryptedContent"
        static let ColumnSearchableMessageEncryptedContentFile = "EncryptedContentFile"
        static let ColumnSearchableMessageEncryptionIV = "EncryptionIV"
        static let ColumnSearchableMessageEncryptedContentSize = "Size"
    }

    func createSearchIndexDBIfNotExisting(userID: String) {
        // Check if db file already exists
        if self.checkIfSearchIndexExists(for: userID) == false {
            print("Create search index table.")
            self.createSearchIndexTable(userID: userID)
        } else {
            print("Search index already exists.")
        }
    }

    func createDatabaseSchema() {
        self.databaseSchema =
        DatabaseEntries(messageID: Expression<String>(DatabaseConstants.ColumnSearchableMessageId),
                        time: Expression<CLong>(DatabaseConstants.ColumnSearchableMessageTime),
                        order: Expression<CLong>(DatabaseConstants.ColumnSearchableMessageOrder),
                        labelIDs: Expression<String>(DatabaseConstants.ColumnSearchableMessageLabels),
                        encryptionIV: Expression<String?>(DatabaseConstants.ColumnSearchableMessageEncryptionIV),
                        encryptedContent: Expression<String?>(
                            DatabaseConstants.ColumnSearchableMessageEncryptedContent),
                        encryptedContentFile: Expression<String?>(
                            DatabaseConstants.ColumnSearchableMessageEncryptedContentFile),
                        encryptedContentSize: Expression<Int>(
                            DatabaseConstants.ColumnSearchableMessageEncryptedContentSize)
                        )
    }

    func createSearchIndexTable(userID: String) {
        self.createDatabaseSchema()

        do {
            self.searchIndexSemaphore.wait()
            var connection = self.connectToSearchIndex(userID: userID)
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
            connection = nil
            self.searchIndexSemaphore.signal()
        } catch {
            self.searchIndexSemaphore.signal()
            print("Create Table. Unexpected error: \(error).")
        }
    }

    // swiftlint:disable function_parameter_count
    func addNewEntryToSearchIndex(userID: String,
                                  messageID: MessageID,
                                  time: Int,
                                  order: Int,
                                  labelIDs: [LabelEntity],
                                  encryptionIV: String?,
                                  encryptedContent: String?,
                                  encryptedContentFile: String,
                                  encryptedContentSize: Int) -> Int64? {
        let expectedESStates: [EncryptedSearchService.EncryptedSearchIndexState] = [.downloading,
                                                                                    .refresh,
                                                                                    .background,
                                                                                    .complete,
                                                                                    .partial,
                                                                                    .paused,
                                                                                    .lowstorage,
                                                                                    .metadataIndexing]
        if expectedESStates.contains(EncryptedSearchService.shared.getESState(userID: userID)) {
            var labels: Set<String> = Set()
            labelIDs.forEach { label in
                labels.insert(label.labelID.rawValue)
            }
            do {
                self.searchIndexSemaphore.wait()
                let insert: Insert = self.searchableMessages.insert(
                    self.databaseSchema.messageID <- messageID.rawValue,
                    self.databaseSchema.time <- time,
                    self.databaseSchema.order <- order,
                    self.databaseSchema.labelIDs <- labels.joined(separator: ";"),
                    self.databaseSchema.encryptionIV <- encryptionIV,
                    self.databaseSchema.encryptedContent <- encryptedContent,
                    self.databaseSchema.encryptedContentFile <- encryptedContentFile,
                    self.databaseSchema.encryptedContentSize <- encryptedContentSize)
                var connection = self.connectToSearchIndex(userID: userID)
                let rowID = try connection?.run(insert)
                connection = nil
                self.searchIndexSemaphore.signal()
                if rowID != -1 {
                    return rowID
                }
            } catch {
                print("Insert in Table. Unexpected error: \(error).")
                self.searchIndexSemaphore.signal()
                return -1
            }
        }
        return -1
    }

    func removeEntryFromSearchIndex(user userID: String, message messageID: String) -> Int? {
        if userCachedStatus.isEncryptedSearchOn == false ||
            EncryptedSearchService.shared.getESState(userID: userID) == .disabled {
            return -1
        }

        let filter = self.searchableMessages.filter(self.databaseSchema.messageID == messageID)
        var rowID: Int? = -1
        do {
            self.searchIndexSemaphore.wait()
            var connection = self.connectToSearchIndex(userID: userID)
            rowID = try connection?.run(filter.delete())
            connection = nil
            self.searchIndexSemaphore.signal()
        } catch {
            self.searchIndexSemaphore.signal()
            print("Error: deleting messages from search index failed: \(error)")
        }
        return rowID
    }

    func updateEntryInSearchIndex(userID: String,
                                  messageID: MessageID,
                                  encryptedContent: String,
                                  encryptionIV: String,
                                  encryptedContentSize: Int) {
        let messageToUpdate = self.searchableMessages.filter(self.databaseSchema.messageID == messageID.rawValue)

        do {
            let query = messageToUpdate.update(self.databaseSchema.encryptedContent <- encryptedContent,
                                               self.databaseSchema.encryptionIV <- encryptionIV,
                                               self.databaseSchema.encryptedContentSize <- encryptedContentSize)
            self.searchIndexSemaphore.wait()
            var connection = self.connectToSearchIndex(userID: userID)
            let updatedRows: Int? = try connection?.run(query)
            connection = nil
            if let updatedRows = updatedRows {
                if updatedRows <= 0 {
                    print("Error: Message not found in search index - less than 0 results found")
                }
            } else {
                print("Error: Message not found in search index - updated row nil")
            }
            self.searchIndexSemaphore.signal()
        } catch {
            self.searchIndexSemaphore.signal()
            print("Error: updating message in search index failed: \(error)")
        }
    }

    func getDBParams(_ userID: String) -> EncryptedsearchDBParams? {
        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)

        return EncryptedsearchNewDBParams(pathToDB,
                                          DatabaseConstants.TableSearchableMessages,
                                          DatabaseConstants.ColumnSearchableMessageId,
                                          DatabaseConstants.ColumnSearchableMessageTime,
                                          DatabaseConstants.ColumnSearchableMessageOrder,
                                          DatabaseConstants.ColumnSearchableMessageLabels,
                                          DatabaseConstants.ColumnSearchableMessageEncryptionIV,
                                          DatabaseConstants.ColumnSearchableMessageEncryptedContent,
                                          DatabaseConstants.ColumnSearchableMessageEncryptedContentFile)
    }

    func getSearchIndexName(_ userID: String) -> String {
        let dbName: String = "encryptedSearchIndex"
        let fileExtension: String = "sqlite3"
        return dbName + "_" + userID + "." + fileExtension
    }

    func getSearchIndexPathToDB(_ dbName: String) -> String {
        let documentsDirectoryURL = try? FileManager.default.url(for: .documentDirectory,
                                                                 in: .userDomainMask,
                                                                 appropriateFor: nil,
                                                                 create: false)
        let urlToSearchIndex = documentsDirectoryURL?.appendingPathComponent(dbName)
        return urlToSearchIndex?.relativePath ?? ""
    }

    func checkIfSearchIndexExists(for userID: String) -> Bool {
        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)

        if FileManager.default.fileExists(atPath: pathToDB) {
            return true
        }

        return false
    }

    func getNumberOfEntriesInSearchIndex(for userID: String) -> Int {
        // If there is no search index for an user, then the number of entries is zero
        if self.checkIfSearchIndexExists(for: userID) == false {
            return -2
        }

        // If indexing is disabled then do nothing
        if userCachedStatus.isEncryptedSearchOn == false ||
            EncryptedSearchService.shared.getESState(userID: userID) == .disabled {
            return -1
        }

        var numberOfEntries: Int = -1
        do {
            self.searchIndexSemaphore.wait()
            var connection = self.connectToSearchIndex(userID: userID)
            numberOfEntries = try connection?.scalar(self.searchableMessages.count) ?? 0
            connection = nil
            self.searchIndexSemaphore.signal()
        } catch {
            self.searchIndexSemaphore.signal()
            print("Error when getting the number of entries in the search index: \(error)")
        }

        return numberOfEntries
    }

    func deleteSearchIndex(for userID: String) -> Bool {
        // Force close database connection
        self.forceCloseDatabaseConnection(userID: userID)

        // Delete database on file
        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)

        if FileManager.default.fileExists(atPath: pathToDB) {
            do {
                try FileManager.default.removeItem(atPath: pathToDB)
            } catch {
                print("Error when deleting the search index: \(error)")
            }
        } else {
            print("Error: cannot find search index at path: \(pathToDB)")
            return false
        }

        return true
    }

    func shrinkSearchIndex(userID: String, expectedSize: Int64) -> Bool {
        if userCachedStatus.isEncryptedSearchOn == false ||
            EncryptedSearchService.shared.getESState(userID: userID) == .disabled {
            return false
        }
        print("ES-RALPH: shrink search index!")

        let sizeOfSearchIndex = self.getSizeOfSearchIndex(for: userID).asInt64!
        print("size of search index: \(sizeOfSearchIndex)")

        var sizeOfDeletedMessages: Int64 = 0
        // in a loop delete messages until it fits the expected size
        var stopResizing: Bool = false
        while true {
            // Get the size of the encrypted content for the oldest message
            let messageSize: Int = self.estimateSizeOfRowToDelete(userID: userID)
            print("message size: \(messageSize)")
            sizeOfDeletedMessages += Int64(messageSize)

            if sizeOfSearchIndex - sizeOfDeletedMessages < expectedSize {
                stopResizing = true
            }

            // remove last message in the search index
            let deletedRow: Int = self.removeLastEntryInSearchIndex(userID: userID)
            print("successfully deleted row: \(deletedRow), size of index: \(self.getSizeOfSearchIndex(for: userID).asInt64!)")
            if deletedRow == -1 || stopResizing {
                break
            }
        }
        return true
    }

    private func removeLastEntryInSearchIndex(userID: String) -> Int {
        var rowID: Int? = -1
        do {
            // Check if there are still entries in the db
            var connection = self.connectToSearchIndex(userID: userID)
            let numberOfEntries: Int? = try connection?.scalar(self.searchableMessages.count)
            connection = nil
            if numberOfEntries == 0 {
                return -1
            }

            let time: Expression<CLong> = self.databaseSchema.time
            let query = self.searchableMessages.select(time).order(time.asc).limit(1)
            // SELECT "time" FROM "SearchableMessages" ORDER BY "time" ASC LIMIT 1
            self.searchIndexSemaphore.wait()
            connection = self.connectToSearchIndex(userID: userID)
            rowID = try connection?.run(query.delete())

            try connection?.vacuum()
            // Flush the db cache to make the size measure more precise
            // Blocks all write statements until delete is done
            // Details here: https://sqlite.org/pragma.html#pragma_wal_checkpoint
            try connection?.run("pragma wal_checkpoint(full)")
            connection = nil
            self.searchIndexSemaphore.signal()
        } catch {
            self.searchIndexSemaphore.signal()
            print("deleting the oldest message from search index failed: \(error)")
        }
        return rowID!
    }

    private func estimateSizeOfRowToDelete(userID: String) -> Int {
        var sizeOfRow: Int = -1
        do {
            let time: Expression<CLong> = self.databaseSchema.time
            let size: Expression<Int> = self.databaseSchema.encryptedContentSize
            let query = self.searchableMessages.select(size).order(time.asc).limit(1)
            // SELECT "Size" FROM "SearchableMessages" ORDER BY "Time" ASC LIMIT 1
            self.searchIndexSemaphore.wait()
            if let connection = self.connectToSearchIndex(userID: userID) {
                for result in try connection.prepare(query) {
                    sizeOfRow = result[size]
                }
            }
            self.searchIndexSemaphore.signal()
        } catch {
            self.searchIndexSemaphore.signal()
            print("deleting the oldest message from search index failed: \(error)")
        }
        return sizeOfRow
    }

    func getSizeOfSearchIndex(for userID: String) -> (asInt64: Int64?, asString: String) {
        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)

        var size: String = ""
        var sizeOfIndex: Int64? = 0
        if FileManager.default.fileExists(atPath: pathToDB) {
            // Check size of file
            sizeOfIndex = FileManager.default.sizeOfFile(atPath: pathToDB)
            size = (self.fileByteCountFormatter?.string(fromByteCount: sizeOfIndex!))!
        } else {
            print("Error: cannot find search index at path: \(pathToDB)")
        }

        return (sizeOfIndex, size)
    }

    func getOldestMessageInSearchIndex(for userID: String) -> (asInt: Int, asString: String) {
        // If indexing is disabled then do nothing
        if userCachedStatus.isEncryptedSearchOn == false ||
            EncryptedSearchService.shared.getESState(userID: userID) == .disabled {
            return (0, "")
        }

        let time: Expression<CLong> = self.databaseSchema.time
        let query = self.searchableMessages.select(time).order(time.asc).limit(1)
        // SELECT "time" FROM "SearchableMessages" ORDER BY "time" ASC LIMIT 1
        var oldestMessage: Int = 0
        do {
            self.searchIndexSemaphore.wait()
            if let connection = self.connectToSearchIndex(userID: userID) {
                for result in try connection.prepare(query) {
                    oldestMessage = result[time]
                }
            }
            self.searchIndexSemaphore.signal()
        } catch {
            self.searchIndexSemaphore.signal()
            print("Error when querying oldest message in search index: \(error)")
        }
        return (oldestMessage, self.timeToDateString(time: oldestMessage))
    }

    func getListOfMessagesInSearchIndex(userID: String, endDate: Date) -> [ESMessage] {
        var allMessages: [ESMessage] = []

        let endDateAsUnixTimeStamp: Int = Int(endDate.timeIntervalSince1970)
        let query = self.searchableMessages.select(self.databaseSchema.messageID,
                                                   self.databaseSchema.time,
                                                   self.databaseSchema.order,
                                                   self.databaseSchema.labelIDs,
                                                   self.databaseSchema.encryptionIV,
                                                   self.databaseSchema.encryptedContent,
                                                   self.databaseSchema.encryptedContentSize).order(
                                                    self.databaseSchema.time.desc).where(
                                                        self.databaseSchema.time >= endDateAsUnixTimeStamp)
        // SELECT "id, time, order, lableIDs, iv, content" FROM
        // "SearchableMessages" WHERE "time >= endTime" ORDER BY "time" DESC

        do {
            self.searchIndexSemaphore.wait()
            if let connection = self.connectToSearchIndex(userID: userID) {
                for result in try connection.prepare(query) {
                    let esMessage: ESMessage? =
                    EncryptedSearchService.shared.createESMessageFromSearchIndexEntry(userID: userID,
                                                                                      messageID: result[self.databaseSchema.messageID],
                                                                                      time: result[self.databaseSchema.time],
                                                                                      order: result[self.databaseSchema.order],
                                                                                      lableIDs: result[self.databaseSchema.labelIDs],
                                                                                      encryptionIV: result[self.databaseSchema.encryptionIV] ?? "",
                                                                                      encryptedContent: result[self.databaseSchema.encryptedContent] ?? "",
                                                                                      encryptedContentSize: result[self.databaseSchema.encryptedContentSize])
                    if let esMessage = esMessage {
                        allMessages.append(esMessage)
                    } else {
                        print("Error when constructing ES message object.")
                    }
                }
            }
            self.searchIndexSemaphore.signal()
        } catch {
            self.searchIndexSemaphore.signal()
            print("Error when querying list of message ids in search index: \(error)")
        }

        return allMessages
    }

    func getMessageIDOfOldestMessageInSearchIndex(for userID: String) -> String? {
        // If indexing is disabled then do nothing
        if userCachedStatus.isEncryptedSearchOn == false ||
            EncryptedSearchService.shared.getESState(userID: userID) == .disabled {
            return nil
        }

        let time: Expression<CLong> = self.databaseSchema.time
        let id: Expression<String> = self.databaseSchema.messageID
        let query = self.searchableMessages.select(id).order(time.asc).limit(1)
        // SELECT "id" FROM "SearchableMessages" ORDER BY "time" ASC LIMIT 1
        var idOfOldestMessage: String?
        do {
            self.searchIndexSemaphore.wait()
            if let connection = self.connectToSearchIndex(userID: userID) {
                for result in try connection.prepare(query) {
                    idOfOldestMessage = result[id]
                }
            }
            self.searchIndexSemaphore.signal()
        } catch {
            self.searchIndexSemaphore.signal()
            print("Error when querying oldest message in search index: \(error)")
        }
        return idOfOldestMessage
    }

    private func timeToDateString(time: CLong) -> String {
        let date: Date = Date(timeIntervalSince1970: TimeInterval(time))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter.string(from: date)
    }
}

extension FileManager {
    func sizeOfFile(atPath path: String) -> Int64? {
        guard let attrs = try? attributesOfItem(atPath: path) else {
            return nil
        }
        return attrs[.size] as? Int64
    }
}
