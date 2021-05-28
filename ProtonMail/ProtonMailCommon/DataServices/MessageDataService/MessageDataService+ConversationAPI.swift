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
                        if var labels = conversationDict["Labels"] as? [[String: Any]] {
                            for (index, _) in labels.enumerated() {
                                labels[index]["UserID"] = self.userID
                                labels[index]["ConversationID"] = conversationID
                            }
                            conversationDict["Labels"] = labels
                        }
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
