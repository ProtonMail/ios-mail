// Copyright (c) 2022 Proton AG
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
import SQLite3

enum SQLiteError: Error {
    case openDatabase(message: String)
    case prepare(message: String)
    case step(message: String)
    case bind(message: String)
}

class SQLiteDatabase {
    private let dbPointer: OpaquePointer?
    private var dbSemaphore: DispatchSemaphore

    private init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
        self.dbSemaphore = DispatchSemaphore(value: 1)
    }
    deinit {
        sqlite3_close(dbPointer)
    }

    static func open(path: String) throws -> SQLiteDatabase {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        if sqlite3_open_v2(path, &db, flags, nil) == SQLITE_OK {
            return SQLiteDatabase(dbPointer: db)
        } else {
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            if let errorPointer = sqlite3_errmsg(db) {
                let message = String(cString: errorPointer)
                throw SQLiteError.openDatabase(message: message)
            } else {
                throw SQLiteError.openDatabase(message: "No error message provided from sqlite.")
            }
        }
    }

    func close() {
        sqlite3_close(dbPointer)
    }

    fileprivate var errorMessage: String {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            let errorMessage = String(cString: errorPointer)
            return errorMessage
        } else {
            return "No error message provided from sqlite"
        }
    }
}

extension SQLiteDatabase {
    func prepareStatement(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.prepare(message: errorMessage)
        }
        return statement
    }

    func createTable(table: String) throws {
        let createTableStatement = try prepareStatement(sql: table)
        defer {
            sqlite3_finalize(createTableStatement)
        }
        guard sqlite3_step(createTableStatement) == SQLITE_DONE else {
            throw SQLiteError.step(message: errorMessage)
        }
        print("Table sucessfully created.")
    }

    func insertEntryIntoDatabase(sqlQuery: String,
                                 databaseEntry: EncryptedSearchIndexService.DatabaseEntries,
                                 completionHandler: @escaping () -> Void) throws {
        // INSERT INTO SearchableMessage (ID, Time, MessageOrder, LabelIDs, EncryptionIV, EncryptedContent, EncryptedContentFile, Size) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        let insertStatement = try prepareStatement(sql: sqlQuery)
        /*defer {
            sqlite3_finalize(insertStatement)
        }*/
        // Bind values to insert statement
        /*guard sqlite3_bind_text(insertStatement, 1, databaseEntry.messageID, -1, nil) == SQLITE_OK &&
              sqlite3_bind_int64(insertStatement, 2, Int64(databaseEntry.time)) == SQLITE_OK &&
              sqlite3_bind_int64(insertStatement, 3, Int64(databaseEntry.order)) == SQLITE_OK &&
              sqlite3_bind_text(insertStatement, 4, databaseEntry.labelIDs, -1, nil) == SQLITE_OK &&
              sqlite3_bind_text(insertStatement, 5, databaseEntry.encryptionIV, -1, nil) == SQLITE_OK &&
              sqlite3_bind_text(insertStatement, 6, databaseEntry.encryptedContent, -1, nil) == SQLITE_OK &&
              // sqlite3_bind_blob64(insertStatement, 6, databaseEntry.encryptedContent, sqlite3_uint64(databaseEntry.encryptedContentSize), nil) == SQLITE_OK &&
            // sqlite3_bind_text(insertStatement, 6, "hello", -1, nil) == SQLITE_OK &&
              sqlite3_bind_text(insertStatement, 7, databaseEntry.encryptedContentFile, -1, nil) == SQLITE_OK &&
              sqlite3_bind_int(insertStatement, 8, Int32(databaseEntry.encryptedContentSize)) == SQLITE_OK
        else {
            throw SQLiteError.bind(message: errorMessage)
        }*/
        print("Trying to insert message: \(databaseEntry.messageID) at time: \(databaseEntry.time)")
        // Execute insert statement
        self.dbSemaphore.wait()
        guard sqlite3_step(insertStatement) == SQLITE_DONE else {
            self.dbSemaphore.signal()
            throw SQLiteError.step(message: errorMessage)
        }
        self.dbSemaphore.signal()
        sqlite3_finalize(insertStatement)
        // print("Successfully inserted message: \(databaseEntry.messageID)!")
        completionHandler()
    }

    func getTimeOfOldestEntryInDatabase(sqlQuery: String) throws -> Int {
        // SELECT "time" FROM "SearchableMessage" ORDER BY "time" ASC LIMIT 1
        guard let queryStatement = try? prepareStatement(sql: sqlQuery) else {
            return -1
        }
        defer {
            sqlite3_finalize(queryStatement)
        }
        // Execute statement
        guard sqlite3_step(queryStatement) == SQLITE_ROW else {
            return -1
        }
        // Extract time from row
        let timeOfOldestMessage: Int64 = sqlite3_column_int64(queryStatement, 0)
        return Int(timeOfOldestMessage)
    }

    func getIDOfOldestEntryInDatabase(sqlQuery: String) throws -> String {
        // SELECT "id" FROM "SearchableMessage" ORDER BY "time" ASC LIMIT 1
        guard let queryStatement = try? prepareStatement(sql: sqlQuery) else {
            return ""
        }
        defer {
            sqlite3_finalize(queryStatement)
        }
        // Execute statement
        guard sqlite3_step(queryStatement) == SQLITE_ROW else {
            return ""
        }
        // Extract id from row
        guard let queryResult = sqlite3_column_text(queryStatement, 0) else {
            print("Query result is nil!")
            return ""
        }
        return String(cString: queryResult)
    }

    func getNumberOfEntriesInDatabase(sqlQuery: String) throws -> Int {
        // SELECT COUNT(*) FROM SearchableMessage;
        guard let queryStatement = try? prepareStatement(sql: sqlQuery) else {
            return -1
        }
        defer {
            sqlite3_finalize(queryStatement)
        }
        // Execute statement
        guard sqlite3_step(queryStatement) == SQLITE_ROW else {
            return -1
        }
        let entries: Int32 = sqlite3_column_int(queryStatement, 0)
        return Int(entries)
    }
}
