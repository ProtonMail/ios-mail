//
//  ConversationDataService+SingleItemFetching.swift
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
import ProtonMailAnalytics

extension ConversationDataService {

    func fetchConversation(
        with conversationID: ConversationID,
        includeBodyOf messageID: MessageID?,
        callOrigin: String?,
        completion: ((Result<Conversation, Error>) -> Void)?
    ) {
        guard !conversationID.rawValue.isEmpty else {
            reportMissingConversationID(callOrigin: callOrigin)
            let err = NSError.protonMailError(1000, localizedDescription: "ID is empty.")
            DispatchQueue.main.async {
                completion?(.failure(err))
            }
            return
        }
        let request = ConversationDetailsRequest(conversationID: conversationID.rawValue,
                                                 messageID: messageID?.rawValue)
        self.apiService.GET(request) { (task, responseDict, error) in
            if let err = error {
                DispatchQueue.main.async {
                    completion?(.failure(err))
                }
            } else {
                let response = ConversationDetailsResponse()
                guard response.ParseResponse(responseDict) else {
                    let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                    DispatchQueue.main.async {
                        completion?(.failure(err))
                    }
                    return
                }
                
                let context = self.contextProvider.rootSavingContext
                context.perform {
                    do {
                        guard var conversationDict = response.conversation, var messagesDict = response.messages else {
                            let err = NSError.protonMailError(1000, localizedDescription: "Data not found")
                            DispatchQueue.main.async {
                                completion?(.failure(err))
                            }
                            return
                        }

                        conversationDict["UserID"] = self.userID.rawValue
                        if var labels = conversationDict["Labels"] as? [[String: Any]] {

                            for index in labels.indices {

                                labels[index]["UserID"] = self.userID.rawValue

                                labels[index]["ConversationID"] = conversationID.rawValue

                            }

                            conversationDict["Labels"] = labels

                        }
                        let conversation = try GRTJSONSerialization.object(withEntityName: Conversation.Attributes.entityName, fromJSONDictionary: conversationDict, in: context)
                        if let conversation = conversation as? Conversation,
                           let labels = conversation.labels as? Set<ContextLabel> {
                            for label in labels {
                                label.order = conversation.order
                            }
                            self.modifyNumMessageIfNeeded(conversation: conversation)
                        }
                        for (index, _) in messagesDict.enumerated() {
                            messagesDict[index]["UserID"] = self.userID.rawValue
                        }
                        let message = try GRTJSONSerialization.objects(withEntityName: Message.Attributes.entityName, fromJSONArray: messagesDict, in: context)
                        if let messages = message as? [Message] {
                            messages.first(where: { $0.messageID == messageID?.rawValue })?.isDetailDownloaded = true
                            if let conversation = conversation as? Conversation {
                                self.softDeleteMessageIfNeeded(conversation: conversation, messages: messages)
                            }
                        }

                        if let error = context.saveUpstreamIfNeeded() {
                            throw error
                        }

                        DispatchQueue.main.async {
                            if let conversation = conversation as? Conversation {
                                completion?(.success((conversation)))
                            } else {
                                let error = NSError(domain: "", code: -1,
                                                    localizedDescription: LocalString._error_no_object)
                                completion?(.failure(error))
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion?(.failure(error))
                        }
                    }
                }
            }
        }
    }

    private func reportMissingConversationID(callOrigin: String?) {
        Breadcrumbs.shared.add(message: "call from \(callOrigin ?? "-")", to: .malformedConversationRequest)
        Analytics.shared.sendError(
            .abortedConversationRequest,
            trace: Breadcrumbs.shared.trace(for: .malformedConversationRequest)
        )
    }
}
