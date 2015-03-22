//
//  MessageQueue.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

class MessageQueue: PersistentQueue {
 
    private struct Key {
        static let id = "id"
        static let action = "action"
    }
    
    // MARK: - Public variables
    
    var isBlocked: Bool = false
    var isInProgress: Bool = false

    func addMessage(messageID: String, action: MessageAction) -> NSUUID {
        let element = [Key.id : messageID, Key.action : action.rawValue]
        
        return add(element)
    }
    
    func nextMessage() -> (uuid: NSUUID, messageID: String, action: String)? {
        if isBlocked || isInProgress {
            return nil
        }
        
        if let (uuid, object: AnyObject) = next() {
            if let element = object as? [String : String] {
                if let id = element[Key.id] {
                    if let action = element[Key.action] {
                        return (uuid, id, action)
                    }
                }
            }
            
            NSLog("\(__FUNCTION__) Removing invalid networkElement: \(object) from the queue.")
            remove(elementID: uuid)
        }
        
        return nil
    }
}
