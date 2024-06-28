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

extension SidebarMenuRobot {
    func openInbox() {
        tapEntry(withLabel: UITestFolder.system(.inbox).value)
    }

    func openArchive() {
        tapEntry(withLabel: UITestFolder.system(.archive).value)
    }

    func openSubscription() {
        tapEntry(withLabel: UITestSidebarEntry.subscription.rawValue)
    }
    
    func openSent() {
        tapEntry(withLabel: UITestFolder.system(.sent).value)
    }

    func tapEntry(withLabel label: String) {
        let model = UITestSidebarListItemEntryModel(label: label)
        model.tap()
    }

    func hasEntries(_ entries: UITestSidebarListItemEntry...) {
        entries.forEach { entry in
            hasEntry(entry)
        }
    }

    private func hasEntry(_ entry: UITestSidebarListItemEntry) {
        let model = UITestSidebarListItemEntryModel(label: entry.text)
        model.isIconDisplayed()
        model.isTextMatching(value: entry.text)

        if let badge = entry.badge {
            model.isBadgeShown(value: badge)
        }
        else {
            model.isBadgeNotShown()
        }
    }
}
