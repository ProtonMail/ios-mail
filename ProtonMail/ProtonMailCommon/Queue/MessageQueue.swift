//
//  MessageQueue.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
    }
    
    // MARK: - variables
    var isBlocked: Bool = false
    var isInProgress: Bool = false
    var isRequiredHumanCheck : Bool = false
    
    //TODO::here need input the time of action when local cache changed.
    func addMessage(_ messageID: String, action: MessageAction, data1: String = "", data2: String = "") -> UUID {
        let time = Date().timeIntervalSince1970
        let element = [Key.id : messageID, Key.action : action.rawValue, Key.time : "\(time)", Key.count : "0", Key.data1 : data1, Key.data2 : data2]
        return add(element as NSCoding)
    }
    
    func nextMessage() -> (uuid: UUID, messageID: String, action: String, data1: String, data2: String)? {
        if isBlocked || isInProgress || isRequiredHumanCheck {
            return nil
        }
        if let (uuid, object) = next() {
            if let element = object as? [String : String] {
                if let id = element[Key.id] {
                    if let action = element[Key.action] {
                        let data1 = element[Key.data1] ?? ""
                        let data2 = element[Key.data2] ?? ""
                        return (uuid as UUID, id, action, data1, data2)
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
                let element = object[Key.object] as? [String: String],
                let id = element[Key.id] else {
                    return nil
            }
            return id
        }
        return Array(Set(ids))
    }
    
    func removeDoubleSent(messageID : String, actions: [String]) {
        self.removeDuplicated(messageID, key: Key.id, actionKey: Key.action, actions: actions)
    }
}
