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
}
