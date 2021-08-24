//
//  ConversationDataService+CollectionFetching.swift
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
import Groot

// MARK: - Collection fetching
extension ConversationDataService {
    func fetchConversationCounts(addressID: String?, completion: ((Result<Void, Error>) -> Void)?) {
        let conversationCountRequest = ConversationCountRequest(addressID: addressID)
        self.apiService.GET(conversationCountRequest) { _, response, error in
            if let error = error {
                completion?(.failure(error))
                return
            } else {
                let countDict = response?["Counts"] as? [[String: Any]]
                self.eventsService?.processEvents(conversationCounts: countDict)
                completion?(.success(()))
            }
        }
    }

    func fetchConversations(for labelID: String,
                            before timestamp: Int,
                            unreadOnly: Bool,
                            shouldReset: Bool,
                            completion: ((Result<Void, Error>) -> Void)?) {
        var para = ConversationsRequest.Parameters()
        if timestamp > 0 {
            para.end = timestamp - 1
        }
        if unreadOnly {
            para.unread = 1
        }
        para.limit = 50
        para.sort = "Time"
        para.desc = 1
        para.labelID = labelID

        let request = ConversationsRequest(para)
        self.apiService.GET(request) { _, responseDict, error in
            if let err = error {
                DispatchQueue.main.async {
                    completion?(.failure(err))
                }
                return
            } else {
                let response = ConversationsResponse()
                guard response.ParseResponse(responseDict) else {
                    let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                    DispatchQueue.main.async {
                        completion?(.failure(err))
                    }
                    return
                }
                if shouldReset {
                    self.cleanAll()
                    self.lastUpdatedStore.removeUpdateTimeExceptUnread(by: self.userID, type: .singleMessage)
                    self.lastUpdatedStore.removeUpdateTimeExceptUnread(by: self.userID, type: .conversation)
                    self.lastUpdatedStore.clear()
                }
                let messcount = responseDict?["Total"] as? Int ?? 0
                let context = self.coreDataService.rootSavingContext
                self.coreDataService.enqueue(context: context) { context in
                    do {
                        var conversationsDict = response.conversationsDict

                        for index in conversationsDict.indices {
                            conversationsDict[index]["UserID"] = self.userID
                            let conversationID = conversationsDict[index]["ID"]
                            if var labels = conversationsDict[index]["Labels"] as? [[String: Any]] {
                                for index in labels.indices {
                                    labels[index]["UserID"] = self.userID
                                    labels[index]["ConversationID"] = conversationID
                                }
                                conversationsDict[index]["Labels"] = labels
                            }
                        }

                        if let conversations =
                            try GRTJSONSerialization.objects(withEntityName: Conversation.Attributes.entityName,
                                                             fromJSONArray: conversationsDict,
                                                             in: context) as? [Conversation] {
                            for conversation in conversations {
                                if let labels = conversation.labels as? Set<ContextLabel> {
                                    for label in labels {
                                        label.order = conversation.order
                                    }
                                }
                            }
                            if let error = context.saveUpstreamIfNeeded() {
                                PMLog.D(" error: \(error)")
                            }
                            
                            if let lastConversation = conversations.last, let firstConversation = conversations.first {
                                let updateTime = self.lastUpdatedStore.lastUpdateDefault(by: labelID,
                                                                                         userID: self.userID,
                                                                                         context: context,
                                                                                         type: .conversation)
                                if unreadOnly {
                                    //Update unread query time
                                    if updateTime.isUnreadNew {
                                        updateTime.unreadStart = firstConversation.getTime(labelID: labelID) ?? Date()
                                    }
                                    if let time = lastConversation.getTime(labelID: labelID),
                                       (updateTime.unreadEndTime.compare(time) == .orderedDescending)
                                        || updateTime.unreadEndTime == .distantPast {
                                        updateTime.unreadEnd = time
                                    }
                                } else {
                                    // Update normal query time
                                    if updateTime.isNew {
                                        updateTime.start = firstConversation.getTime(labelID: labelID) ?? Date()
                                        updateTime.total = Int32(messcount)
                                    }
                                    if let time = lastConversation.getTime(labelID: labelID),
                                       (updateTime.endTime.compare(time) == .orderedDescending)
                                        || updateTime.endTime == .distantPast {
                                        updateTime.end = time
                                    }
                                    updateTime.update = Date()
                                }
                            }
                        }
                        DispatchQueue.main.async {
                            completion?(.success(()))
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

    func fetchConversations(with conversationIDs: [String], completion: ((Result<Void, Error>) -> Void)?) {
        var para = ConversationsRequest.Parameters()
        para.IDs = conversationIDs
        
        let request = ConversationsRequest(para)
        self.apiService.GET(request) { (task, responseDict, error) in
            if let err = error {
                DispatchQueue.main.async {
                    completion?(.failure(err))
                }
            } else {
                let response = ConversationsResponse()
                guard response.ParseResponse(responseDict) else {
                    let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                    DispatchQueue.main.async {
                        completion?(.failure(err))
                    }
                    return
                }
                
                let context = self.coreDataService.rootSavingContext
                self.coreDataService.enqueue(context: context) { (context) in
                    do {
                        var conversationsDict = response.conversationsDict
                        
                        guard !conversationsDict.isEmpty else {
                            DispatchQueue.main.async {
                                completion?(.failure(NSError.protonMailError(1000, localizedDescription: "Data not found")))
                            }
                            return
                        }
                        
                        for index in conversationsDict.indices {
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
                            for conversation in conversations {
                                if let labels = conversation.labels as? Set<ContextLabel> {
                                    for label in labels {
                                        label.order = conversation.order
                                    }
                                }
                            }
                            if let error = context.saveUpstreamIfNeeded() {
                                PMLog.D(" error: \(error)")
                            }
                        }
                        DispatchQueue.main.async {
                            completion?(.success(()))
                        }
                    } catch {
                        PMLog.D("error: \(error)")
                        DispatchQueue.main.async {
                            completion?(.failure(error as NSError))
                        }
                    }
                }
            }
        }
    }
}
