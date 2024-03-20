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

/// The only purpose of this object is to track the strings already used in the app so we can find all when
/// translation setup is ready
enum LocalizationTemp {

    static let official = "Official"

    enum Mailbox {
        static let allDraft = "All Draft"
        static let allMail = "All Mail"
        static let allScheduled = "All Scheduled"
        static let allSent = "All Sent"
        static let archive = "Archive"
        static let draft = "Draft"
        static let inbox = "Inbox"
        static let outbox = "Outbox"
        static let sent = "Sent"
        static let snoozed = "Snoozed"
        static let spam = "Spam"
        static let starred = "Starred"
        static let trash = "Trash"
    }

    static let settings = "Settings"
}
