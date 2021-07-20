//
//  EncryptedSearchIndexService.swift
//  ProtonMail
//
//  Created by Ralph Ankele on 19.07.21.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import Foundation
import SQLite

public class EncryptedSearchIndexService {
    //instance of Singleton
    static let shared = EncryptedSearchIndexService()
    
    //set initializer to private - Singleton
    private init() {
        //TODO initialize variables if needed
        databaseSchema = DatabaseEntries()
        searchableMessages = Table(DatabaseConstants.Table_Searchable_Messages)
    }
    
    internal var handleToSQliteDB: Connection?
    internal var databaseSchema: DatabaseEntries
    internal var searchableMessages: Table
}

extension EncryptedSearchIndexService {
    func createSearchIndex() -> Connection? {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let path = urls[0]
        
        do {
            self.handleToSQliteDB = try Connection("\(path)/encryptedSearchIndex.sqlite3")
            print("path to database: ", path)
        } catch {
            print("Create database connection. Unexpected error: \(error).")
        }
        return self.handleToSQliteDB
    }
    
    enum DatabaseConstants {
        static let Table_Searchable_Messages = "SearchableMessage"
        static let Column_Searchable_Message_Id = "ID"
        static let Column_Searchable_Message_Time = "Time"
        static let Column_Searchable_Message_Refresh_Bit = "RefreshBit"
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
    }
    
    struct DatabaseEntries {
        var messageID:Expression<String> = Expression(value: "")
        var time:Expression<CLong> = Expression(value: 0)
        var labelIDs:Expression<String> = Expression(value: "")
        var isStarred:Expression<Bool?> = Expression(value: nil)
        var unread:Expression<Bool> = Expression(value: false)
        var location:Expression<Int> = Expression(value: -1)
        var order:Expression<CLong?> = Expression(value: nil)
        var refreshBit:Expression<Bool> = Expression(value: false)
        var hasBody:Expression<Bool> = Expression(value: false)
        var decryptionFailed:Expression<Bool> = Expression(value: false)
        var encryptionIV: Expression<String?> = Expression(value: nil)
        var encryptedContent:Expression<String?> = Expression(value: nil)
        var encryptedContentFile: Expression<String?> = Expression(value: nil)
    }
    
    func createSearchIndexTable() -> Void {
        //self.searchableMessages = Table(DatabaseConstants.Table_Searchable_Messages)
        self.databaseSchema = DatabaseEntries(messageID: Expression<String>(DatabaseConstants.Column_Searchable_Message_Id), time: Expression<CLong>(DatabaseConstants.Column_Searchable_Message_Time), labelIDs: Expression<String>(DatabaseConstants.Column_Searchable_Message_Labels), isStarred: Expression<Bool?>(DatabaseConstants.Column_Searchable_Message_Is_Starred), unread: Expression<Bool>(DatabaseConstants.Column_Searchable_Message_Unread), location: Expression<Int>(DatabaseConstants.Column_Searchable_Message_Location), order: Expression<CLong?>(DatabaseConstants.Column_Searchable_Message_Order), refreshBit: Expression<Bool>(DatabaseConstants.Column_Searchable_Message_Refresh_Bit), hasBody: Expression<Bool>(DatabaseConstants.Column_Searchable_Message_Has_Body), decryptionFailed: Expression<Bool>(DatabaseConstants.Column_Searchable_Message_Decryption_Failed), encryptionIV: Expression<String?>(DatabaseConstants.Column_Searchable_Message_Encryption_IV), encryptedContent: Expression<String?>(DatabaseConstants.Column_Searchable_Message_Encrypted_Content), encryptedContentFile: Expression<String?>(DatabaseConstants.Column_Searchable_Message_Encrypted_Content_File))
        
        do {
            try self.handleToSQliteDB?.run(self.searchableMessages.create(ifNotExists: true) {
                t in
                t.column(self.databaseSchema.messageID, primaryKey: true)  //TODO set default value
                t.column(self.databaseSchema.time, defaultValue: 0)
                t.column(self.databaseSchema.labelIDs)    //TODO set default value
                t.column(self.databaseSchema.isStarred, defaultValue: nil)
                t.column(self.databaseSchema.unread, defaultValue: false)
                t.column(self.databaseSchema.location, defaultValue: -1)
                t.column(self.databaseSchema.order, defaultValue: nil)
                t.column(self.databaseSchema.refreshBit, defaultValue: false)
                t.column(self.databaseSchema.hasBody, defaultValue: false)
                t.column(self.databaseSchema.decryptionFailed, defaultValue: false)
                t.column(self.databaseSchema.encryptionIV, defaultValue: nil)
                t.column(self.databaseSchema.encryptedContent, defaultValue: nil)
                t.column(self.databaseSchema.encryptedContentFile, defaultValue: nil)
            })
        } catch {
            print("Create Table. Unexpected error: \(error).")
        }
        
        //TODO only return if successfully generated (otherwise return nil)
        //return messages
    }
    
    func addNewEntryToSearchIndex(messageID:String, time: Int, labelIDs: NSSet, isStarred:Bool, unread:Bool, location:Int, order:Int, refreshBit:Bool, hasBody:Bool, decryptionFailed:Bool, encryptionIV:String, encryptedContent:String, encryptedContentFile:String) -> Int64? {
        
        var rowID:Int64? = -1
        var allLabels:String = ""
        for (index, label) in labelIDs.enumerated() {
            let id:String = (label as! Label).labelID
            if index == 0 {
                allLabels += id
            } else {
                allLabels += ";" + id
            }
        }
        
        do {
            let insert: Insert? = self.searchableMessages.insert(self.databaseSchema.messageID <- messageID, self.databaseSchema.time <- time, self.databaseSchema.labelIDs <- allLabels, self.databaseSchema.isStarred <- isStarred, self.databaseSchema.unread <- unread, self.databaseSchema.location <- location, self.databaseSchema.order <- order, self.databaseSchema.refreshBit <- refreshBit, self.databaseSchema.hasBody <- hasBody, self.databaseSchema.decryptionFailed <- decryptionFailed, self.databaseSchema.encryptionIV <- encryptionIV, self.databaseSchema.encryptedContent <- encryptedContent, self.databaseSchema.encryptedContentFile <- encryptedContentFile)
            rowID = try self.handleToSQliteDB?.run(insert!)
        } catch {
            print("Insert in Table. Unexpected error: \(error).")
        }
        return rowID
    }
}
