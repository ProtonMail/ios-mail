//
//  MessageDataService+ConversationActions.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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
import CoreData

extension MessageDataService {
    @discardableResult
    func move(conversations: [Conversation], from fLabel: String, to tLabel: String, queue: Bool = true) -> Bool {
        #warning("TODO: - v4 supprot offline mode")
        guard !conversations.isEmpty else {
            return false
        }

        if queue {
            let ids = conversations.map{ $0.objectID.uriRepresentation().absoluteString }
            self.queue(.folder, isConversation: true, data1: fLabel, data2: tLabel, otherData: ids)
        }
        return true
    }
    
    @discardableResult
    func mark(conversations: [Conversation], labelID: String, unRead: Bool) -> Bool {
        #warning("TODO: - v4 supprot offline mode")
        guard !conversations.isEmpty else {
            return false
        }
        guard let context = conversations.first?.managedObjectContext else {
            return false
        }
        let ids = conversations.map{ $0.objectID.uriRepresentation().absoluteString }
        self.queue(unRead ? .unread : .read, isConversation: true, data1: "", data2: "", otherData: ids)
        
        var hasError = false
        context.performAndWait {
            for conversation in conversations {
                if let conversation = Conversation.conversationForConversationID(conversation.conversationID, inManagedObjectContext: context) {
                    conversation.applyMarksAsChanges(unRead: unRead, labelID: labelID)
                    
                    //Read action
                    if unRead == false {
                        let msgs = Message.messagesForConversationID(conversation.conversationID, inManagedObjectContext: context)
                        msgs?.forEach({ (msg) in
                            guard msg.getLableIDs().contains(labelID) else {
                                return
                            }
                            msg.unRead = unRead
                        })
                    }
                }
            }
            
            let error = context.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
                hasError = true
            }
        }
        
        if hasError {
            return false
        }
        
        #warning("v4 update counter")
        return true
    }
    
    @discardableResult
    func label(conversations: [Conversation], label: String, apply: Bool) -> Bool {
        guard !conversations.isEmpty else {
            return false
        }
        #warning("TODO: -v4 offline mode supprot")
        
        let ids = conversations.map{ $0.objectID.uriRepresentation().absoluteString }
        self.queue(apply ? .label : .unlabel, isConversation: true, data1: label, data2: "", otherData: ids)
        return true
    }
}

extension MessageDataService {
    func fetchConversations(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Conversation] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Conversation.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K in %@", Conversation.Attributes.conversationID, selected)
        do {
            if let conversations = try context.fetch(fetchRequest) as? [Conversation] {
                return conversations
            }
        } catch let ex as NSError {
            PMLog.D("fetch error: \(ex)")
        }
        return []
    }
}
