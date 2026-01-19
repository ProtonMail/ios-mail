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

import InboxSnapshotTesting
import InboxTesting
import SwiftUI
import Testing
import proton_app_uniffi

@testable import ProtonMail

@MainActor
final class TrackersInfoViewSnapshotTests {
    @Test
    func testTrackersInfoView_whenNoTrackers_itLayoutsCorrectOnIphoneX() throws {
        let trackersInfoView = TrackersInfoView(
            state: .init(
                trackers: .init(
                    blockedTrackers: [],
                    cleanedLinks: []
                )
            )
        )
        assertSnapshotsOnIPhoneX(of: trackersInfoView)
    }

    @Test
    func testTrackersInfoView_onlyLinks_itLayoutsCorrectOnIphoneX() throws {
        let trackersInfoView = TrackersInfoView(
            state: .init(
                trackers: .init(
                    blockedTrackers: [],
                    cleanedLinks: dummyLinks
                )
            )
        )
        assertSnapshotsOnIPhoneX(of: trackersInfoView)
    }

    @Test
    func testTrackersInfoView_whenTrackersAndLinksAreCollapsed_itLayoutsCorrectOnIphoneX() throws {
        let trackersInfoView = TrackersInfoView(
            state: .init(
                trackers: .init(
                    blockedTrackers: dummyTrackers,
                    cleanedLinks: dummyLinks
                )
            )
        )
        assertSnapshotsOnIPhoneX(of: trackersInfoView)
    }

    @Test
    func testTrackersInfoView_whenTrackersAndLinksAreExpanded_itLayoutsCorrectOnIphoneX() throws {
        let trackersInfoView = TrackersInfoView(
            state: .init(
                trackers: .init(
                    blockedTrackers: dummyTrackers,
                    cleanedLinks: dummyLinks
                ),
                isTrackersSectionExpanded: true,
                isLinksSectionExpanded: true
            )
        )
        assertSnapshotsOnIPhoneX(of: trackersInfoView)
    }
}

private extension TrackersInfoViewSnapshotTests {
    var dummyTrackers: [TrackerDomain] {
        [
            .init(
                name: "amazon.com",
                urls: [
                    "https://www.amazon.com/dp/B00TEST123?ref_=nav_signin&psc=1&smid=ATVPDKIKX0DER&tag=testtag-20&ascsubtag=tracking123&th=1&customParam=abc",
                    "https://www.amazon.com/s?k=usb+c+cable&ref=nb_sb_noss&crid=TEST123456&sprefix=usb%2Caps%2C200&qid=9999999999&tag=test&field-brandtextbin=Anker",
                ]),
            .init(
                name: "tiktok.com",
                urls: [
                    "https://www.tiktok.com/@fakeuser/video/999"
                ]),
        ]
    }

    var dummyLinks: [CleanedLink] {
        [
            .init(
                original: "https://www.facebook.com/fake.user.123?ref=bookmarks&sk=timeline&__tn__=%2CdC-R&eid=TEST123456&notif_id=9999999999&notif_t=close_friend_activity&testParam=hello",
                cleaned: "https://www.facebook.com/fake.user.123"
            )
        ]
    }
}
