//
//  MessageDataService+ConversationAPI.swift
//  ProtonMail
//
//
//  Copyright (c) 2020 Proton Technologies AG
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
import Groot
import ProtonCore_Services
import PromiseKit

extension MessageDataService {
    func fetchConversations(by iDs: [String], completion: CompletionBlock?) {
        var para = ConversationsRequest.Parameters()
        para.IDs = iDs
        
        let request = ConversationsRequest(para)
        self.apiService.GET(request) { (task, responseDict, error) in
            if let err = error {
                DispatchQueue.main.async {
                    completion?(task, responseDict, err)
                }
            } else {
                let response = ConversationsResponse()
                guard response.ParseResponse(responseDict) else {
                    let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                    DispatchQueue.main.async {
                        completion?(task, responseDict, err)
                    }
                    return
                }
                
                let context = self.coreDataService.rootSavingContext
                self.coreDataService.enqueue(context: context) { (context) in
                    do {
                        var conversationsDict = response.conversationsDict
                        
                        guard !conversationsDict.isEmpty else {
                            DispatchQueue.main.async {
                                completion?(task, responseDict, nil)
                            }
                            return
                        }
                        
                        for (index, _) in conversationsDict.enumerated() {
                            conversationsDict[index]["UserID"] = self.userID
                            let conversationID = conversationsDict[index]["ID"]
                            if var labels = conversationsDict[index]["Labels"] as? [[String: Any]] {
                                for (index, _) in labels.enumerated() {
                                    labels[index]["UserID"] = self.userID
                                    labels[index]["ConversationID"] = conversationID
                                }
                                conversationsDict[index]["Labels"] = labels
                            }
                        }
                        
                        if (try GRTJSONSerialization.objects(withEntityName: Conversation.Attributes.entityName, fromJSONArray: conversationsDict, in: context) as? [Conversation]) != nil {
                            if let error = context.saveUpstreamIfNeeded() {
                                PMLog.D(" error: \(error)")
                            }
                        }
                        DispatchQueue.main.async {
                            completion?(task, responseDict, error)
                        }
                    } catch {
                        PMLog.D("error: \(error)")
                        DispatchQueue.main.async {
                            completion?(task, responseDict, error as NSError)
                        }
                    }
                }
            }
        }
    }
    
    func fetchConversations(by labelID: String, time: Int, forceClean: Bool, isUnread: Bool, completion: CompletionBlock?) {
        //TODO: improve later
        var para = ConversationsRequest.Parameters()
        if time > 0 {
            para.end = time - 1
        }
        if isUnread {
            para.unread = 1
        }
        para.limit = 50
        para.sort = "Time"
        para.desc = 1
        para.labelID = labelID
        
        let request = ConversationsRequest(para)
        self.apiService.GET(request) { (task, responseDict, error) in
            if let err = error {
                DispatchQueue.main.async {
                    completion?(task, responseDict, err)
                }
            } else {
                let response = ConversationsResponse()
                guard response.ParseResponse(responseDict) else {
                    let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                    DispatchQueue.main.async {
                        completion?(task, responseDict, err)
                    }
                    return
                }
                
                let messcount = responseDict?["Total"] as? Int ?? 0
                let context = self.coreDataService.rootSavingContext
                self.coreDataService.enqueue(context: context) { (context) in
                    do {
                        var conversationsDict = response.conversationsDict
                        
                        guard !conversationsDict.isEmpty else {
                            DispatchQueue.main.async {
                                completion?(task, responseDict, nil)
                            }
                            return
                        }
                        
                        for (index, _) in conversationsDict.enumerated() {
                            conversationsDict[index]["UserID"] = self.userID
                            let conversationID = conversationsDict[index]["ID"]
                            if var labels = conversationsDict[index]["Labels"] as? [[String: Any]] {
                                for (index, _) in labels.enumerated() {
                                    labels[index]["UserID"] = self.userID
                                    labels[index]["ConversationID"] = conversationID
                                }
                                conversationsDict[index]["Labels"] = labels
                            }
                        }
                        
                        if let conversations = try GRTJSONSerialization.objects(withEntityName: Conversation.Attributes.entityName, fromJSONArray: conversationsDict, in: context) as? [Conversation] {
                            if let error = context.saveUpstreamIfNeeded() {
                                PMLog.D(" error: \(error)")
                            }
                            
                            if let lastConversation = conversations.last, let firstConversation = conversations.first {
                                let updateTime = self.lastUpdatedStore.lastUpdateDefault(by: labelID, userID: self.userID, context: context, type: .conversation)
                                if isUnread {
                                    //Update unread query time
                                    if updateTime.isUnreadNew {
                                        updateTime.unreadStart = firstConversation.getTime(labelID: labelID) ?? Date()
                                    }
                                    if let time = lastConversation.getTime(labelID: labelID), (updateTime.unreadEndTime.compare(time) == .orderedDescending) || updateTime.unreadEndTime == .distantPast {
                                        updateTime.unreadEnd = time
                                    }
                                } else {
                                    //Update normal query time
                                    if updateTime.isNew {
                                        updateTime.start = firstConversation.getTime(labelID: labelID) ?? Date()
                                        updateTime.total = Int32(messcount)
                                    }
                                    if let time = lastConversation.getTime(labelID: labelID), (updateTime.unreadEndTime.compare(time) == .orderedDescending) || updateTime.unreadEndTime == .distantPast {
                                        updateTime.end = time
                                    }
                                    updateTime.update = Date()
                                }
                            }
                        }

                        DispatchQueue.main.async {
                            //                            let conversaionIDs = conversationsDict.compactMap { (value) -> String? in
                            //                                return value["ID"] as? String
                            //                            }
                            completion?(task, responseDict, error)
                        }
                    } catch {
                        PMLog.D("error: \(error)")
                        DispatchQueue.main.async {
                            completion?(task, responseDict, error as NSError)
                        }
                    }
                }
            }
        }
    }

    func fetchConversationsWithReset(byLabel labelID: String,
                                     time: Int,
                                     completion: CompletionBlock?) {
        let getLatestEventID = EventLatestIDRequest()
        apiService.exec(route: getLatestEventID) { (task, response: EventLatestIDResponse) in
            if !response.eventID.isEmpty {
                let completionWrapper: CompletionBlock = { _, responseDict, error in
                    if error == nil {
                        self.lastUpdatedStore.clear()
                        _ = self.lastUpdatedStore.updateEventID(by: self.userID, eventID: response.eventID).ensure {
                            completion?(task, responseDict, error)
                        }
                    } else {
                        completion?(task, responseDict, error)
                    }
                }

                self.cleanMessage().then { _ -> Promise<Void> in
                    self.lastUpdatedStore.removeUpdateTime(by: self.userID, type: .singleMessage)
                    self.lastUpdatedStore.removeUpdateTime(by: self.userID, type: .conversation)
                    return self.contactDataService.cleanUp()
                }.ensure {
                    self.fetchConversations(by: labelID,
                                            time: time,
                                            forceClean: false,
                                            isUnread: false,
                                            completion: completionWrapper)
                    self.contactDataService.fetchContacts(completion: nil)
                    _ = self.labelDataService.fetchV4Labels()
                }.cauterize()
            } else {
                completion?(task, nil, nil)
            }
        }
    }

    func fetchConversationsOnlyWithReset(byLabel labelID: String,
                                         time: Int,
                                         completion: CompletionBlock?) {
        let getLatestEventID = EventLatestIDRequest()
        apiService.exec(route: getLatestEventID) { (task, response: EventLatestIDResponse) in
            if !response.eventID.isEmpty {
                let completionWrapper: CompletionBlock = { _, responseDict, error in
                    if error == nil {
                        self.lastUpdatedStore.clear()
                        _ = self.lastUpdatedStore.updateEventID(by: self.userID, eventID: response.eventID).ensure {
                            completion?(task, responseDict, error)
                        }
                    } else {
                        completion?(task, responseDict, error)
                    }
                }

                self.cleanMessage().then { _ -> Promise<Void> in
                    self.lastUpdatedStore.removeUpdateTime(by: self.userID, type: .singleMessage)
                    self.lastUpdatedStore.removeUpdateTime(by: self.userID, type: .conversation)
                    return Promise<Void>()
                }.ensure {
                    self.fetchConversations(by: labelID,
                                            time: time,
                                            forceClean: false,
                                            isUnread: false,
                                            completion: completionWrapper)
                    _ = self.labelDataService.fetchV4Labels()
                }.cauterize()
            } else {
                completion?(task, nil, nil)
            }
        }
    }
    
    func fetchConversationDetail(by conversationID: String, completion: ((Swift.Result<[String], Error>) -> Void)?) {
        let request = ConversationDetailsRequest(conversationID: conversationID, messageID: nil)
        self.apiService.GET(request) { (task, responseDict, error) in
            if let err = error {
                completion?(.failure(err))
            } else {
                let response = ConversationDetailsResponse()
                guard response.ParseResponse(responseDict) else {
                    let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                    completion?(.failure(err))
                    return
                }
                
                let context = self.coreDataService.rootSavingContext
                self.coreDataService.enqueue(context: context) { (context) in
                    do {
                        guard var conversationDict = response.conversation, var messagesDict = response.messages else {
                            let err = NSError.protonMailError(1000, localizedDescription: "Data not found")
                            completion?(.failure(err))
                            return
                        }
                        
                        conversationDict["UserID"] = self.userID
                        try GRTJSONSerialization.object(withEntityName: Conversation.Attributes.entityName, fromJSONDictionary: conversationDict, in: context)
                        
                        for (index, _) in messagesDict.enumerated() {
                            messagesDict[index]["UserID"] = self.userID
                        }
                        try GRTJSONSerialization.objects(withEntityName: Message.Attributes.entityName, fromJSONArray: messagesDict, in: context)
                        
                        if let error = context.saveUpstreamIfNeeded() {
                            throw error
                        }
                        
                        DispatchQueue.main.async {
                            let msgIDs = messagesDict.compactMap({ (value) -> String? in
                                return value["ID"] as? String
                            })
                            completion?(.success(msgIDs))
                        }
                    } catch {
                        PMLog.D("error: \(error)")
                        DispatchQueue.main.async {
                            completion?(.failure(error))
                        }
                    }
                }
            }
        }
    }
    
    func markConversationAsUnread(by conversationIDs: [String], currentLabelID: String, completion: ((Swift.Result<Bool, Error>) -> Void)?) {
        let request = ConversationUnreadRequest(conversationIDs: conversationIDs, labelID: currentLabelID)
        self.apiService.exec(route: request) { (task, response: ConversationUnreadResponse) in
            if let err = response.error {
                completion?(.failure(err))
                return
            }
            
            guard response.results != nil else {
                let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                completion?(.failure(err))
                return
            }
            completion?(.success(true))
        }
    }
    
    func markConversationAsRead(by conversationIDs: [String], completion: ((Swift.Result<Bool, Error>) -> Void)?) {
        let request = ConversationReadRequest(conversationIDs: conversationIDs)
        self.apiService.exec(route: request) { (task, response: ConversationReadResponse) in
            if let err = response.error {
                completion?(.failure(err))
                return
            }
            guard response.results != nil else {
                let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                completion?(.failure(err))
                return
            }
            completion?(.success(true))
        }
    }
    
    func fetchConversationsCount(addressID: String? = nil, completion: ((Swift.Result<[ConversationCountData], Error>) -> Void)?) {
        let request = ConversationCountRequest(addressID: addressID)
        self.apiService.GET(request) { (task, responseDict, error) in
            if let err = error {
                completion?(.failure(err))
            } else {
                let response = ConversationCountResponse()
                guard response.ParseResponse(responseDict) else {
                    let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                    completion?(.failure(err))
                    return
                }
                completion?(.success(response.counts ?? []))
            }
        }
    }
    
    func labelConversations(conversationIDs: [String], labelID: String, completion: ((Swift.Result<Bool, Error>) -> Void)?) {
        let request = ConversationLabelRequest(conversationIDs: conversationIDs, labelID: labelID)
        self.apiService.exec(route: request) { (task, response: ConversationLabelResponse) in
            if let err = response.error {
                completion?(.failure(err))
                return
            }
            
            guard response.results != nil else {
                let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                completion?(.failure(err))
                return
            }
            completion?(.success(true))
        }
    }
    
    func unlabelConversations(conversationIDs: [String], labelID: String, completion: ((Swift.Result<Bool, Error>) -> Void)?) {
        let request = ConversationUnlabelRequest(conversationIDs: conversationIDs, labelID: labelID)
        self.apiService.exec(route: request) { (task, response: ConversationUnlabelResponse) in
            if let err = response.error {
                completion?(.failure(err))
                return
            }
            
            guard response.results != nil else {
                let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                completion?(.failure(err))
                return
            }
            completion?(.success(true))
        }
    }
    
    ///labelID: where the conversation is at.
    func deleteConversations(conversationIDs: [String], labelID: String, completion: ((Swift.Result<Bool, Error>) -> Void)?) {
        let request = ConversationDeleteRequest(conversationIDs: conversationIDs, labelID: labelID)
        self.apiService.exec(route: request) { (task, response: ConversationDeleteResponse) in
            if let err = response.error {
                completion?(.failure(err))
                return
            }
            
            guard response.results != nil else {
                let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                completion?(.failure(err))
                return
            }
            completion?(.success(true))
        }
    }
}
