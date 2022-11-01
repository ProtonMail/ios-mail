//
//  LocalConversationUpdater.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import CoreData
import Foundation

final class LocalConversationUpdater {
    private let contextProvider: CoreDataContextProviderProtocol
    private let userID: String

    init(contextProvider: CoreDataContextProviderProtocol, userID: String) {
        self.contextProvider = contextProvider
        self.userID = userID
    }

    func delete(conversationIDs: [ConversationID],
                completion: ((Result<Void, Error>) -> Void)?) {
        contextProvider.performAndWaitOnRootSavingContext { context in
            for conversationID in conversationIDs {
                guard let conversationInContext = Conversation
                        .conversationForConversationID(conversationID.rawValue,
                                                       inManagedObjectContext: context) else {
                    continue
                }
                // Mark as unread when deleting which will in turn update counters
                self.mark(conversationIDs: [conversationID],
                          asUnread: false,
                          labelID: Message.Location.trash.labelID) { _ in
                    context.delete(conversationInContext)
                    let messages = Message.messagesForConversationID(conversationID.rawValue,
                                                                     inManagedObjectContext: context)
                    messages?.forEach({ message in
                        context.delete(message)
                    })
                }
            }

            self.save(context: context, completion: completion)
        }
    }

    func mark(conversationIDs: [ConversationID],
              asUnread: Bool,
              labelID: LabelID,
              completion: ((Result<Void, Error>) -> Void)?) {
        let labelID = labelID
        contextProvider.performAndWaitOnRootSavingContext { context in
            for conversationID in conversationIDs {
                guard let conversationInContext = Conversation
                        .conversationForConversationID(conversationID.rawValue,
                                                       inManagedObjectContext: context) else {
                    continue
                }
                conversationInContext.applyMarksAsChanges(unRead: asUnread, labelID: labelID.rawValue)
            }

            self.save(context: context, completion: completion)
        }
    }

    // swiftlint:disable function_body_length
    func editLabels(conversationIDs: [ConversationID],
                    labelToRemove: LabelID?,
                    labelToAdd: LabelID?,
                    isFolder: Bool,
                    completion: ((Result<Void, Error>) -> Void)?) {
        contextProvider.performAndWaitOnRootSavingContext { context in
            for conversationID in conversationIDs {
                guard let conversation = Conversation
                        .conversationForConversationID(conversationID.rawValue, inManagedObjectContext: context) else {
                    continue
                }
                let messages = Message
                    .messagesForConversationID(conversationID.rawValue,
                                               inManagedObjectContext: context)
                let untouchedLocations: [LabelID] = [
                    Message.Location.draft.labelID,
                    Message.Location.sent.labelID,
                    Message.Location.allmail.labelID
                ]

                var labelsThatAlreadyUpdateTheUnreadCount: [LabelID] = []
                if isFolder, let messages = messages {
                    // If folder, first remove all labels that are not draft, sent, starred, archive, allmail
                    labelsThatAlreadyUpdateTheUnreadCount = self.removeSpecificFolder(
                        of: conversation,
                        messagesOfConversation: messages,
                        context: context
                    )
                }

                if let removed = labelToRemove, !removed.rawValue.isEmpty,
                   !untouchedLocations.contains(removed) {
                    let hasUnread = messages?.contains(where: { $0.unRead }) == true ||
                    conversation.isUnread(labelID: removed.rawValue)
                    conversation.applyLabelChanges(labelID: removed.rawValue, apply: false)
                    messages?.forEach { $0.remove(labelID: removed.rawValue) }
                    if hasUnread && !labelsThatAlreadyUpdateTheUnreadCount.contains(removed) {
                        self.updateConversationCount(for: removed, offset: -1, in: context)
                    }
                }

                if let added = labelToAdd, !added.rawValue.isEmpty {
                    let scheduleID = LabelLocation.scheduled.rawLabelID
                    if conversation.contains(of: scheduleID) &&
                        added == LabelLocation.trash.labelID {
                        self.updateLabelForTrashedScheduleConversation(conversation, messages: messages)
                    } else {
                        conversation.applyLabelChanges(labelID: added.rawValue, apply: true)
                        messages?.forEach { $0.add(labelID: added.rawValue) }
                    }
                    // When we trash the conversation, make all unread messages as read.
                    if added == Message.Location.trash.labelID {
                        messages?.forEach { $0.unRead = false }
                        PushUpdater().remove(notificationIdentifiers: messages?.compactMap({ $0.notificationId }))
                        conversation.labels
                            .compactMap({ $0 as? ContextLabel })
                            .filter({ $0.unreadCount != NSNumber(value: 0) })
                            .forEach({ contextLabel in
                                contextLabel.unreadCount = NSNumber(value: 0)
                                self.updateConversationCount(
                                    for: LabelID(contextLabel.labelID),
                                    offset: -1,
                                    in: context
                                )
                            })
                    } else {
                        let hasUnread = messages?.contains(where: { $0.unRead }) == true ||
                            /* Be carefull to handle the case that the message is not fetched.
                             Read status from all mail. */
                            conversation.isUnread(labelID: Message.Location.allmail.rawValue)
                        if hasUnread {
                            self.updateConversationCount(for: added, offset: 1, in: context)
                        }
                    }
                }
            }
            self.save(context: context, completion: completion)
        }
    }

    private func updateLabelForTrashedScheduleConversation(_ conversation: Conversation,
                                                           messages: [Message]?) {
        let scheduleID = LabelLocation.scheduled.rawLabelID
        let draftID = LabelLocation.draft.rawLabelID
        let trashID = LabelLocation.trash.rawLabelID
        conversation.applyLabelChanges(labelID: scheduleID, apply: false)
        conversation.applyLabelChanges(labelID: draftID, apply: true)
        var scheduledCount = 0
        messages?.forEach({ message in
            if message.contains(label: .scheduled) {
                message.add(labelID: draftID)
                message.remove(labelID: scheduleID)
                scheduledCount += 1
            } else {
                message.add(labelID: trashID)
            }
        })
        if scheduledCount != messages?.count {
            conversation.applyLabelChanges(labelID: trashID, apply: true)
        }
    }

    private func removeSpecificFolder(of conversation: Conversation,
                                      messagesOfConversation: [Message],
                                      context: NSManagedObjectContext) -> [LabelID] {
        let untouchedLocations: [Message.Location] = [.draft, .sent, .starred, .archive, .allmail, .scheduled]
        // If folder, first remove all labels that are not draft, sent, starred, archive, allmail, scheduled
        var labelsThatAlreadyUpdateTheUnreadCount: [LabelID] = []
        let allLabels = conversation.labels as? Set<ContextLabel> ?? []
        let filteredLabels = allLabels.filter({ !untouchedLocations.map(\.rawValue).contains($0.labelID) })
        for filteredLabel in filteredLabels {
            let label = Label.labelForLabelID(filteredLabel.labelID, inManagedObjectContext: context)
            // We clear only folder type labels
            if label?.type == 0 || label?.type == 3 {
                let hasUnread = messagesOfConversation.contains(where: { $0.unRead }) == true ||
                    conversation.isUnread(labelID: filteredLabel.labelID)
                conversation.applyLabelChanges(labelID: filteredLabel.labelID,
                                               apply: false)
                messagesOfConversation.forEach { $0.remove(labelID: filteredLabel.labelID) }
                if hasUnread {
                    let filteredID = LabelID(filteredLabel.labelID)
                    updateConversationCount(for: filteredID, offset: -1, in: context)
                    labelsThatAlreadyUpdateTheUnreadCount.append(filteredID)
                }
            }
         }
        return labelsThatAlreadyUpdateTheUnreadCount
    }

    private func updateConversationCount(for labelID: LabelID, offset: Int, in context: NSManagedObjectContext) {
        guard let contextLabel = ConversationCount.lastContextUpdate(by: labelID.rawValue,
                                                                     userID: self.userID,
                                                                     inManagedObjectContext: context) else {
            return
        }
        contextLabel.unread += Int32(offset)
        contextLabel.unread = max(contextLabel.unread, 0)
    }

    private func save(context: NSManagedObjectContext,
                      completion: ((Result<Void, Error>) -> Void)?) {
        let error = context.saveUpstreamIfNeeded()
        if let error = error {
            completion?(.failure(error))
        } else {
            completion?(.success(()))
        }
    }
}
