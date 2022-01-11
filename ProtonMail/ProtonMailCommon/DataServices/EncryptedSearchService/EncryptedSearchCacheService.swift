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

    func deleteCache(userID: String) -> Bool {
        if userID == currentUserID {
            if let cache = self.cache {
                cache.deleteAll()
                self.currentUserID = ""
            } else {
                print("Error cache is nil!")
            }
        } else {
            print("Error no cache for user \(userID) found!")
        }
        return false
    }

    func updateCachedMessage(userID: String, message: Message) -> Bool {
        if userID == currentUserID {
            if let cache = self.cache {
                let msg: EncryptedsearchMessage? = self.messageToEncryptedsearchMessage(msg: message, userID: userID)
                cache.update(msg)
            } else {
                print("Error cache is nil!")
            }
        } else {
            print("Error no cache for user \(userID) found!")
        }
        return false
    }

    func deleteCachedMessage(userID: String, messageID: String) -> Bool {
        if userID == currentUserID {
            if let cache = self.cache {
                return cache.deleteMessage(messageID)
            } else {
                print("Error cache is nil!")
            }
        } else {
            print("Error no cache for user \(userID) found!")
        }
        return false
    }

    func isCacheBuilt(userID: String) -> Bool {
        if self.currentUserID == userID {
            if let cache = self.cache {
                return cache.isBuilt()
            } else {
                print("Error cache is nil!")
            }
        } else {
            print("Error no cache for user \(userID) found!")
        }
        return false
    }

    func isPartial(userID: String) -> Bool {
        if self.currentUserID == userID {
            if let cache = self.cache {
                return cache.isPartial()
            } else {
                print("Error cache is nil!")
            }
        } else {
            print("Error no cache for user \(userID) found!")
        }
        return false
    }

    func getNumberOfCachedMessages(userID: String) -> Int {
        if self.currentUserID == userID {
            if let cache = self.cache {
                return cache.getLength()
            } else {
                print("Error cache is nil!")
            }
        } else {
            print("Error no cache for user \(userID) found!")
        }
        return 0
    }

    func getLastIDCached(userID: String) -> String? {
        if self.currentUserID == userID {
            if let cache = self.cache {
                return cache.getLastIDCached()
            } else {
                print("Error cache is nil!")
            }
        } else {
            print("Error no cache for user \(userID) found!")
        }
        return ""
    }

    func getLastTimeCached(userID: String) -> Int64? {
        if self.currentUserID == userID {
            if let cache = self.cache {
                return cache.getLastTimeCached()
            } else {
                print("Error cache is nil!")
            }
        } else {
            print("Error no cache for user \(userID) found!")
        }
        return -1
    }

    func getSizeOfCache(userID: String) -> Int64? {
        if self.currentUserID == userID {
            if let cache = self.cache {
                return cache.getSize()
            } else {
                print("Error cache is nil!")
            }
        } else {
            print("Error no cache for user \(userID) found!")
        }
        return -1
    }

    func containsMessage(userID: String, messageID: String) -> Bool {
        if self.currentUserID == userID {
            if let cache = self.cache {
                return cache.hasMessage(messageID)
            } else {
                print("Error cache is nil!")
            }
        } else {
            print("Error no cache for user \(userID) found!")
        }
        return false
    }

    func getLastCacheUserID() -> String? {
        return self.currentUserID
    }
    
    func messageToEncryptedsearchMessage(msg: Message, userID: String) -> EncryptedsearchMessage? {
        let esMessage:ESMessage? = EncryptedSearchService.shared.convertMessageToESMessage(for: msg)
        if let esMessage = esMessage {
            var body: String? = ""
            do {
                body = try EncryptedSearchService.shared.decryptBodyIfNeeded(message: esMessage)
            } catch {
                print("Error when decrypting messages: \(error).")
            }

            let emailContent: String = EmailparserExtractData(body, true)
            let encryptedContent: EncryptedsearchEncryptedMessageContent? = EncryptedSearchService.shared.createEncryptedContent(message: esMessage, cleanedBody: emailContent, userID: userID)
            
            //1. create decryptedMessageContent
            let sender: EncryptedsearchRecipient? = EncryptedsearchRecipient(esMessage.Sender.Name, email: esMessage.Sender.Address)
            let toList: EncryptedsearchRecipientList = EncryptedsearchRecipientList()
            esMessage.ToList.forEach { s in
                let r: EncryptedsearchRecipient? = EncryptedsearchRecipient(s!.Name, email: s!.Address)
                toList.add(r)
            }
            let ccList: EncryptedsearchRecipientList = EncryptedsearchRecipientList()
            esMessage.CCList.forEach { s in
                let r: EncryptedsearchRecipient? = EncryptedsearchRecipient(s!.Name, email: s!.Address)
                ccList.add(r)
            }
            let bccList: EncryptedsearchRecipientList = EncryptedsearchRecipientList()
            esMessage.BCCList.forEach { s in
                let r: EncryptedsearchRecipient? = EncryptedsearchRecipient(s!.Name, email: s!.Address)
                bccList.add(r)
            }

            let decryptedMessageContent: EncryptedsearchDecryptedMessageContent? = EncryptedsearchNewDecryptedMessageContent(esMessage.Subject, sender, emailContent, toList, ccList, bccList)

            return EncryptedsearchMessage(esMessage.ID, timeValue: Int64(msg.time!.timeIntervalSince1970), locationValue: Int64(Message.Location.allmail.rawValue)!, unreadValue: msg.unRead, isStarredValue: msg.starred, labelidsValue: esMessage.LabelIDs.joined(separator: ";"), encryptedValue: encryptedContent, decryptedValue: decryptedMessageContent)
        }
        return nil
    }
}
