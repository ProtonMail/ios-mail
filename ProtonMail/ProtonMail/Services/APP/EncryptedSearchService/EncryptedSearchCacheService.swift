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

import Crypto
import Foundation

@available(iOS 12.0, *)
public class EncryptedSearchCacheService {
    // Instance of Singleton
    static let shared = EncryptedSearchCacheService()

    // Set initializer to private - Singleton
    private init() {
        let maxMemory: Double = EncryptedSearchService.shared.getTotalAvailableMemory()
        self.maxCacheSize = Int64((maxMemory * self.searchCacheHeapPercent))
        self.batchSize = Int64((maxMemory * self.searchCacheHeapPercent) / self.searchMsgSize)
        self.cache = EncryptedsearchCache(self.maxCacheSize)
    }

    // Percentage of heap that can be used by the cache
    internal let searchCacheHeapPercent: Double = 0.2
    // Percentage of heap that can be used to load messages from the index
    internal let searchBatchHeapPercent: Double = 0.1
    // An estimation of how many bytes take a search message in memory
    internal let searchMsgSize: Double = 14_000
    internal var maxCacheSize: Int64 = 0
    var batchSize: Int64 = 0
    internal var cache: EncryptedsearchCache?
    internal var currentUserID: String = ""
}

@available(iOS 12.0, *)
extension EncryptedSearchCacheService {
    func buildCacheForUser(userId: String,
                           dbParams: EncryptedsearchDBParams,
                           cipher: EncryptedsearchAESGCMCipher) -> EncryptedsearchCache? {
        // If cache is not build or we have a new user
        if currentUserID != userId || self.cache == nil {
            // Run on a separate thread
            DispatchQueue.global(qos: .userInitiated).async {
                self.cache?.deleteAll()
                do {
                    try self.cache?.cacheIndex(dbParams, cipher: cipher, batchSize: Int(self.batchSize))
                } catch {
                    print("Error when building the cache: ", error)
                }
            }
            self.currentUserID = userId
        }
        return self.cache
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

    func updateCachedMessage(userID: String, message: Message?) -> Bool {
        guard let message = message else {
            print("Error updating cached message. Message nil!")
            return false
        }

        if userID == currentUserID {
            if let cache = self.cache {
                let msg: EncryptedsearchMessage? = self.messageToEncryptedsearchMessage(msg: message, userID: userID)
                cache.update(msg)
                return true
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
            return false
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

    // swiftlint:disable function_body_length
    private func messageToEncryptedsearchMessage(msg: Message, userID: String) -> EncryptedsearchMessage? {
        var body: String? = ""
        do {
            body = try EncryptedSearchService.shared.messageService?.messageDecrypter.decrypt(message: msg)
        } catch {
            print("Error when decrypting messages: \(error).")
        }

        let emailContent: String = EmailparserExtractData(body, true)
        let encryptedContent: EncryptedsearchEncryptedMessageContent? =
        EncryptedSearchService.shared.createEncryptedContent(message: MessageEntity(msg),
                                                             cleanedBody: emailContent,
                                                             userID: userID)

        let sender: EncryptedsearchRecipient? = EncryptedsearchRecipient(msg.sender?.toContact()?.name,
                                                                         email: msg.sender?.toContact()?.email)
        let decoder = JSONDecoder()
        var esToList: [ESSender?] = []
        var esCcList: [ESSender?] = []
        var esBccList: [ESSender?] = []
        let jsonToListData: Data = msg.toList.data(using: .utf8)!
        let jsonCCListData: Data = msg.ccList.data(using: .utf8)!
        let jsonBCCListData: Data = msg.bccList.data(using: .utf8)!

        do {
            esToList = try decoder.decode([ESSender].self, from: jsonToListData)
            esCcList = try decoder.decode([ESSender].self, from: jsonCCListData)
            esBccList = try decoder.decode([ESSender].self, from: jsonBCCListData)
        } catch {
            print("Error when decoding message.tolist, ccList or bccList")
        }

        let toList: EncryptedsearchRecipientList = EncryptedsearchRecipientList()
        esToList.forEach { recipient in
            if let recipient = recipient {
                toList.add(EncryptedsearchRecipient(recipient.name, email: recipient.address))
            }
        }
        let ccList: EncryptedsearchRecipientList = EncryptedsearchRecipientList()
        esCcList.forEach { recipient in
            if let recipient = recipient {
                ccList.add(EncryptedsearchRecipient(recipient.name, email: recipient.address))
            }
        }
        let bccList: EncryptedsearchRecipientList = EncryptedsearchRecipientList()
        esBccList.forEach { recipient in
            if let recipient = recipient {
                bccList.add(EncryptedsearchRecipient(recipient.name, email: recipient.address))
            }
        }

        let decryptedMessageContent: EncryptedsearchDecryptedMessageContent? =
        EncryptedsearchNewDecryptedMessageContent(msg.title,
                                                  sender,
                                                  emailContent,
                                                  toList,
                                                  ccList,
                                                  bccList,
                                                  msg.addressID,
                                                  msg.conversationID,
                                                  Int64(truncating: msg.flags),
                                                  msg.unRead,
                                                  false, // isStarred
                                                  msg.replied,
                                                  msg.repliedAll,
                                                  msg.forwarded,
                                                  Int(truncating: msg.numAttachments),
                                                  Int64(msg.expirationTime?.timeIntervalSince1970 ?? 0))

        return EncryptedsearchMessage(msg.messageID,
                                      timeValue: Int64(msg.time?.timeIntervalSince1970 ?? 0),
                                      orderValue: Int64(truncating: msg.order),
                                      labelidsValue: (msg.labels.allObjects as? [String])?.joined(separator: ";"),
                                      encryptedValue: encryptedContent,
                                      decryptedValue: decryptedMessageContent)
    }
}
