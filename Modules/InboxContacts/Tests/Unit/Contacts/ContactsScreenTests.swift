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

@testable import InboxContacts
import InboxCore
import InboxDesignSystem
import InboxTesting
import SwiftUI
import ViewInspector
import XCTest

class ContactsScreenTests: BaseTestCase {

    private var sut: ContactsScreen!
    private var dismissSpy: DismissSpy!

    override func setUp() {
        super.setUp()
        dismissSpy = .init()
        sut = .testInstance(search: .initial, items: [])
    }

    override func tearDown() {
        dismissSpy = nil
        sut = nil
        super.tearDown()
    }

    func testOnAppear_ItDoesNotDismissSelfYet() throws {
        arrange { inspectSUT in
            XCTAssertEqual(self.dismissSpy.callsCount, 0)
        }
    }

    func testOnAppear_WhenTapOnClose_ItDismissesSelf() throws {
        arrange { inspectSUT in
            try inspectSUT.simulateTapOnClose()

            XCTAssertEqual(self.dismissSpy.callsCount, 1)
        }
    }

    // MARK: - Private

    private func arrange(
        function: String = #function,
        file: StaticString = #file,
        line: UInt = #line,
        perform: @escaping (InspectableView<ViewType.View<ContactsScreen>>) throws -> Void
    ) {
        let expectation = sut.on(
            \.onLoad,
             function: function,
             file: file,
             line: line,
             perform: perform
        )

        ViewHosting.host(view: sut.environment(\.dismissTestable, dismissSpy))

        wait(for: [expectation], timeout: 0.1)
    }

}

private extension InspectableView where View == ViewType.View<ContactsScreen> {

    func simulateTapOnClose() throws {
        let toolbar = try XCTUnwrap(try find(ContactsControllerRepresentable.self).findToolbars().first)

        let closeButton = try toolbar.find(buttonWithImage: DS.Icon.icCross)

        try closeButton.tap()
    }

}
