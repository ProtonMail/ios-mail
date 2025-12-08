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

extension MailboxRobot {
    // MARK: Actions

    func scrollDown() {
        rootElement.swipeUp()
    }

    func scrollUp() {
        rootElement.swipeDown()
    }

    func tapEntryAt(index: Int) {
        let model = UITestMailboxListItemEntryModel(index: index)
        model.tap()
    }

    func longPressItemAt(index: Int) {
        let model = UITestMailboxListItemEntryModel(index: index)
        model.longPress()
    }

    func selectItemAt(index: Int) {
        let model = UITestMailboxListItemEntryModel(index: index)
        model.tapAvatar()
    }

    func selectItemsAt(indexes: [Int]) {
        indexes.forEach { index in
            selectItemAt(index: index)
        }
    }

    func unselectItemAt(index: Int) {
        let model = UITestMailboxListItemEntryModel(index: index)
        model.tapCheckedAvatar()
    }

    func unselectItemsAt(indexes: Int...) {
        indexes.forEach { index in
            unselectItemAt(index: index)
        }
    }

    func tapAttachmentCapsuleAt(forItem item: Int, atIndex index: Int) {
        let model = UITestMailboxListItemEntryModel(index: item)
        model.tapAttachmentCapsuleAt(index)
    }

    func waitForEntry(atIndex index: Int) {
        let model = UITestMailboxListItemEntryModel(index: index)
        model.waitForExistence(timeout: 30)
    }

    // MARK: Assertions

    func hasSelectedItemAt(index: Int) {
        let model = UITestMailboxListItemEntryModel(index: index)
        model.isItemSelected()
    }

    func hasSelectedItemsAt(indexes: [Int]) {
        indexes.forEach { index in
            hasSelectedItemAt(index: index)
        }
    }

    func hasUnselectedItemAt(index: Int) {
        let model = UITestMailboxListItemEntryModel(index: index)
        model.isItemUnselected()
    }

    func hasUnselectedItemsAt(indexes: [Int]) {
        indexes.forEach { index in
            hasUnselectedItemAt(index: index)
        }
    }

    func hasEntries(entries: UITestMailboxListItemEntry...) {
        entries.forEach { entry in
            hasEntry(entry: entry)
        }
    }
    func hasNoEntries() {
        let model = UITestMailboxListItemEntryModel(index: 0)
        model.doesNotExist()
    }

    func hasAttachmentPreviewEntries(index: Int, entries: UITestAttachmentPreviewItemEntry) {
        let model = UITestMailboxListItemEntryModel(index: index)
        model.hasAttachmentPreviews(entry: entries)
    }

    func hasNoAttachmentPreviewEntries(index: Int) {
        let model = UITestMailboxListItemEntryModel(index: index)
        model.hasNoAttachmentPreviews()
    }

    private func hasEntry(entry: UITestMailboxListItemEntry) {
        let model = UITestMailboxListItemEntryModel(index: entry.index)

        switch entry.avatar {
        case .initials(let value):
            model.hasInitials(value)
            model.hasNoAvatarImage()
        case .image:
            model.hasAvatarImage()
            model.hasNoInitials()
        }

        model.hasParticipants(entry.sender)
        model.hasSubject(entry.subject)
        model.hasDate(entry.date)

        if let count = entry.count {
            model.hasCount(count)
        } else {
            model.hasNoCount()
        }

        if let attachmentPreviews = entry.attachmentPreviews {
            model.hasAttachmentPreviews(entry: attachmentPreviews)
        } else {
            model.hasNoAttachmentPreviews()
        }
    }
}
