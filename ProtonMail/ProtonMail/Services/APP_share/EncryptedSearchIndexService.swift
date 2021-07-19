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
    }
    
    internal var handleToSQliteDB: Connection?
}

extension EncryptedSearchIndexService {
    //TODO add functions to build the search index
    
    func createSearchIndex() -> Connection? {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let path = urls[0]
        
        do {
            self.handleToSQliteDB = try Connection("\(path)/encryptedSearchIndex.sqlite3")
        } catch {
            print("Unexpected error: \(error).")
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
    
    func createSearchIndexTable() -> Void {
        let messages = Table(DatabaseConstants.Table_Searchable_Messages)
        let id = Expression<String>(DatabaseConstants.Column_Searchable_Message_Id)
        let time = Expression<CLong>(DatabaseConstants.Column_Searchable_Message_Time)
        let refreshBit = Expression<Bool>(DatabaseConstants.Column_Searchable_Message_Refresh_Bit)
        //let labels = Expression<[String]>(DatabaseConstants.Column_Searchable_Message_Labels)
        let labels = Expression<String>(DatabaseConstants.Column_Searchable_Message_Labels)
        let hasBody = Expression<Bool>(DatabaseConstants.Column_Searchable_Message_Has_Body)
        let isStarred = Expression<Bool?>(DatabaseConstants.Column_Searchable_Message_Is_Starred)
        let unread = Expression<Bool>(DatabaseConstants.Column_Searchable_Message_Unread)
        let location = Expression<Int>(DatabaseConstants.Column_Searchable_Message_Location)
        let order = Expression<CLong?>(DatabaseConstants.Column_Searchable_Message_Order)
        let decryptionFailed = Expression<Bool>(DatabaseConstants.Column_Searchable_Message_Decryption_Failed)
        
        let encryptedContent = Expression<String?>(DatabaseConstants.Column_Searchable_Message_Encrypted_Content)
        let encryptedContentFile = Expression<String?>(DatabaseConstants.Column_Searchable_Message_Encrypted_Content_File)
        let encryptionIV = Expression<String?>(DatabaseConstants.Column_Searchable_Message_Encryption_IV)
        
        do {
            try self.handleToSQliteDB?.run(messages.create(ifNotExists: true) {
                t in
                t.column(id, primaryKey: true)  //TODO set default value
                t.column(time, defaultValue: 0)
                t.column(labels)    //TODO set default value
                t.column(isStarred, defaultValue: nil)
                t.column(unread, defaultValue: false)
                t.column(location, defaultValue: -1)
                t.column(order, defaultValue: nil)
                t.column(refreshBit, defaultValue: false)
                t.column(hasBody, defaultValue: false)
                t.column(decryptionFailed, defaultValue: false)
                t.column(encryptionIV, defaultValue: nil)
                t.column(encryptedContent, defaultValue: nil)
                t.column(encryptedContentFile, defaultValue: nil)
            })
        } catch {
            print("Unexpected error: \(error).")
        }
    }
}
