//
//  MessageQueue.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation

let sharedMessageQueue = MessageQueue(queueName: "writeQueue")
let sharedFailedQueue = MessageQueue(queueName: "failedQueue")

class MessageQueue: PersistentQueue {
    fileprivate struct Key {
        static let id = "id"
        static let action = "action"
        static let time = "time"
        static let count = "count"
        static let data1 = "data1"
        static let data2 = "data2"
        static let userId = "userId"
    }
    
    // MARK: - variables
    var isBlocked: Bool = false
    var isInProgress: Bool = false
    var isRequiredHumanCheck : Bool = false
    
    //TODO::here need input the time of action when local cache changed.
    func addMessage(_ messageID: String, action: MessageAction, data1: String = "", data2: String = "", userId: String = "") -> UUID {
        let time = Date().timeIntervalSince1970
        let element = [Key.id : messageID, Key.action : action.rawValue, Key.time : "\(time)", Key.count : "0", Key.data1 : data1, Key.data2 : data2, Key.userId: userId]
        return add(element as NSCoding)
    }
    
    func nextMessage() -> (uuid: UUID, messageID: String, action: String, data1: String, data2: String, userId: String)? {
        if isBlocked || isInProgress || isRequiredHumanCheck {
            return nil
        }
        if let (uuid, object) = next() {
            if let element = object as? [String : String] {
                if let id = element[Key.id] {
                    if let action = element[Key.action] {
                        let data1 = element[Key.data1] ?? ""
                        let data2 = element[Key.data2] ?? ""
                        let userId = element[Key.userId] ?? ""
                        return (uuid as UUID, id, action, data1, data2, userId)
                    }
                }
            }
            PMLog.D(" Removing invalid networkElement: \(object) from the queue.")
            let _ = remove(uuid)
        }
        return nil
    }
    
    func queuedMessageIds() -> [String] {
        let ids = self.queue.compactMap { entryOfQueue -> String? in
            guard let object = entryOfQueue as? [String: Any],
                let element = object[PersistentQueue.Key.object] as? [String: String],
                let id = element[MessageQueue.Key.id] else {
                    return nil
            }
            return id
        }
        return Array(Set(ids))
    }
    
    func removeDoubleSent(messageID : String, actions: [String]) {
        self.removeDuplicated(messageID, key: Key.id, actionKey: Key.action, actions: actions)
    }
    
    func isAnyQueuedMessage(userID: String) -> Bool {
        let msgs = self.queue.compactMap { (entryOfQueue) -> String? in
            guard let object = entryOfQueue as? [String: Any],
                let element = object[PersistentQueue.Key.object] as? [String: String],
                let userId = element[MessageQueue.Key.userId] else {
                    return nil
            }
            if userId == userID {
                return userId
            }
            return nil
        }
        return msgs.isEmpty ? false : true
    }
    
    func removeAllQueuedMessage(userId: String) {
        self.remove(key: MessageQueue.Key.userId, value: userId)
    }
}
