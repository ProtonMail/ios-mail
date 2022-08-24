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

import XCTest
@testable import ProtonMail

class LabelLocationTests: XCTestCase {

    func testInitWithIDString() {
        XCTAssertEqual(LabelLocation(id: "Provide feedback", name: nil), .provideFeedback)
        XCTAssertEqual(LabelLocation(id: "0", name: nil), .inbox)
        XCTAssertEqual(LabelLocation(id: "1", name: nil), .hiddenDraft)
        XCTAssertEqual(LabelLocation(id: "8", name: nil), .draft)
        XCTAssertEqual(LabelLocation(id: "2", name: nil), .hiddenSent)
        XCTAssertEqual(LabelLocation(id: "7", name: nil), .sent)
        XCTAssertEqual(LabelLocation(id: "10", name: nil), .starred)
        XCTAssertEqual(LabelLocation(id: "6", name: nil), .archive)
        XCTAssertEqual(LabelLocation(id: "4", name: nil), .spam)
        XCTAssertEqual(LabelLocation(id: "3", name: nil), .trash)
        XCTAssertEqual(LabelLocation(id: "5", name: nil), .allmail)

        XCTAssertEqual(LabelLocation(id: "Report a bug", name: nil), .bugs)
        XCTAssertEqual(LabelLocation(id: "Contacts", name: nil), .contacts)
        XCTAssertEqual(LabelLocation(id: "Settings", name: nil), .settings)
        XCTAssertEqual(LabelLocation(id: "Logout", name: nil), .signout)
        XCTAssertEqual(LabelLocation(id: "Lock The App", name: nil), .lockapp)
        XCTAssertEqual(LabelLocation(id: "Subscription", name: nil), .subscription)
        XCTAssertEqual(LabelLocation(id: "Add Label", name: nil), .addLabel)
        XCTAssertEqual(LabelLocation(id: "Add Folder", name: nil), .addFolder)
        XCTAssertEqual(LabelLocation(id: "Account Manager", name: nil), .accountManger)
        XCTAssertEqual(LabelLocation(id: "Add Account", name: nil), .addAccount)
        let randomID = String.randomString(10)
        XCTAssertEqual(LabelLocation(id: randomID, name: nil), .customize(randomID, nil))
    }

    func testInitWithLabelID() {
        XCTAssertEqual(LabelLocation(labelID: LabelID("0"), name: nil), .inbox)
    }

    func testGetLabelID() {
        let allCases = LabelLocation.allCases
        allCases.forEach { location in
            XCTAssertEqual(location.labelID.rawValue, location.rawLabelID)
        }
    }

    func testGetLocalizedTitle() {
        XCTAssertEqual(LabelLocation.provideFeedback.localizedTitle, LocalString._provide_feedback)
        XCTAssertEqual(LabelLocation.inbox.localizedTitle, LocalString._menu_inbox_title)
        XCTAssertEqual(LabelLocation.hiddenDraft.localizedTitle, "")
        XCTAssertEqual(LabelLocation.draft.localizedTitle, LocalString._menu_drafts_title)
        XCTAssertEqual(LabelLocation.hiddenSent.localizedTitle, "")
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
        let randomName = String.randomString(100)
        XCTAssertEqual(LabelLocation.customize("", randomName).localizedTitle, randomName)
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
        XCTAssertEqual(LabelLocation.hiddenDraft.toMessageLocation, .draft)
        XCTAssertEqual(LabelLocation.hiddenSent.toMessageLocation, .sent)

        let filter: [LabelLocation] = [
            .inbox,
            .draft,
            .sent,
            .starred,
            .archive,
            .spam,
            .trash,
            .allmail,
            .hiddenSent,
            .hiddenDraft
        ]
        let otherCases = LabelLocation.allCases.filter({ !filter.contains($0) })
        otherCases.forEach { location in
            XCTAssertEqual(location.toMessageLocation, .inbox)
        }

    }
}
