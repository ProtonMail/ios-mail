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
import Reachability

public class EncryptedSearchIndexService {
    // instance of Singleton
    static let shared = EncryptedSearchIndexService()

    // set initializer to private - Singleton
    private init() {
        databaseSchema = DatabaseEntries()
        searchableMessages = Table(DatabaseConstants.Table_Searchable_Messages)
        fileByteCountFormatter = ByteCountFormatter()
        fileByteCountFormatter?.allowedUnits = .useAll//[.useMB]
        fileByteCountFormatter?.countStyle = .file
        fileByteCountFormatter?.includesUnit = true
        fileByteCountFormatter?.isAdaptive = true

        // Create initial connection if not existing
        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        let userID: String? = usersManager.firstUser?.userInfo.userId
        if let uid = userID {
            let handleToSQliteDB: Connection? = self.connectToSearchIndex(for: uid)
            self.createSearchIndexTable(using: handleToSQliteDB!) // Create Table
        }
    }

    internal var databaseConnections = [String:Connection?]()
    internal var databaseSchema: DatabaseEntries
    internal var searchableMessages: Table

    private var fileByteCountFormatter: ByteCountFormatter? = nil
}

extension EncryptedSearchIndexService {
    func connectToSearchIndex(for userID: String) -> Connection? {
        if self.checkIfSearchIndexExists(for: userID) {
            if let connection = self.databaseConnections[userID] {
                return connection
            }
        }

        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)
        do {
            let handleToSQliteDB = try Connection(pathToDB)
            self.databaseConnections[userID] = handleToSQliteDB
            print("path to database: ", pathToDB)
        } catch {
            print("Create database connection. Unexpected error: \(error).")
        }

        return self.databaseConnections[userID]!
    }

    enum DatabaseConstants {
        static let Table_Searchable_Messages = "SearchableMessage"
        static let Column_Searchable_Message_Id = "ID"
        static let Column_Searchable_Message_Time = "Time"
        static let Column_Searchable_Message_Labels = "LabelIDs"
        static let Column_Searchable_Message_Has_Body = "HasBody"
        static let Column_Searchable_Message_Is_Starred = "IsStarred"
        static let Column_Searchable_Message_Unread = "Unread"
        static let Column_Searchable_Message_Location = "Location"
        static let Column_Searchable_Message_Order = "MessageOrder"
        static let Column_Searchable_Message_Decryption_Failed = "DecryptionFailed"

        static let Column_Searchable_Message_Encrypted_Content = "EncryptedContent"
        static let Column_Searchable_Message_Encrypted_Content_File = "EncryptedContentFile"
        static let Column_Searchable_Message_Encryption_IV = "EncryptionIV"
        static let Column_Searchable_Message_Encrypted_Content_Size = "Size"
    }

    struct DatabaseEntries {
        var messageID:Expression<String> = Expression(value: "")
        var time:Expression<CLong> = Expression(value: 0)
        var labelIDs:Expression<String> = Expression(value: "")
        var isStarred:Expression<Bool?> = Expression(value: nil)
        var unread:Expression<Bool> = Expression(value: false)
        var location:Expression<Int> = Expression(value: -1)
        var order:Expression<CLong?> = Expression(value: nil)
        var hasBody:Expression<Bool> = Expression(value: false)
        var decryptionFailed:Expression<Bool> = Expression(value: false)
        var encryptionIV: Expression<Data?> = Expression(value: nil)
        var encryptedContent:Expression<Data?> = Expression(value: nil)
        var encryptedContentFile: Expression<String?> = Expression(value: nil)
        var encryptedContentSize: Expression<Int> = Expression(value: 0)
    }

    func createSearchIndexTable(using handleToSQliteDB: Connection) -> Void {
        self.databaseSchema = DatabaseEntries(messageID: Expression<String>(DatabaseConstants.Column_Searchable_Message_Id), time: Expression<CLong>(DatabaseConstants.Column_Searchable_Message_Time), labelIDs: Expression<String>(DatabaseConstants.Column_Searchable_Message_Labels), isStarred: Expression<Bool?>(DatabaseConstants.Column_Searchable_Message_Is_Starred), unread: Expression<Bool>(DatabaseConstants.Column_Searchable_Message_Unread), location: Expression<Int>(DatabaseConstants.Column_Searchable_Message_Location), order: Expression<CLong?>(DatabaseConstants.Column_Searchable_Message_Order), hasBody: Expression<Bool>(DatabaseConstants.Column_Searchable_Message_Has_Body), decryptionFailed: Expression<Bool>(DatabaseConstants.Column_Searchable_Message_Decryption_Failed), encryptionIV: Expression<Data?>(DatabaseConstants.Column_Searchable_Message_Encryption_IV), encryptedContent: Expression<Data?>(DatabaseConstants.Column_Searchable_Message_Encrypted_Content), encryptedContentFile: Expression<String?>(DatabaseConstants.Column_Searchable_Message_Encrypted_Content_File), encryptedContentSize: Expression<Int>(DatabaseConstants.Column_Searchable_Message_Encrypted_Content_Size))

        do {
            try handleToSQliteDB.run(self.searchableMessages.create(ifNotExists: true) {
                t in
                t.column(self.databaseSchema.messageID, primaryKey: true)  //TODO set default value
                t.column(self.databaseSchema.time, defaultValue: 0)
                t.column(self.databaseSchema.labelIDs)    //TODO set default value
                t.column(self.databaseSchema.isStarred, defaultValue: nil)
                t.column(self.databaseSchema.unread, defaultValue: false)
                t.column(self.databaseSchema.location, defaultValue: -1)
                t.column(self.databaseSchema.order, defaultValue: nil)
                t.column(self.databaseSchema.hasBody, defaultValue: false)
                t.column(self.databaseSchema.decryptionFailed, defaultValue: false)
                t.column(self.databaseSchema.encryptionIV, defaultValue: nil)
                t.column(self.databaseSchema.encryptedContent, defaultValue: nil)
                t.column(self.databaseSchema.encryptedContentFile, defaultValue: nil)
                t.column(self.databaseSchema.encryptedContentSize, defaultValue: -1)
            })
        } catch {
            print("Create Table. Unexpected error: \(error).")
        }
    }

    func addNewEntryToSearchIndex(for userID: String, messageID:String, time: Int, labelIDs: Set<String>, isStarred:Bool, unread:Bool, location:Int, order:Int, hasBody:Bool, decryptionFailed:Bool, encryptionIV:Data, encryptedContent:Data, encryptedContentFile:String, encryptedContentSize:Int) -> Int64? {
        var rowID:Int64? = -1
        let allLabels:String = labelIDs.joined(separator: ";")

        do {
            let insert: Insert? = self.searchableMessages.insert(self.databaseSchema.messageID <- messageID, self.databaseSchema.time <- time, self.databaseSchema.labelIDs <- allLabels, self.databaseSchema.isStarred <- isStarred, self.databaseSchema.unread <- unread, self.databaseSchema.location <- location, self.databaseSchema.order <- order, self.databaseSchema.hasBody <- hasBody, self.databaseSchema.decryptionFailed <- decryptionFailed, self.databaseSchema.encryptionIV <- encryptionIV, self.databaseSchema.encryptedContent <- encryptedContent, self.databaseSchema.encryptedContentFile <- encryptedContentFile, self.databaseSchema.encryptedContentSize <- encryptedContentSize)
            let handleToSQliteDB: Connection? = self.connectToSearchIndex(for: userID)
            rowID = try handleToSQliteDB?.run(insert!)
        } catch {
            print("Insert in Table. Unexpected error: \(error).")
        }
        return rowID
    }

    func removeEntryFromSearchIndex(user userID: String, message messageID: String) -> Int? {
        let filter = self.searchableMessages.filter(self.databaseSchema.messageID == messageID)
        var rowID:Int? = -1
        do {
            let handleToSQLiteDB: Connection? = self.connectToSearchIndex(for: userID)
            rowID = try handleToSQLiteDB?.run(filter.delete())
        } catch {
            print("deleting messages from search index failed: \(error)")
        }
        return rowID
    }

    func getDBParams(_ userID: String) -> EncryptedsearchDBParams {
        var dbParams: EncryptedsearchDBParams? = nil
        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)

        dbParams = EncryptedsearchDBParams(pathToDB, table: DatabaseConstants.Table_Searchable_Messages, id_: DatabaseConstants.Column_Searchable_Message_Id, time: DatabaseConstants.Column_Searchable_Message_Time, location: DatabaseConstants.Column_Searchable_Message_Location, read: DatabaseConstants.Column_Searchable_Message_Unread, starred: DatabaseConstants.Column_Searchable_Message_Is_Starred, labels: DatabaseConstants.Column_Searchable_Message_Labels, initVector: DatabaseConstants.Column_Searchable_Message_Encryption_IV, content: DatabaseConstants.Column_Searchable_Message_Encrypted_Content, contentFile: DatabaseConstants.Column_Searchable_Message_Encrypted_Content_File)

        return dbParams!
    }

    func getSearchIndexName(_ userID: String) -> String {
        let dbName: String = "encryptedSearchIndex"
        let fileExtension: String = "sqlite3"
        return dbName + "_" + userID + "." + fileExtension
    }

    func getSearchIndexPathToDB(_ dbName: String) -> String {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let path: URL = urls[0]

        let pathToDB: String = path.absoluteString + dbName
        return pathToDB
    }

    func checkIfSearchIndexExists(for userID: String) -> Bool {
        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)
        let urlToDB: URL? = URL(string: pathToDB)

        if FileManager.default.fileExists(atPath: urlToDB!.path) {
            return true
        }

        return false
    }

    func getNumberOfEntriesInSearchIndex(for userID: String) -> Int {
        var numberOfEntries: Int? = 0

        // If there is no search index for an user, then the number of entries is zero
        if self.checkIfSearchIndexExists(for: userID) == false {
            return numberOfEntries!
        }

        let handleToDB: Connection? = self.connectToSearchIndex(for: userID)
        do {
            numberOfEntries = try handleToDB?.scalar(self.searchableMessages.count)
        } catch {
            print("Error when getting the number of entries in the search index: \(error)")
        }

        return numberOfEntries!
    }

    func deleteSearchIndex(for userID: String) -> Bool {
        // Explicitly close connection to DB and then set handle to nil
        var connection: Connection? = self.connectToSearchIndex(for: userID)
        sqlite3_close(connection?.handle)
        self.databaseConnections.removeValue(forKey: userID)
        connection = nil

        // Delete database on file
        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)
        let urlToDB: URL? = URL(string: pathToDB)

        if FileManager.default.fileExists(atPath: urlToDB!.path) {
            do {
                try FileManager.default.removeItem(atPath: urlToDB!.path)
            } catch {
                print("Error when deleting the search index: \(error)")
            }
        } else {
            print("Error: cannot find search index at path: \(urlToDB!.path)")
            return false
        }

        return true
    }

    func resizeSearchIndex(userID: String, expectedSize: Int64) -> Bool {
        // check if search index exists for user
        if self.checkIfSearchIndexExists(for: userID) == false {
            return false
        }

        // check if size is already smaller
        let sizeOfSearchIndex = self.getSizeOfSearchIndex(for: userID).asInt64!
        if sizeOfSearchIndex < expectedSize {
            return false
        }
        print("size of search index: \(sizeOfSearchIndex)")

        let handleToDB: Connection? = self.connectToSearchIndex(for: userID)
        var sizeOfDeletedMessages: Int64 = 0
        // in a loop delete messages until it fits the expected size
        var stopResizing: Bool = false
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
                break
            }
        }
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
            rowID = try handleToDB?.run(query.delete())

            try handleToDB?.run("VACUUM")
            // Flush the db cache to make the size measure more precise
            // Blocks all write statements until delete is done
            // Details here: https://sqlite.org/pragma.html#pragma_wal_checkpoint
            try handleToDB?.run("pragma wal_checkpoint(full)")
        } catch {
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
            for result in try handleToDB!.prepare(query) {
                sizeOfRow = result[size]
            }
        } catch {
            print("deleting the oldest message from search index failed: \(error)")
        }
        return sizeOfRow
    }

    func getSizeOfSearchIndex(for userID: String) -> (asInt64: Int64?, asString: String) {
        let dbName: String = self.getSearchIndexName(userID)
        let pathToDB: String = self.getSearchIndexPathToDB(dbName)
        let urlToDB: URL? = URL(string: pathToDB)

        var size: String = ""
        var sizeOfIndex: Int64? = nil
        if FileManager.default.fileExists(atPath: urlToDB!.path) {
            // Check size of file
            sizeOfIndex = FileManager.default.sizeOfFile(atPath: urlToDB!.path)
            size = (self.fileByteCountFormatter?.string(fromByteCount: sizeOfIndex!))!
        } else {
            print("Error: cannot find search index at path: \(urlToDB!.path)")
        }

        return (sizeOfIndex, size)
    }

    /*func getFreeDiskSpace() -> (asInt64: Int64?, asString: String) {
        var size: String = ""
        var freeSpace: Int64? = nil
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
            freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value
            size = (self.fileByteCountFormatter?.string(fromByteCount: freeSpace!))!
        } catch {
            print("error \(error)")
        }

        return (freeSpace, size)
    }*/

    func getOldestMessageInSearchIndex(for userID: String) -> String {
        let time: Expression<CLong> = self.databaseSchema.time
        let query = self.searchableMessages.select(time).order(time.asc).limit(1)
        // SELECT "time" FROM "SearchableMessages" ORDER BY "time" ASC LIMIT 1

        let handleToSQLiteDB: Connection? = self.connectToSearchIndex(for: userID)
        var oldestMessage: CLong = 0
        do {
            for result in try handleToSQLiteDB!.prepare(query) {
                oldestMessage = result[time]
            }
        } catch {
            print("Error when querying oldest message in search index: \(error)")
        }
        return self.timeToDateString(time: oldestMessage)
    }

    func getNewestMessageInSearchIndex(for userID: String) -> Int {
        let time: Expression<CLong> = self.databaseSchema.time
        let query = self.searchableMessages.select(time).order(time.desc).limit(1)
        // SELECT "time" FROM "SearchableMessages" ORDER BY "time" DESC LIMIT 1

        let handleToSQLiteDB: Connection? = self.connectToSearchIndex(for: userID)
        var newestMessage: CLong = 0
        do {
            for result in try handleToSQLiteDB!.prepare(query) {
                newestMessage = result[time]
            }
        } catch {
            print("Error when querying newest message in search index: \(error)")
        }
        return Int(newestMessage)
    }

    private func timeToDateString(time: CLong) -> String {
        let date: Date = Date(timeIntervalSince1970: TimeInterval(time))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter.string(from: date)
    }

    func createSearchIndexDBIfNotExisting(for userID: String){
        // Check if db handle exists
        let handle: Connection? = self.connectToSearchIndex(for: userID)
        
        // Check if db table exists
        let table = Table(DatabaseConstants.Table_Searchable_Messages)
        do {
            let _ = try handle?.scalar(table.exists)
        } catch {
            self.createSearchIndexTable(using: handle!)
        }
    }

    func compressSearchIndex(for userID: String) {
        // If there is no search index for an user, then do nothing
        if self.checkIfSearchIndexExists(for: userID) == false {
            return
        }

        let handle: Connection? = self.connectToSearchIndex(for: userID)
        do {
            try handle?.run("VACUUM")
        } catch {
            print("Error when compressing the search index db: \(error)")
        }
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
