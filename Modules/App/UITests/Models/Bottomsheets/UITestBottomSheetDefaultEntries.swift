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

struct UITestBottomSheetDefaultEntries {

    struct MessageActions {
        static let defaultInboxList = [
            UITestBottomSheetDynamicEntry(section: 0, index: 0, text: "Mark as unread"),
            UITestBottomSheetDynamicEntry(section: 0, index: 1, text: "Star"),
            UITestBottomSheetDynamicEntry(section: 0, index: 2, text: "Label as…"),
            UITestBottomSheetDynamicEntry(section: 1, index: 0, text: "Move to trash"),
            UITestBottomSheetDynamicEntry(section: 1, index: 1, text: "Archive"),
            UITestBottomSheetDynamicEntry(section: 1, index: 2, text: "Move to spam"),
            UITestBottomSheetDynamicEntry(section: 1, index: 3, text: "Move to…"),
            UITestBottomSheetDynamicEntry(section: 2, index: 0, text: "View message in light mode"),
            UITestBottomSheetDynamicEntry(section: 2, index: 1, text: "Save as PDF"),
            UITestBottomSheetDynamicEntry(section: 2, index: 2, text: "Print"),
            UITestBottomSheetDynamicEntry(section: 2, index: 3, text: "View headers"),
            UITestBottomSheetDynamicEntry(section: 2, index: 4, text: "View HTML"),
            UITestBottomSheetDynamicEntry(section: 2, index: 5, text: "Report phishing"),
        ]

        static let defaultTrashList = [
            UITestBottomSheetDynamicEntry(section: 0, index: 0, text: "Mark as unread"),
            UITestBottomSheetDynamicEntry(section: 0, index: 1, text: "Star"),
            UITestBottomSheetDynamicEntry(section: 0, index: 2, text: "Label as…"),
            UITestBottomSheetDynamicEntry(section: 1, index: 0, text: "Delete permanently"),
            UITestBottomSheetDynamicEntry(section: 1, index: 1, text: "Move to inbox"),
            UITestBottomSheetDynamicEntry(section: 1, index: 2, text: "Move to spam"),
            UITestBottomSheetDynamicEntry(section: 1, index: 3, text: "Move to…"),
            UITestBottomSheetDynamicEntry(section: 2, index: 0, text: "View message in light mode"),
            UITestBottomSheetDynamicEntry(section: 2, index: 1, text: "Save as PDF"),
            UITestBottomSheetDynamicEntry(section: 2, index: 2, text: "Print"),
            UITestBottomSheetDynamicEntry(section: 2, index: 3, text: "View headers"),
            UITestBottomSheetDynamicEntry(section: 2, index: 4, text: "View HTML"),
            UITestBottomSheetDynamicEntry(section: 2, index: 5, text: "Report phishing"),
        ]

        static let defaultSpamList = [
            UITestBottomSheetDynamicEntry(section: 0, index: 0, text: "Mark as unread"),
            UITestBottomSheetDynamicEntry(section: 0, index: 1, text: "Star"),
            UITestBottomSheetDynamicEntry(section: 0, index: 2, text: "Label as…"),
            UITestBottomSheetDynamicEntry(section: 1, index: 0, text: "Not spam"),
            UITestBottomSheetDynamicEntry(section: 1, index: 1, text: "Move to trash"),
            UITestBottomSheetDynamicEntry(section: 1, index: 2, text: "Delete permanently"),
            UITestBottomSheetDynamicEntry(section: 1, index: 3, text: "Move to…"),
            UITestBottomSheetDynamicEntry(section: 2, index: 0, text: "View message in light mode"),
            UITestBottomSheetDynamicEntry(section: 2, index: 1, text: "Save as PDF"),
            UITestBottomSheetDynamicEntry(section: 2, index: 2, text: "Print"),
            UITestBottomSheetDynamicEntry(section: 2, index: 3, text: "View headers"),
            UITestBottomSheetDynamicEntry(section: 2, index: 4, text: "View HTML"),
            UITestBottomSheetDynamicEntry(section: 2, index: 5, text: "Report phishing"),
        ]

        static let defaultArchiveList = [
            UITestBottomSheetDynamicEntry(section: 0, index: 0, text: "Mark as unread"),
            UITestBottomSheetDynamicEntry(section: 0, index: 1, text: "Star"),
            UITestBottomSheetDynamicEntry(section: 0, index: 2, text: "Label as…"),
            UITestBottomSheetDynamicEntry(section: 1, index: 0, text: "Move to trash"),
            UITestBottomSheetDynamicEntry(section: 1, index: 1, text: "Move to inbox"),
            UITestBottomSheetDynamicEntry(section: 1, index: 2, text: "Move to spam"),
            UITestBottomSheetDynamicEntry(section: 1, index: 3, text: "Move to…"),
            UITestBottomSheetDynamicEntry(section: 2, index: 0, text: "View message in light mode"),
            UITestBottomSheetDynamicEntry(section: 2, index: 1, text: "Save as PDF"),
            UITestBottomSheetDynamicEntry(section: 2, index: 2, text: "Print"),
            UITestBottomSheetDynamicEntry(section: 2, index: 3, text: "View headers"),
            UITestBottomSheetDynamicEntry(section: 2, index: 4, text: "View HTML"),
            UITestBottomSheetDynamicEntry(section: 2, index: 5, text: "Report phishing"),
        ]

        static let defaultSenderActions = [
            UITestBottomSheetDynamicEntry(section: 0, index: 0, text: "Message"),
            UITestBottomSheetDynamicEntry(section: 0, index: 1, text: "Add to contacts"),
            UITestBottomSheetDynamicEntry(section: 1, index: 0, text: "Copy address"),
            UITestBottomSheetDynamicEntry(section: 1, index: 1, text: "Copy name"),
            UITestBottomSheetDynamicEntry(section: 2, index: 0, text: "Block this contact"),
        ]

        static let defaultRecipientActions = [
            UITestBottomSheetDynamicEntry(section: 0, index: 0, text: "Message"),
            UITestBottomSheetDynamicEntry(section: 0, index: 1, text: "Add to contacts"),
            UITestBottomSheetDynamicEntry(section: 1, index: 0, text: "Copy address"),
            UITestBottomSheetDynamicEntry(section: 1, index: 1, text: "Copy name"),
        ]
    }
}
