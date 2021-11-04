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
        let maxMemory: Double = EncryptedSearchService.shared.getTotalAvailableMemory()
        self.maxCacheSize = Int64((maxMemory * self.searchCacheHeapPercent))
        self.batchSize = Int64((maxMemory * self.searchCacheHeapPercent) / self.searchMsgSize)
        self.cache = EncryptedsearchCache(self.maxCacheSize)
    }
    
    internal let searchCacheHeapPercent: Double = 0.2 // Percentage of heap that can be used by the cache
    internal let searchBatchHeapPercent: Double = 0.1 // Percentage of heap that can be used to load messages from the index
    internal let searchMsgSize: Double = 14000 // An estimation of how many bytes take a search message in memory
    internal var maxCacheSize: Int64 = 0
    var batchSize: Int64 = 0
    internal var cache: EncryptedsearchCache? = nil
    internal var currentUserID: String = ""
}

extension EncryptedSearchCacheService {
    func buildCacheForUser(userId: String, dbParams: EncryptedsearchDBParams, cipher: EncryptedsearchAESGCMCipher) -> EncryptedsearchCache {
        //If cache is not build or we have a new user
        if currentUserID != userId || !(self.cache?.isBuilt())! {
            print("Build cache for user \(userId)")
            self.cache?.deleteAll()
            do {
                try self.cache?.cacheIndex(dbParams, cipher: cipher, batchSize: Int(self.batchSize))
            } catch {
                print("Error when building the cache: ", error)
            }
            self.currentUserID = userId
        }
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
