//
//  LocalConversationUpdater.swift
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

import CoreData
import Foundation

final class LocalConversationUpdater {
    let userID: String

    init(userID: String) {
        self.userID = userID
    }

    func delete(conversations: [Conversation],
                in context: NSManagedObjectContext,
                completion: ((Result<Void, Error>) -> Void)?) {
        context.performAndWait {
            for conversation in conversations {
                guard let conversationInContext = Conversation
                        .conversationForConversationID(conversation.conversationID,
                                                       inManagedObjectContext: context) else {
                    continue
                }
                // Mark as unread when deleting which will in turn update counters
                mark(conversations: [conversationInContext],
                     in: context,
                     asUnread: false,
                     labelID: Message.Location.trash.rawValue) { _ in
                    context.delete(conversationInContext)
                    let messages = Message.messagesForConversationID(conversationInContext.conversationID,
                                                                     inManagedObjectContext: context)
                    messages?.forEach({ message in
                        context.delete(message)
                    })
                }
            }

            save(context: context, completion: completion)
        }
    }

    func mark(conversations: [Conversation],
              in context: NSManagedObjectContext,
              asUnread: Bool,
              labelID: String,
              completion: ((Result<Void, Error>) -> Void)?) {
        let labelID = labelID
        context.performAndWait {
            for conversation in conversations {
                guard let conversationInContext = Conversation
                        .conversationForConversationID(conversation.conversationID,
                                                       inManagedObjectContext: context) else {
                    continue
                }
                conversationInContext.applyMarksAsChanges(unRead: asUnread, labelID: labelID)
                // Mark contained messages as unread if marking conversation as unread
                if !asUnread {
                    let msgs = Message.messagesForConversationID(conversationInContext.conversationID,
                                                                 inManagedObjectContext: context)
                    msgs?.forEach({ msg in
                        guard msg.getLabelIDs().contains(labelID) else {
                            return
                        }
                        msg.unRead = asUnread
                    })
                }
                updateCounters(conversationInContext: conversationInContext, context: context, asUnread: asUnread)
            }

            save(context: context, completion: completion)
        }
    }

    func editLabels(conversations: [Conversation],
                    in context: NSManagedObjectContext,
                    labelToRemove: String?,
                    labelToAdd: String?,
                    isFolder: Bool,
                    completion: ((Result<Void, Error>) -> Void)?) {
        context.performAndWait {
            for conversation in conversations {
                guard let conversationInContext = Conversation
                        .conversationForConversationID(conversation.conversationID,
                                                       inManagedObjectContext: context) else {
                    continue
                }
                let messages = Message.messagesForConversationID(conversationInContext.conversationID,
                                                                 inManagedObjectContext: context)
                let wasUnread = conversationInContext.isUnread(labelID: labelToRemove ?? "")
                if isFolder, let labelToAdd = labelToAdd {
                    // If folder, first remove all labels that are not draft, sent, starred, archive, allmail
                    let untouchedLocations: [Message.Location] = [.draft, .sent, .starred, .archive, .allmail]
                    let allLabels = conversationInContext.labels as? Set<ContextLabel> ?? []
                    let filteredLabels = allLabels.filter({ !untouchedLocations.map(\.rawValue).contains($0.labelID) })
                    for filteredLabel in filteredLabels {
                        conversationInContext.applyLabelChanges(labelID: filteredLabel.labelID, apply: false)
                        messages?.forEach { $0.remove(labelID: filteredLabel.labelID) }
                    }
                    // Then, apply the new folder
                    conversationInContext.applyLabelChanges(labelID: labelToAdd, apply: true)
                    messages?.forEach { $0.add(labelID: labelToAdd) }
                    // If destination is Trash, mark as read and update counters
                    if labelToAdd == Message.Location.trash.rawValue {
                        mark(conversations: [conversationInContext],
                             in: context,
                             asUnread: false,
                             labelID: labelToAdd) { _ in }
                    } else {
                        updateCounters(conversationInContext: conversationInContext,
                                       context: context,
                                       asUnread: wasUnread)
                    }
                } else {
                    if let labelToRemove = labelToRemove {
                        conversationInContext.applyLabelChanges(labelID: labelToRemove, apply: false)
                        messages?.forEach { message in
                            message.remove(labelID: labelToRemove)
                        }
                    }
                    if let labelToAdd = labelToAdd {
                        conversationInContext.applyLabelChanges(labelID: labelToAdd, apply: true)
                        messages?.forEach { message in
                            message.add(labelID: labelToAdd)
                        }
                    }
                }
            }
            save(context: context, completion: completion)
        }
    }

    private func save(context: NSManagedObjectContext,
                      completion: ((Result<Void, Error>) -> Void)?) {
        let error = context.saveUpstreamIfNeeded()
        if let error = error {
            PMLog.D(" error: \(error)")
            completion?(.failure(error))
        } else {
            completion?(.success(()))
        }
    }
}

private extension LocalConversationUpdater {
    func updateCounters(conversationInContext: Conversation, context: NSManagedObjectContext, asUnread: Bool) {
        // Update the counters
        if let labels = conversationInContext.labels as? Set<ContextLabel> {
            for label in labels {
                let location = Message.Location(rawValue: label.labelID)
                switch location {
                case .draft, .sent:
                    // Draft and Sent show a count of messages, not of conversations, we don't update them
                    continue
                default:
                    if let conversationCount = ConversationCount.lastContextUpdate(by: label.labelID,
                                                                                   userID: self.userID,
                                                                                   inManagedObjectContext: context) {
                        if asUnread {
                            conversationCount.unread += 1
                        } else {
                            conversationCount.unread -= 1
                            conversationCount.unread = max(conversationCount.unread, 0)
                        }
                    }
                }
            }
        }
    }
}
