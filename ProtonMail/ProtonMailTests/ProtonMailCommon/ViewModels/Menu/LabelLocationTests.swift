// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail

class LabelLocationTests: XCTestCase {

    func testInitWithIDString() {
        XCTAssertEqual(LabelLocation(id: "Provide feedback"), .provideFeedback)
        XCTAssertEqual(LabelLocation(id: "0"), .inbox)
        XCTAssertEqual(LabelLocation(id: "1"), .hiddenDraft)
        XCTAssertEqual(LabelLocation(id: "8"), .draft)
        XCTAssertEqual(LabelLocation(id: "2"), .hiddenSent)
        XCTAssertEqual(LabelLocation(id: "7"), .sent)
        XCTAssertEqual(LabelLocation(id: "10"), .starred)
        XCTAssertEqual(LabelLocation(id: "6"), .archive)
        XCTAssertEqual(LabelLocation(id: "4"), .spam)
        XCTAssertEqual(LabelLocation(id: "3"), .trash)
        XCTAssertEqual(LabelLocation(id: "5"), .allmail)

        XCTAssertEqual(LabelLocation(id: "Report a bug"), .bugs)
        XCTAssertEqual(LabelLocation(id: "Contacts"), .contacts)
        XCTAssertEqual(LabelLocation(id: "Settings"), .settings)
        XCTAssertEqual(LabelLocation(id: "Logout"), .signout)
        XCTAssertEqual(LabelLocation(id: "Lock The App"), .lockapp)
        XCTAssertEqual(LabelLocation(id: "Subscription"), .subscription)
        XCTAssertEqual(LabelLocation(id: "Add Label"), .addLabel)
        XCTAssertEqual(LabelLocation(id: "Add Folder"), .addFolder)
        XCTAssertEqual(LabelLocation(id: "Account Manager"), .accountManger)
        XCTAssertEqual(LabelLocation(id: "Add Account"), .addAccount)
        let randomID = String.randomString(10)
        XCTAssertEqual(LabelLocation(id: randomID), .customize(randomID))
    }

    func testInitWithLabelID() {
        XCTAssertEqual(LabelLocation(labelID: LabelID("0")), .inbox)
    }

    func testGetLabelID() {
        let allCases = LabelLocation.allCases
        allCases.forEach { location in
            XCTAssertEqual(location.labelID.rawValue, location.rawLabelID)
        }
    }

    func testGetLocalizedTitke() {
        XCTAssertEqual(LabelLocation.provideFeedback.localizedTitle, LocalString._provide_feedback)
        XCTAssertEqual(LabelLocation.inbox.localizedTitle, LocalString._menu_inbox_title)
        XCTAssertEqual(LabelLocation.hiddenDraft.localizedTitle, LocalString._menu_drafts_title)
        XCTAssertEqual(LabelLocation.draft.localizedTitle, LocalString._menu_drafts_title)
        XCTAssertEqual(LabelLocation.hiddenSent.localizedTitle, LocalString._menu_sent_title)
        XCTAssertEqual(LabelLocation.sent.localizedTitle, LocalString._menu_sent_title)
        XCTAssertEqual(LabelLocation.starred.localizedTitle, LocalString._menu_starred_title)
        XCTAssertEqual(LabelLocation.archive.localizedTitle, LocalString._menu_archive_title)
        XCTAssertEqual(LabelLocation.spam.localizedTitle, LocalString._menu_spam_title)
        XCTAssertEqual(LabelLocation.trash.localizedTitle, LocalString._menu_trash_title)
        XCTAssertEqual(LabelLocation.allmail.localizedTitle, LocalString._menu_allmail_title)

        XCTAssertEqual(LabelLocation.bugs.localizedTitle, LocalString._menu_bugs_title)
        XCTAssertEqual(LabelLocation.contacts.localizedTitle, LocalString._menu_contacts_title)
        XCTAssertEqual(LabelLocation.settings.localizedTitle, LocalString._menu_settings_title)
        XCTAssertEqual(LabelLocation.signout.localizedTitle, LocalString._menu_signout_title)
        XCTAssertEqual(LabelLocation.lockapp.localizedTitle, LocalString._menu_lockapp_title)
        XCTAssertEqual(LabelLocation.subscription.localizedTitle, LocalString._menu_service_plan_title)
        XCTAssertEqual(LabelLocation.addLabel.localizedTitle, LocalString._labels_add_label_action)
        XCTAssertEqual(LabelLocation.addFolder.localizedTitle, LocalString._labels_add_folder_action)
        XCTAssertEqual(LabelLocation.accountManger.localizedTitle, LocalString._menu_manage_accounts)
        XCTAssertEqual(LabelLocation.addAccount.localizedTitle, "")
        let randomID = String.randomString(100)
        XCTAssertEqual(LabelLocation.customize(randomID).localizedTitle, randomID)
    }

    func testGetIcon() {
        XCTAssertEqual(LabelLocation.provideFeedback.icon, Asset.menuFeedbackNew.image)
        XCTAssertEqual(LabelLocation.inbox.icon, Asset.menuInbox.image)
        XCTAssertEqual(LabelLocation.draft.icon, Asset.menuDraft.image)
        XCTAssertEqual(LabelLocation.sent.icon, Asset.menuSent.image)
        XCTAssertEqual(LabelLocation.starred.icon, Asset.menuStarred.image)
        XCTAssertEqual(LabelLocation.archive.icon, Asset.menuArchive.image)
        XCTAssertEqual(LabelLocation.spam.icon, Asset.menuSpam.image)
        XCTAssertEqual(LabelLocation.trash.icon, Asset.menuTrash.image)
        XCTAssertEqual(LabelLocation.allmail.icon, Asset.menuAllMail.image)
        XCTAssertEqual(LabelLocation.subscription.icon, Asset.menuServicePlan.image)
        XCTAssertEqual(LabelLocation.settings.icon, Asset.menuSettings.image)
        XCTAssertEqual(LabelLocation.contacts.icon, Asset.menuContacts.image)
        XCTAssertEqual(LabelLocation.bugs.icon, Asset.menuBugs.image)
        XCTAssertEqual(LabelLocation.lockapp.icon, Asset.menuLockApp.image)
        XCTAssertEqual(LabelLocation.signout.icon, Asset.menuLogout.image)
        XCTAssertEqual(LabelLocation.addLabel.icon, Asset.menuPlus.image)
        XCTAssertEqual(LabelLocation.addFolder.icon, Asset.menuPlus.image)

        XCTAssertNil(LabelLocation.customize("").icon)
    }

    func testGetMessageLocation() {
        XCTAssertEqual(LabelLocation.inbox.toMessageLocation, .inbox)
        XCTAssertEqual(LabelLocation.draft.toMessageLocation, .draft)
        XCTAssertEqual(LabelLocation.sent.toMessageLocation, .sent)
        XCTAssertEqual(LabelLocation.starred.toMessageLocation, .starred)
        XCTAssertEqual(LabelLocation.archive.toMessageLocation, .archive)
        XCTAssertEqual(LabelLocation.spam.toMessageLocation, .spam)
        XCTAssertEqual(LabelLocation.trash.toMessageLocation, .trash)
        XCTAssertEqual(LabelLocation.allmail.toMessageLocation, .allmail)

        let filter: [LabelLocation] = [.inbox,
                                       .draft,
                                       .sent,
                                       .starred,
                                       .archive,
                                       .spam,
                                       .trash,
                                       .allmail]
        let otherCases = LabelLocation.allCases.filter({ !filter.contains($0) })
        otherCases.forEach { location in
            XCTAssertEqual(location.toMessageLocation, .inbox)
        }

    }
}
