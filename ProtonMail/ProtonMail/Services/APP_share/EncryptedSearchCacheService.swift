// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import Crypto

public class EncryptedSearchCacheService {
    //instance of Singleton
    static let shared = EncryptedSearchCacheService()
    
    //set initializer to private - Singleton
    private init() {
        self.maxCacheSize = 0   //TODO intialize
        self.batchSize = 0      //TODO initialize
        self.cache = EncryptedsearchCache(self.maxCacheSize)
    }
    
    internal var maxCacheSize: Int64 = 0
    internal var batchSize: Int64 = 0
    internal var cache: EncryptedsearchCache? = nil
    internal var currentUserID: String = ""
}

extension EncryptedSearchCacheService {
    func buildCacheForUser(userId: String, dbParams: EncryptedsearchDBParams, cipher: EncryptedsearchAESGCMCipher) -> EncryptedsearchCache {
        print("Build cache for user \(userId)")
        //If cache is not build or we have a new user
        if currentUserID != userId || !(self.cache?.isBuilt())! {
            print("cache not available, build new cache")
            self.cache?.deleteAll()
            let parallelDecryptions: Int = 100  //TODO why 100?
            do {
                try self.cache?.cacheIndex(dbParams, cipher: cipher, batchSize: Int(self.batchSize), parallelDecryptions: parallelDecryptions)
            } catch {
                print("Error when building the cache: ", error)
            }
            self.currentUserID = userId
        }
        print("cache: ", self.cache!)
        return self.cache!
    }
    
    func deleteCache(userID: String) {
        if userID == currentUserID {
            self.cache?.deleteAll()
            self.currentUserID = ""
        }
    }
    
    func updateCachedMessage(){
        //TODO implement
    }
    
    func deleteCachedMessage(){
        //TODO implement
    }
    
    func isCacheBuilt(userID: String) -> Bool {
        return self.currentUserID == userID && ((self.cache?.isBuilt()) != nil)
    }
}
