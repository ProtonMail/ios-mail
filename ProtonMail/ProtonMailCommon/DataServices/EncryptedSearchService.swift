//
//  EncryptedSearchService.swift
//  ProtonMail
//
//  Created by Ralph Ankele on 05.07.21.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import Foundation

public class EncryptedSearchService {
    //instance of Singleton
    static let shared = EncryptedSearchService()
    
    //set initializer to private - Singleton
    private init(){
        let users: UsersManager = sharedServices.get()
        user = users.firstUser!
        //TODO is the firstUser correct? Should we select user by ID?
    }
    
    internal var user: UserManager!
}

extension EncryptedSearchService {
    //function to build the search index needed for encrypted search
    func buildSearchIndex() -> Bool {
        //Run code in the background
        DispatchQueue.global(qos: .userInitiated).async {
            //TODO implement code in the background
            //1. download all messages locally
            NSLog("Downloading messages locally")
            ///  nonmaly fetching the message from server based on label and time. //TODO:: change to promise
            ///
            /// - Parameters:
            ///   - labelID: labelid, location id, forlder id
            ///   - time: the latest update time
            ///   - forceClean: force clean the exsition messages first
            ///   - completion: aync complete handler
            //func fetchMessages(byLabel labelID : String, time: Int, forceClean: Bool, isUnread: Bool, completion: CompletionBlock?)
            //MessageDataService:159
            
            let mailBoxID: String = "5"
            let service = self.user.messageService
            service.fetchMessages(byLabel: mailBoxID, time: 0, forceClean: false, isUnread: false) { _, result, error in
                //TODO implement completion block
                if error == nil {
                    NSLog("Messages: %@", result!)
                }
                NSLog("All messages downloaded")
            }
            
            
            //2. decrypt messages (using the user's PGP key)
            //3. extract keywords from message
            //4. encrypt search index (using local symmetric key)
            //5. store the keywords index in a local DB(sqlite3)
        }
        DispatchQueue.main.async {
            // TODO task has completed
            // Update UI -> progress bar?
        }
        return true
    }

    //Encrypted Search
    func search() {
        //TODO implement
    }
}
