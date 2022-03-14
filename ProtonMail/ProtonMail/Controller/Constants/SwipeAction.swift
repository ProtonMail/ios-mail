//
//  SwipeAction.swift
//  ProtonMail - Created on 12/6/18.
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

import ProtonCore_UIFoundations

enum SwipeActionSettingType: Int, CustomStringConvertible {
    case none
    case trash
    case spam
    case starAndUnstar
    case archive
    case readAndUnread
    case labelAs
    case moveTo

    var description: String {
        switch self {
        case .trash:
            return LocalString._locations_trash_desc
        case .spam:
            return LocalString._move_to_spam
        case .starAndUnstar:
            return LocalString._star_unstar
        case .archive:
            return LocalString._move_to_archive
        case .readAndUnread:
            return LocalString._mark_as_unread_read
        case .none:
            return LocalString._none
        case .labelAs:
            return LocalString._label_as_
        case .moveTo:
            return LocalString._move_to_
        }
    }

    var selectionTitle: String {
        switch self {
        case .none:
            return LocalString._setting_swipe_action_none_selection_title
        default:
            return description
        }
    }

    var actionDisplayTitle: String {
        switch self {
        case .none:
            return LocalString._setting_swipe_action_none_display_title
        case .readAndUnread:
            return LocalString._swipe_action_unread
        case .starAndUnstar:
            return LocalString._swipe_action_star
        case .archive:
            return LocalString._swipe_action_archive
        case .spam:
            return LocalString._swipe_action_spam
        default:
            return description
        }
    }

    var actionDisplayIcon: UIImage {
        switch self {
        case .starAndUnstar:
            return Asset.swipeStar.image
        default:
            return icon
        }
    }

    var icon: UIImage {
        switch self {
        case .none:
            return Asset.swipeNone.image
        case .starAndUnstar:
            return Asset.swipeUnstar.image
        case .readAndUnread:
            return Asset.swipeUnread.image
        case .trash:
            return Asset.swipeTrash.image
        case .labelAs:
            return Asset.swipeLabelAs.image
        case .moveTo:
            return Asset.swipeMoveTo.image
        case .archive:
            return Asset.swipeArchive.image
        case .spam:
            return Asset.swipeSpam.image
        }
    }

    var actionColor: UIColor {
        switch self {
        case .none, .labelAs, .moveTo, .archive, .spam:
            return ColorProvider.IconHint
        case .readAndUnread:
            return ColorProvider.InteractionNorm
        case .starAndUnstar:
            return ColorProvider.NotificationWarning
        case .trash:
            return ColorProvider.NotificationError
        }
    }

    static func migrateFromV3(rawValue: Int) -> SwipeActionSettingType? {
        switch rawValue {
        case 0:
            return .trash
        case 1:
            return .spam
        case 2:
            return .starAndUnstar
        case 3:
            return .archive
        case 4:
            return .readAndUnread
        default:
            return nil
        }
    }
}

enum MessageSwipeAction: CustomStringConvertible {
    case none
    case unread
    case read
    case star
    case unstar
    case trash
    case labelAs
    case moveTo
    case archive
    case spam

    var description: String {
        switch self {
        case .none:
            return LocalString._swipe_action_unread
        case .unread:
            return LocalString._swipe_action_unread
        case .read:
            return LocalString._swipe_action_read
        case .star:
            return LocalString._swipe_action_star
        case .unstar:
            return LocalString._swipe_action_unstar
        case .trash:
            return LocalString._locations_trash_desc
        case .labelAs:
            return LocalString._label_as_
        case .moveTo:
            return LocalString._move_to_
        case .archive:
            return LocalString._swipe_action_archive
        case .spam:
            return LocalString._swipe_action_spam
        }
    }

    var actionColor: UIColor {
        switch self {
        case .none, .unstar, .labelAs, .moveTo, .archive, .spam:
            return ColorProvider.IconHint
        case .unread, .read:
            return ColorProvider.InteractionNorm
        case .star:
            return ColorProvider.NotificationWarning
        case .trash:
            return ColorProvider.NotificationError
        }
    }

    var icon: UIImage {
        switch self {
        case .none:
            return Asset.swipeNone.image
        case .unread:
            return Asset.swipeUnread.image
        case .read:
            return Asset.swipeRead.image
        case .star:
            return Asset.swipeStar.image
        case .unstar:
            return Asset.swipeUnstar.image
        case .trash:
            return Asset.swipeTrash.image
        case .labelAs:
            return Asset.swipeLabelAs.image
        case .moveTo:
            return Asset.swipeMoveTo.image
        case .archive:
            return Asset.swipeArchive.image
        case .spam:
            return Asset.swipeSpam.image
        }
    }
}
