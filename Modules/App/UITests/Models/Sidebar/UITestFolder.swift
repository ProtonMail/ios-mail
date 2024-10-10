// Copyright (c) 2024 Proton Technologies AG
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

enum UITestFolder {
    case system(System)
    case custom(Custom)

    var value: String {
        switch self {
        case .system(let value):
            return value.rawValue
        case .custom(let value):
            return value.description
        }
    }

    enum System: String {
        case allDraft = "All Draft"
        case allMail = "All Mail"
        case allScheduled = "All Scheduled"
        case allSent = "All Sent"
        case archive = "Archive"
        case draft = "Draft"
        case inbox = "Inbox"
        case outbox = "Outbox"
        case sent = "Sent"
        case snoozed = "Snoozed"
        case spam = "Spam"
        case starred = "Starred"
        case trash = "Trash"
    }

    enum Custom: CustomStringConvertible {
        case ofValue(_ value: String)

        var description: String {
            switch self {
            case .ofValue(let value):
                return value
            }
        }
    }
}
