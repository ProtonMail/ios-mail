//
//  MessageLocation.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
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

import Foundation

extension Message {
    
    enum HiddenLocation: String {
        case draft = "1" //1 can't be removed
        case sent  = "2" //2 can't be removed
        case outbox = "9"
    }
    
    /// Predefined location. matches with exclusive label id
    enum Location: String, CaseIterable {
        case inbox   = "0"
        case draft   = "8"  // "8"   //1 can't be removed
        case sent    = "7"  // "7"    //2 can't be removed
        case starred = "10"
        case archive = "6"
        case spam    = "4"
        case trash   = "3"
        case allmail = "5"
        case scheduled = "12"
        // 8 , 7  another type of draft,sent

        var localizedTitle: String {
            switch self {
            case .inbox:
                return LocalString._menu_inbox_title
            case .starred:
                return LocalString._menu_starred_title
            case .draft:
                return LocalString._menu_drafts_title
            case .sent:
                return LocalString._menu_sent_title
            case .trash:
                return LocalString._menu_trash_title
            case .archive:
                return LocalString._menu_archive_title
            case .spam:
                return LocalString._menu_spam_title
            case .allmail:
                return LocalString._menu_allmail_title
            case .scheduled:
                return LocalString._locations_scheduled_title
            }
        }

        var labelID: LabelID {
            return LabelID(rawValue)
        }

        init?(_ labelID: LabelID) {
            self.init(rawValue: labelID.rawValue)
        }
    }
}
