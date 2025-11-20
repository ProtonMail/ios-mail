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

import XCTest
import proton_app_uniffi

@testable import InboxContacts

final class ContactsFilterStrategyTests: XCTestCase {

    func testFilter_ForEmptyStringSearchPhrase_ReturnsAllResults() {
        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    .contact(.vip)
                ]
            ),
            .init(
                groupedBy: "A",
                items: [
                    .contact(.aliceAdams),
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            ),
            .init(
                groupedBy: "E",
                items: [
                    .contact(.evanAndrage)
                ]
            ),
        ]

        XCTAssertEqual(ContactsFilterStrategy.filter(searchPhrase: "", items: groupedItems), groupedItems)
    }

    func testFilter_ForAndSearchPhrase_ReturnsOnlyMatchingResults() {
        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    .contact(.vip)
                ]
            ),
            .init(
                groupedBy: "A",
                items: [
                    .contact(.alexAbrams),
                    .contact(.aliceAdams),
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            ),
            .init(
                groupedBy: "E",
                items: [
                    .contact(.evanAndrage),
                    .contact(.elenaErickson),
                ]
            ),
        ]

        let expectedItems: [GroupedContacts] = [
            .init(
                groupedBy: "A",
                items: [
                    .contact(.alexAbrams),
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            ),
            .init(
                groupedBy: "E",
                items: [
                    .contact(.evanAndrage)
                ]
            ),
        ]

        XCTAssertEqual(ContactsFilterStrategy.filter(searchPhrase: "And", items: groupedItems), expectedItems)
    }

    func testFilter_ForAndrSearchPhrase_ReturnsOnlyMatchingResults() {
        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    .contact(.vip)
                ]
            ),
            .init(
                groupedBy: "A",
                items: [
                    .contact(.alexAbrams),
                    .contact(.aliceAdams),
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            ),
            .init(
                groupedBy: "E",
                items: [
                    .contact(.evanAndrage),
                    .contact(.elenaErickson),
                ]
            ),
        ]

        let expectedItems: [GroupedContacts] = [
            .init(
                groupedBy: "A",
                items: [
                    .contact(.alexAbrams),
                    .contact(.andrewAllen),
                ]
            ),
            .init(
                groupedBy: "E",
                items: [
                    .contact(.evanAndrage)
                ]
            ),
        ]

        XCTAssertEqual(ContactsFilterStrategy.filter(searchPhrase: "Andr", items: groupedItems), expectedItems)
    }

}
