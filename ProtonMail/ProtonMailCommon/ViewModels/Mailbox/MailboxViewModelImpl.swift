//
//  MailboxViewModelImpl.swift
//  ProtonMail - Created on 8/15/15.
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

import CoreData
import Foundation

final class MailboxViewModelImpl: MailboxViewModel {
    private let label: Message.Location

    init(label: Message.Location,
         userManager: UserManager,
         usersManager: UsersManager,
         pushService: PushNotificationService,
         coreDataService: CoreDataService,
         lastUpdatedStore: LastUpdatedStoreProtocol,
         queueManager: QueueManager) {
        self.label = label
        super.init(labelID: label.rawValue,
                   userManager: userManager,
                   usersManager: usersManager,
                   pushService: pushService,
                   coreDataService: coreDataService,
                   lastUpdatedStore: lastUpdatedStore,
                   queueManager: queueManager)
    }

    override var localizedNavigationTitle: String {
        return self.label.localizedTitle
    }

    override func getSwipeTitle(_ action: MessageSwipeAction) -> String {
        action.description
    }

    override func isSwipeActionValid(_ action: MessageSwipeAction,
                                     message: Message) -> Bool {
        switch self.label {
        case .archive:
            return action != .archive
        case .starred:
            return action != .star
        case .spam:
            return action != .spam
        case .draft:
            return action != .spam && action != .archive
        case .sent:
            return action != .spam
        case .trash:
            return true
        case .allmail:
            return checkIsSwipeActionValidOf(message: message, action: action)
        default:
            return true
        }
    }

    private func checkIsSwipeActionValidOf(message: Message,
                                           action: MessageSwipeAction) -> Bool {
        switch action {
        case .none:
            return false
        case .unread:
            return message.unRead != true
        case .read:
            return message.unRead == true
        case .star:
            return !message.contains(label: .starred)
        case .unstar:
            return message.contains(label: .starred)
        case .trash:
            return !message.contains(label: .trash)
        case .labelAs:
            return true
        case .moveTo:
            return true
        case .archive:
            return !message.contains(label: .archive)
        case .spam:
            return !message.contains(label: .spam) && message.draft == false && !message.contains(label: .sent)
        }
    }

    override func isSwipeActionValid(_ action: MessageSwipeAction,
                                     conversation: Conversation) -> Bool {
        switch self.label {
        case .archive:
            return action != .archive
        case .starred:
            return action != .star
        case .spam:
            return action != .spam
        case .draft:
            return action != .spam && action != .archive
        case .sent:
            return action != .spam
        case .trash:
            return true
        case .allmail:
            return checkIsSwipeActionValidOf(conversation: conversation, action: action)
        default:
            return true
        }
    }

    private func checkIsSwipeActionValidOf(conversation: Conversation,
                                           action: MessageSwipeAction) -> Bool {
        switch action {
        case .none:
            return false
        case .unread:
            return !conversation.isUnread(labelID: labelID)
        case .read:
            return conversation.isUnread(labelID: labelID)
        case .star:
            return !conversation.starred
        case .unstar:
            return conversation.starred
        case .trash:
            return true
        case .labelAs:
            return true
        case .moveTo:
            return true
        case .archive:
            return !conversation.contains(of: Message.Location.archive.rawValue)
        case .spam:
            return !conversation.contains(of: Message.Location.spam.rawValue)
                && !conversation.contains(of: Message.Location.sent.rawValue)
        }
    }

    override func isDrafts() -> Bool {
        return self.label == .draft
    }

    override func isArchive() -> Bool {
        return self.label == .archive
    }

    override func isDelete() -> Bool {
        switch self.label {
        case .trash, .spam, .draft:
            return true
        default:
            return false
        }
    }

    override func showLocation() -> Bool {
        switch self.label {
        case .allmail, .draft:
            return true
        default:
            return false
        }
    }

    override func isShowEmptyFolder() -> Bool {
        switch self.label {
        case .trash, .spam, .draft:
            return true
        default:
            return false
        }
    }

    override func emptyFolder() {
        switch self.label {
        case .trash, .spam, .draft:
            self.messageService.empty(location: self.label)
        default:
            break
        }
    }

    override func ignoredLocationTitle() -> String {
        if self.label == .sent {
            return Message.Location.sent.title
        }
        if self.label == .trash {
            return Message.Location.trash.title
        }
        if self.label == .archive {
            return Message.Location.archive.title
        }
        if self.label == .draft {
            return Message.Location.draft.title
        }
        if self.label == .trash {
            return Message.Location.trash.title
        }
        return ""
    }

    override func reloadTable() -> Bool {
        return self.label == .draft
    }

    override func delete(message: Message) -> (SwipeResponse, UndoMessage?, Bool) {
        if self.labelId == Message.Location.trash.rawValue {
            return (.nothing, nil, false)
        } else {
            if messageService.move(messages: [message],
                                   from: [self.label.rawValue],
                                   to: Message.Location.trash.rawValue) {
                return (.showUndo,
                        UndoMessage(msgID: message.messageID,
                                    origLabels: self.label.rawValue,
                                    origHasStar: message.starred,
                                    newLabels: Message.Location.trash.rawValue), true)
            }
        }
        return (.nothing, nil, false)
    }
}
