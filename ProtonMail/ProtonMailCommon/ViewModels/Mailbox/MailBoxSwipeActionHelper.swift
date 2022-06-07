// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

struct MailBoxSwipeActionHelper {
    func checkIsSwipeActionValidOn(location: Message.Location,
                                   action: MessageSwipeAction) -> Bool {
        switch location {
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
            return false
        default:
            return true
        }
    }

    // swiftlint:disable function_parameter_count
    func checkIsSwipeActionValidOnMessage(isDraft: Bool,
                                          isUnread: Bool,
                                          isStar: Bool,
                                          isInTrash: Bool,
                                          isInArchive: Bool,
                                          isInSent: Bool,
                                          isInSpam: Bool,
                                          action: MessageSwipeAction) -> Bool {
        switch action {
        case .none:
            return false
        case .unread:
            return isUnread != true
        case .read:
            return isUnread == true
        case .star:
            return !isStar
        case .unstar:
            return isStar
        case .trash:
            return !isInTrash
        case .labelAs:
            return true
        case .moveTo:
            return true
        case .archive:
            return !isInArchive
        case .spam:
            return !isInSpam && isDraft == false && !isInSent
        }
    }

    func checkIsSwipeActionValidOnConversation(isUnread: Bool,
                                               isStar: Bool,
                                               isInArchive: Bool,
                                               isInSpam: Bool,
                                               isInSent: Bool,
                                               action: MessageSwipeAction) -> Bool {
        switch action {
        case .none:
            return false
        case .unread:
            return !isUnread
        case .read:
            return isUnread
        case .star:
            return !isStar
        case .unstar:
            return isStar
        case .trash:
            return true
        case .labelAs:
            return true
        case .moveTo:
            return true
        case .archive:
            return !isInArchive
        case .spam:
            return !isInSpam
                && !isInSent
        }
    }
}
