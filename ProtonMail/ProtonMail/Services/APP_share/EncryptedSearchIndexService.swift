//
//  EncryptedSearchIndexService.swift
//  ProtonMail
//
//  Created by Ralph Ankele on 19.07.21.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import Foundation
import SQLite
import Crypto

public class EncryptedSearchIndexService {
    // instance of Singleton
    static let shared = EncryptedSearchIndexService()

    // set initializer to private - Singleton
    private init() {
        searchIndexSemaphore = DispatchSemaphore(value: 1)  // Semaphore to lock access to database
        databaseSchema = DatabaseEntries()
        searchableMessages = Table(DatabaseConstants.Table_Searchable_Messages)
        fileByteCountFormatter = ByteCountFormatter()
        fileByteCountFormatter?.allowedUnits = .useAll
        fileByteCountFormatter?.countStyle = .file
        fileByteCountFormatter?.includesUnit = true
        fileByteCountFormatter?.isAdaptive = true

        // Create initial connection if not existing
        /*let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        if let userID = usersManager.firstUser?.userInfo.userId {
            let handleToSQliteDB: Connection? = self.connectToSearchIndex(for: userID)
            self.createSearchIndexTable(using: handleToSQliteDB!) // Create Table
        }*/
    }

    //internal var databaseConnections = [String:Connection?]()
    internal var databaseSchema: DatabaseEntries
    internal var searchableMessages: Table

    private var fileByteCountFormatter: ByteCountFormatter? = nil
    internal let searchIndexSemaphore: DispatchSemaphore
}

extension EncryptedSearchIndexService {
    func connectToSearchIndex(for userID: String) -> Connection? {
        /*if self.checkIfSearchIndexExists(for: userID) {
            if let connection = self.databaseConnections[userID] {
                return connection
            }
        }*/

        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)
        //let urlToDB: URL? = URL(string: pathToDB)
        do {
            let handleToSQliteDB = try Connection(pathToDB)
            //let handleToSQliteDB = try Connection(pathToDB)
            //handleToSQliteDB.busyTimeout = 5 // Retry multiple times - database is locked error after 5 seconds
            //self.databaseConnections[userID] = handleToSQliteDB
            //print("path to database: ", pathToDB)
            return handleToSQliteDB
        } catch {
            print("Create database connection. Unexpected error: \(error).")
        }

        return nil
        //return self.databaseConnections[userID]!
    }

    /*func forceReconnectToDatabase(userID: String) -> Connection? {
        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)
        do {
            let handleToSQliteDB = try Connection(pathToDB)
            handleToSQliteDB.busyTimeout = 5 // Retry multiple times - database is locked error after 5 seconds
            self.databaseConnections[userID] = handleToSQliteDB
            print("path to database: ", pathToDB)
            return handleToSQliteDB
        } catch {
            print("Create database connection. Unexpected error: \(error).")
        }
        return nil
    }*/

    //func forceCloseDatabaseConnection(connection: Connection?) {
        /*guard let connection = connection else {
            print("Error when closing db connection. Handle is nil!")
            return
        }*/

        // Explicitly close connection to DB and then set handle to nil
        //sqlite3_close(connection?.handle)
    //}

    enum DatabaseConstants {
        static let Table_Searchable_Messages = "SearchableMessage"
        static let Column_Searchable_Message_Id = "ID"
        static let Column_Searchable_Message_Time = "Time"
        static let Column_Searchable_Message_Order = "MessageOrder"
        static let Column_Searchable_Message_Labels = "LabelIDs"
        static let Column_Searchable_Message_Location = "Location"
        static let Column_Searchable_Message_Decryption_Failed = "DecryptionFailed"

        static let Column_Searchable_Message_Encrypted_Content = "EncryptedContent"
        static let Column_Searchable_Message_Encrypted_Content_File = "EncryptedContentFile"
        static let Column_Searchable_Message_Encryption_IV = "EncryptionIV"
        static let Column_Searchable_Message_Encrypted_Content_Size = "Size"
    }

    struct DatabaseEntries {
        var messageID:Expression<String> = Expression(value: "")
        var time:Expression<CLong> = Expression(value: 0)
        var order:Expression<CLong> = Expression(value: 0)
        var labelIDs:Expression<String> = Expression(value: "")
        var encryptionIV: Expression<String?> = Expression(value: nil)
        var encryptedContent:Expression<String?> = Expression(value: nil)
        var encryptedContentFile: Expression<String?> = Expression(value: nil)
        var encryptedContentSize: Expression<Int> = Expression(value: 0)
    }

    func createSearchIndexTable(userID: String) -> Void {
        self.databaseSchema = DatabaseEntries(messageID: Expression<String>(DatabaseConstants.Column_Searchable_Message_Id),
                                              time: Expression<CLong>(DatabaseConstants.Column_Searchable_Message_Time),
                                              order: Expression<CLong>(DatabaseConstants.Column_Searchable_Message_Order),
                                              labelIDs: Expression<String>(DatabaseConstants.Column_Searchable_Message_Labels),
                                              encryptionIV: Expression<String?>(DatabaseConstants.Column_Searchable_Message_Encryption_IV),
                                              encryptedContent: Expression<String?>(DatabaseConstants.Column_Searchable_Message_Encrypted_Content),
                                              encryptedContentFile: Expression<String?>(DatabaseConstants.Column_Searchable_Message_Encrypted_Content_File),
                                              encryptedContentSize: Expression<Int>(DatabaseConstants.Column_Searchable_Message_Encrypted_Content_Size))

        var handleToSQliteDB: Connection? = nil
        do {
            self.searchIndexSemaphore.wait()
            handleToSQliteDB = self.connectToSearchIndex(for: userID)
            try handleToSQliteDB?.run(self.searchableMessages.create(ifNotExists: true) {
                t in
                t.column(self.databaseSchema.messageID, primaryKey: true)
                t.column(self.databaseSchema.time, defaultValue: 0)
                t.column(self.databaseSchema.order, defaultValue: 0)
                t.column(self.databaseSchema.labelIDs)
                t.column(self.databaseSchema.encryptionIV, defaultValue: nil)
                t.column(self.databaseSchema.encryptedContent, defaultValue: nil)
                t.column(self.databaseSchema.encryptedContentFile, defaultValue: nil)
                t.column(self.databaseSchema.encryptedContentSize, defaultValue: -1)
            })
            handleToSQliteDB = nil
            self.searchIndexSemaphore.signal()
        } catch {
            handleToSQliteDB = nil
            self.searchIndexSemaphore.signal()
            print("Create Table. Unexpected error: \(error).")
        }
    }

    func addNewEntryToSearchIndex(userID: String,
                                  messageID: MessageID,
                                  time: Int,
                                  order:Int,
                                  labelIDs: [LabelEntity],
                                  encryptionIV:String?,
                                  encryptedContent:String?,
                                  encryptedContentFile:String,
                                  encryptedContentSize:Int) -> Int64? {
        var rowID:Int64? = -1

        let expectedESStates: [EncryptedSearchService.EncryptedSearchIndexState] = [.downloading, .refresh, .background, .complete, .partial, .paused, .lowstorage, .metadataIndexing]
        if expectedESStates.contains(EncryptedSearchService.shared.getESState(userID: userID)) {
            var labels: Set<String> = Set()
            labelIDs.forEach { label in
                labels.insert(label.labelID.rawValue)
            }
            var handleToSQliteDB: Connection? = nil
            do {
                let insert: Insert? = self.searchableMessages.insert(self.databaseSchema.messageID <- messageID.rawValue,
                                                                     self.databaseSchema.time <- time,
                                                                     self.databaseSchema.order <- order,
                                                                     self.databaseSchema.labelIDs <- labels.joined(separator: ";"),
                                                                     self.databaseSchema.encryptionIV <- encryptionIV,
                                                                     self.databaseSchema.encryptedContent <- encryptedContent,
                                                                     self.databaseSchema.encryptedContentFile <- encryptedContentFile,
                                                                     self.databaseSchema.encryptedContentSize <- encryptedContentSize)
                self.searchIndexSemaphore.wait()
                handleToSQliteDB = self.connectToSearchIndex(for: userID)
                rowID = try handleToSQliteDB?.run(insert!)
                handleToSQliteDB = nil
                self.searchIndexSemaphore.signal()
            } catch {
                handleToSQliteDB = nil
                self.searchIndexSemaphore.signal()
                print("Insert in Table. Unexpected error: \(error).")
            }
        }

        return rowID
    }

    func removeEntryFromSearchIndex(user userID: String, message messageID: String) -> Int? {
        if userCachedStatus.isEncryptedSearchOn == false || EncryptedSearchService.shared.getESState(userID: userID) == .disabled {
            return -1
        }

        let filter = self.searchableMessages.filter(self.databaseSchema.messageID == messageID)
        var rowID:Int? = -1
        var handleToSQLiteDB: Connection? = nil
        do {
            self.searchIndexSemaphore.wait()
            handleToSQLiteDB = self.connectToSearchIndex(for: userID)
            rowID = try handleToSQLiteDB?.run(filter.delete())
            handleToSQLiteDB = nil
            self.searchIndexSemaphore.signal()
        } catch {
            handleToSQLiteDB = nil
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

        var handleToSQLiteDB: Connection? = nil
        do {
            let query = messageToUpdate.update(self.databaseSchema.encryptedContent <- encryptedContent,
                                               self.databaseSchema.encryptionIV <- encryptionIV,
                                               self.databaseSchema.encryptedContentSize <- encryptedContentSize)
            self.searchIndexSemaphore.wait()
            handleToSQLiteDB = self.connectToSearchIndex(for: userID)
            let updatedRows: Int? = try handleToSQLiteDB?.run(query)
            if let updatedRows = updatedRows {
                if updatedRows <= 0 {
                    print("Error: Message not found in search index - less than 0 results found")
                }
            } else {
                print("Error: Message not found in search index - updated row nil")
            }
            handleToSQLiteDB = nil
            self.searchIndexSemaphore.signal()
        } catch {
            handleToSQLiteDB = nil
            self.searchIndexSemaphore.signal()
            print("Error: updating message in search index failed: \(error)")
        }
    }

    func getDBParams(_ userID: String) -> EncryptedsearchDBParams {
        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)

        return EncryptedsearchNewDBParams(pathToDB,
                                          DatabaseConstants.Table_Searchable_Messages,
                                          DatabaseConstants.Column_Searchable_Message_Id,
                                          DatabaseConstants.Column_Searchable_Message_Time,
                                          DatabaseConstants.Column_Searchable_Message_Order,
                                          DatabaseConstants.Column_Searchable_Message_Labels,
                                          DatabaseConstants.Column_Searchable_Message_Encryption_IV,
                                          DatabaseConstants.Column_Searchable_Message_Encrypted_Content,
                                          DatabaseConstants.Column_Searchable_Message_Encrypted_Content_File)!
    }

    func getSearchIndexName(_ userID: String) -> String {
        let dbName: String = "encryptedSearchIndex"
        let fileExtension: String = "sqlite3"
        return dbName + "_" + userID + "." + fileExtension
    }

    func getSearchIndexPathToDB(_ dbName: String) -> String {
        /*let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let path: URL = urls[0]

        let pathToDB: String = path.absoluteString + dbName
        return pathToDB*/
        
        //Documents directory
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        // Library directory
        //let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .allDomainsMask, true).first!
        return path + "/" + dbName
    }

    func checkIfSearchIndexExists(for userID: String) -> Bool {
        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)
        //let urlToDB: URL? = URL(string: pathToDB)

        //if FileManager.default.fileExists(atPath: urlToDB!.path) {
        if FileManager.default.fileExists(atPath: pathToDB) {
            print("ES-INDEX: file exists: path -> \(pathToDB)")
            return true
        }

        return false
    }

    func getNumberOfEntriesInSearchIndex(for userID: String) -> Int {
        var numberOfEntries: Int? = -1
        // If indexing is disabled then do nothing
        if userCachedStatus.isEncryptedSearchOn == false ||
            EncryptedSearchService.shared.getESState(userID: userID) == .disabled {
            return numberOfEntries!
        }

        // If there is no search index for an user, then the number of entries is zero
        if self.checkIfSearchIndexExists(for: userID) == false {
            return numberOfEntries!
        }

        var handleToDB: Connection? = nil
        do {
            self.searchIndexSemaphore.wait()
            handleToDB = self.connectToSearchIndex(for: userID)
            numberOfEntries = try handleToDB?.scalar(self.searchableMessages.count)
            handleToDB = nil
            self.searchIndexSemaphore.signal()
        } catch {
            handleToDB = nil
            self.searchIndexSemaphore.signal()
            print("Error when getting the number of entries in the search index: \(error)")
        }

        return numberOfEntries!
    }

    func deleteSearchIndex(for userID: String) -> Bool {
        // Delete database on file
        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)
        //let urlToDB: URL? = URL(string: pathToDB)

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
        if userCachedStatus.isEncryptedSearchOn == false || EncryptedSearchService.shared.getESState(userID: userID) == .disabled {
            return false
        }
        print("ES-RALPH: shrink search index!")

        let sizeOfSearchIndex = self.getSizeOfSearchIndex(for: userID).asInt64!
        print("size of search index: \(sizeOfSearchIndex)")

        var sizeOfDeletedMessages: Int64 = 0
        // in a loop delete messages until it fits the expected size
        var stopResizing: Bool = false
        var handleToDB: Connection? = self.connectToSearchIndex(for: userID)
        while true {
            // Get the size of the encrypted content for the oldest message
            let messageSize: Int = self.estimateSizeOfRowToDelete(handleToDB: handleToDB)
            print("message size: \(messageSize)")
            sizeOfDeletedMessages += Int64(messageSize)

            if sizeOfSearchIndex - sizeOfDeletedMessages < expectedSize {
                stopResizing = true
            }

            // remove last message in the search index
            let deletedRow: Int = self.removeLastEntryInSearchIndex(handleToDB: handleToDB)
            print("successfully deleted row: \(deletedRow), size of index: \(self.getSizeOfSearchIndex(for: userID).asInt64!)")
            if deletedRow == -1 || stopResizing {
                //sqlite3_close(handleToDB!.handle)
                break
            }
        }
        handleToDB = nil
        return true
    }

    private func removeLastEntryInSearchIndex(handleToDB: Connection?) -> Int {
        var rowID:Int? = -1
        do {
            // Check if there are still entries in the db
            let numberOfEntries: Int? = try handleToDB?.scalar(self.searchableMessages.count)
            if numberOfEntries == 0 {
                return rowID!
            }

            let time: Expression<CLong> = self.databaseSchema.time
            let query = self.searchableMessages.select(time).order(time.asc).limit(1)
            // SELECT "time" FROM "SearchableMessages" ORDER BY "time" ASC LIMIT 1
            self.searchIndexSemaphore.wait()
            rowID = try handleToDB?.run(query.delete())

            try handleToDB?.run("VACUUM")
            // Flush the db cache to make the size measure more precise
            // Blocks all write statements until delete is done
            // Details here: https://sqlite.org/pragma.html#pragma_wal_checkpoint
            print("ES-RALPH: PRAGMA WAL CHECKPOINT")
            try handleToDB?.run("pragma wal_checkpoint(full)")
            self.searchIndexSemaphore.signal()
        } catch {
            self.searchIndexSemaphore.signal()
            print("deleting the oldest message from search index failed: \(error)")
        }
        return rowID!
    }

    private func estimateSizeOfRowToDelete(handleToDB: Connection?) -> Int {
        var sizeOfRow: Int = -1
        do {
            let time: Expression<CLong> = self.databaseSchema.time
            let size: Expression<Int> = self.databaseSchema.encryptedContentSize
            let query = self.searchableMessages.select(size).order(time.asc).limit(1)
            // SELECT "Size" FROM "SearchableMessages" ORDER BY "Time" ASC LIMIT 1
            self.searchIndexSemaphore.wait()
            for result in try handleToDB!.prepare(query) {
                sizeOfRow = result[size]
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
        //let urlToDB: URL? = URL(string: pathToDB)

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

        var oldestMessage: CLong = 0
        var handleToSQLiteDB: Connection? = nil
        do {
            self.searchIndexSemaphore.wait()
            handleToSQLiteDB = self.connectToSearchIndex(for: userID)
            for result in try handleToSQLiteDB!.prepare(query) {
                oldestMessage = result[time]
            }
            handleToSQLiteDB = nil
            self.searchIndexSemaphore.signal()
        } catch {
            handleToSQLiteDB = nil
            self.searchIndexSemaphore.signal()
            print("Error when querying oldest message in search index: \(error)")
        }
        return (Int(oldestMessage), self.timeToDateString(time: oldestMessage))
    }

    func getNewestMessageInSearchIndex(for userID: String) -> Int {
        // If indexing is disabled then do nothing
        if userCachedStatus.isEncryptedSearchOn == false ||
            EncryptedSearchService.shared.getESState(userID: userID) == .disabled {
            return 0
        }

        let time: Expression<CLong> = self.databaseSchema.time
        let query = self.searchableMessages.select(time).order(time.desc).limit(1)
        // SELECT "time" FROM "SearchableMessages" ORDER BY "time" DESC LIMIT 1

        var newestMessage: CLong = 0
        var handleToSQLiteDB: Connection? = nil
        do {
            self.searchIndexSemaphore.wait()
            handleToSQLiteDB = self.connectToSearchIndex(for: userID)
            for result in try handleToSQLiteDB!.prepare(query) {
                newestMessage = result[time]
            }
            handleToSQLiteDB = nil
            self.searchIndexSemaphore.signal()
        } catch {
            handleToSQLiteDB = nil
            self.searchIndexSemaphore.signal()
            print("Error when querying newest message in search index: \(error)")
        }
        return Int(newestMessage)
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
        // SELECT "id, time, order, lableIDs, iv, content" FROM "SearchableMessages" WHERE "time >= endTime" ORDER BY "time" DESC

        var handleToSQLiteDB: Connection? = nil
        do {
            self.searchIndexSemaphore.wait()
            handleToSQLiteDB = self.connectToSearchIndex(for: userID)
            for result in try handleToSQLiteDB!.prepare(query) {
                let esMessage: ESMessage? = EncryptedSearchService.shared.createESMessageFromSearchIndexEntry(userID: userID,
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
            handleToSQLiteDB = nil
            self.searchIndexSemaphore.signal()
        } catch {
            handleToSQLiteDB = nil
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

        var idOfOldestMessage: String? = nil
        var handleToSQLiteDB: Connection? = nil
        do {
            self.searchIndexSemaphore.wait()
            handleToSQLiteDB = self.connectToSearchIndex(for: userID)
            for result in try handleToSQLiteDB!.prepare(query) {
                idOfOldestMessage = result[id]
            }
            handleToSQLiteDB = nil
            self.searchIndexSemaphore.signal()
        } catch {
            handleToSQLiteDB = nil
            self.searchIndexSemaphore.signal()
            print("Error when querying oldest message in search index: \(error)")
        }
        return idOfOldestMessage
    }

    func getMessageIDOfNewestMessageInSearchIndex(for userID: String) -> String? {
        // If indexing is disabled then do nothing
        if userCachedStatus.isEncryptedSearchOn == false ||
            EncryptedSearchService.shared.getESState(userID: userID) == .disabled {
            return nil
        }

        let time: Expression<CLong> = self.databaseSchema.time
        let id: Expression<String> = self.databaseSchema.messageID
        let query = self.searchableMessages.select(id).order(time.desc).limit(1)
        // SELECT "id" FROM "SearchableMessages" ORDER BY "time" DESC LIMIT 1

        var idOfNewestMessage: String? = nil
        var handleToSQLiteDB: Connection? = nil
        do {
            self.searchIndexSemaphore.wait()
            handleToSQLiteDB = self.connectToSearchIndex(for: userID)
            for result in try handleToSQLiteDB!.prepare(query) {
                idOfNewestMessage = result[id]
            }
            handleToSQLiteDB = nil
            self.searchIndexSemaphore.signal()
        } catch {
            handleToSQLiteDB = nil
            self.searchIndexSemaphore.signal()
            print("Error when querying newest message in search index: \(error)")
        }
        return idOfNewestMessage
    }

    private func timeToDateString(time: CLong) -> String {
        let date: Date = Date(timeIntervalSince1970: TimeInterval(time))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter.string(from: date)
    }

    func createSearchIndexDBIfNotExisting(for userID: String) {
        // If indexing is disabled then do nothing
        /*if userCachedStatus.isEncryptedSearchOn == false ||
            EncryptedSearchService.shared.getESState(userID: userID) == .disabled {
            return
        }*/

        // Check if db table exists
        let table = Table(DatabaseConstants.Table_Searchable_Messages)
        var handle: Connection? = nil
        do {
            self.searchIndexSemaphore.wait()
            handle = self.connectToSearchIndex(for: userID)
            let _ = try handle?.scalar(table.exists)
            handle = nil
            self.searchIndexSemaphore.signal()
        } catch {
            print("Error: search index db table does not exist yet, create it now.")
            handle = nil
            self.searchIndexSemaphore.signal()
            self.createSearchIndexTable(userID: userID)
        }
    }

    /*func compressSearchIndex(for userID: String) {
        // If there is no search index for an user, then do nothing
        if self.checkIfSearchIndexExists(for: userID) == false ||
            userCachedStatus.isEncryptedSearchOn == false ||
            EncryptedSearchService.shared.getESState(userID: userID) == .disabled {
            return
        }

        let handle: Connection? = self.connectToSearchIndex(for: userID)
        do {
            self.searchIndexSemaphore.wait()
            try handle?.run("VACUUM")
            self.searchIndexSemaphore.signal()
        } catch {
            print("Error when compressing the search index db: \(error)")
        }
    }*/
}

extension FileManager {
    func sizeOfFile(atPath path: String) -> Int64? {
        guard let attrs = try? attributesOfItem(atPath: path) else {
            return nil
        }
        return attrs[.size] as? Int64
    }
}
