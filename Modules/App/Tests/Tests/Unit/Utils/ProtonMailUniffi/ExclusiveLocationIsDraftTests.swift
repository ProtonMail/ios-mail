// Copyright (c) 2025 Proton Technologies AG
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

import proton_app_uniffi
@testable import ProtonMail
import XCTest

final class ExclusiveLocationIsDraftTests: XCTestCase {

    func testIsDraft_whenExclusiveLocationIsADraftSystemLabel_itReturnsTrue() {
        XCTAssertTrue(ExclusiveLocation.system(name: .drafts, id: .random()).isDraft)
        XCTAssertTrue(ExclusiveLocation.system(name: .allDrafts, id: .random()).isDraft)
    }

    func testIsDraft_whenExclusiveLocationIsASystemLabelButNotDraft_itReturnsFalse() {
        let nonDraftSystemLabel: [SystemLabel] = [
            .inbox,
            .allSent,
            .trash,
            .spam,
            .allMail,
            .archive,
            .sent,
            .outbox,
            .starred,
            .scheduled,
            .almostAllMail,
            .snoozed,
            .categorySocial,
            .categoryPromotions,
            .catergoryUpdates,
            .categoryForums,
            .categoryDefault,
        ]
        nonDraftSystemLabel.forEach {
            let sut = ExclusiveLocation.system(name: $0, id: .random())
            XCTAssertEqual(sut.isDraft, false, "isDraft failed for \(sut)")
        }
    }

    func testIsDraft_whenExclusiveLocationIsACustomFolder_itReturnsFalse() {
        XCTAssertFalse(ExclusiveLocation.custom(name: "my folder", id: .random(), color: .init(value: .empty)).isDraft)
    }

    func testIsDraft_whenExclusiveLocationIsNil_itReturnsFalse() {
        let sut: ExclusiveLocation? = nil
        XCTAssertFalse(sut.isDraft)
    }
}
