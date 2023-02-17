// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCore_UIFoundations
@testable import ProtonMail
import XCTest

final class ScheduledSendHelperTests: XCTestCase {
    private var fakeViewController: UIViewController!
    var delegateMock: MockScheduledSendHelperDelegate!
    var sut: ScheduledSendHelper!

    override func setUp() {
        super.setUp()

        fakeViewController = .init()
        delegateMock = .init()
        sut = .init(viewController: fakeViewController,
                    delegate: delegateMock,
                    originalScheduledTime: nil)
        fakeViewController.loadViewIfNeeded()
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
        delegateMock = nil
        fakeViewController = nil
    }

    func testPresentActionSheet_dateIsEarlierThan6am_havingInTheMorningItems() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let date = try XCTUnwrap(formatter.date(from: "2023-02-10 00:00"))

        sut.presentActionSheet(date: date)

        let actionSheet = try XCTUnwrap(
            fakeViewController.view.subviews.first(where: { $0 is PMActionSheet }) as? PMActionSheet
        )
        let itemGroup = try XCTUnwrap(actionSheet.itemGroups?.first)
        XCTAssertEqual(itemGroup.items.count, 3)

        let tomorrowDate = try XCTUnwrap(date.today(at: 8, minute: 0))
        let firstItem = try XCTUnwrap(itemGroup.items.first as? PMActionSheetPlainItem)
        XCTAssertEqual(firstItem.title, L11n.ScheduledSend.inTheMorning)
        XCTAssertEqual(firstItem.detail, tomorrowDate.localizedString(withTemplate: nil))

        let nextMondayDate = try XCTUnwrap(date.next(.monday, hour: 8, minute: 0))
        let secondItem = try XCTUnwrap(itemGroup.items[safe: 1] as? PMActionSheetPlainItem)
        XCTAssertEqual(secondItem.title,
                       nextMondayDate.formattedWith("EEEE").capitalized)
        XCTAssertEqual(secondItem.detail, nextMondayDate.localizedString(withTemplate: nil))

        let lastItem = try XCTUnwrap(itemGroup.items[safe: 2])
        XCTAssertEqual(lastItem.title, L11n.ScheduledSend.custom)
    }

    func testPresentActionSheet_dateIsLaterThan6am_havingTomorrowItems() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let date = try XCTUnwrap(formatter.date(from: "2023-02-10 06:01"))

        sut.presentActionSheet(date: date)

        let actionSheet = try XCTUnwrap(
            fakeViewController.view.subviews.first(where: { $0 is PMActionSheet }) as? PMActionSheet
        )
        let itemGroup = try XCTUnwrap(actionSheet.itemGroups?.first)
        XCTAssertEqual(itemGroup.items.count, 3)

        let tomorrowDate = try XCTUnwrap(date.tomorrow(at: 8, minute: 0))
        let firstItem = try XCTUnwrap(itemGroup.items.first as? PMActionSheetPlainItem)
        XCTAssertEqual(firstItem.title, L11n.ScheduledSend.tomorrow)
        XCTAssertEqual(firstItem.detail, tomorrowDate.localizedString(withTemplate: nil))

        let nextMondayDate = try XCTUnwrap(date.next(.monday, hour: 8, minute: 0))
        let secondItem = try XCTUnwrap(itemGroup.items[safe: 1] as? PMActionSheetPlainItem)
        XCTAssertEqual(secondItem.title,
                       nextMondayDate.formattedWith("EEEE").capitalized)
        XCTAssertEqual(secondItem.detail, nextMondayDate.localizedString(withTemplate: nil))

        let lastItem = try XCTUnwrap(itemGroup.items[safe: 2])
        XCTAssertEqual(lastItem.title, L11n.ScheduledSend.custom)
    }
}
