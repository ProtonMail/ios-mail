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

@testable import ProtonMail
import XCTest
import ViewInspector

class OnboardingScreenTests: BaseTestCase {

    private var sut: OnboardingScreen!
    private var dismissCallsCount: Int!

    override func setUp() {
        super.setUp()
        dismissCallsCount = 0
        sut = .init(onDismiss: { self.dismissCallsCount += 1 })
    }

    override func tearDown() {
        dismissCallsCount = nil
        sut = nil
        super.tearDown()
    }

    func testInInitialState_ItHas1stPageSelected() throws {
        XCTAssertEqual(sut.state.currentPageIndex, 0)
    }

    func test_WhenTapOnNextOnce_ItHas2ndPageSelected() throws {
        let expectation = sut.on(\.didAppear) { inspectView in
            try inspectView.simulateTapOnNext()

            let view = try inspectView.actualView()

            XCTAssertEqual(view.state.currentPageIndex, 1)
            XCTAssertEqual(self.dismissCallsCount, 0)
        }

        ViewHosting.host(view: sut)

        wait(for: [expectation], timeout: 0.1)
    }

    func test_WhenTapOnNextTwice_ItHas3rdPageSelected() throws {
        let expectation = sut.on(\.didAppear) { inspectView in
            try inspectView.simulateTapOnNext()
            try inspectView.simulateTapOnNext()

            let indexView = try inspectView.find(OnboardingDotsIndexView.self)
            try indexView.find(viewWithId: 2).callOnTapGesture()


            let view = try inspectView.actualView()

            XCTAssertEqual(view.state.currentPageIndex, 2)
            XCTAssertEqual(self.dismissCallsCount, 0)
        }

        ViewHosting.host(view: sut)

        wait(for: [expectation], timeout: 0.1)
    }

    func test_WhenTapOn2ndPageDot_ItHas2ndPageSelected() throws {
        let expectation = sut.on(\.didAppear) { inspectView in
            try inspectView.simulateTapGestureOnDot(index: 1)

            let view = try inspectView.actualView()

            XCTAssertEqual(view.state.currentPageIndex, 1)
            XCTAssertEqual(self.dismissCallsCount, 0)
        }

        ViewHosting.host(view: sut)

        wait(for: [expectation], timeout: 0.1)
    }

    func test_WhenTapOn3rdPageDot_ItHas3rdPageSelected() throws {
        let expectation = sut.on(\.didAppear) { inspectView in
            try inspectView.simulateTapGestureOnDot(index: 2)

            let view = try inspectView.actualView()

            XCTAssertEqual(view.state.currentPageIndex, 2)
            XCTAssertEqual(self.dismissCallsCount, 0)
        }

        ViewHosting.host(view: sut)

        wait(for: [expectation], timeout: 0.1)
    }

    func test_WhenTapOnStartTesting_ItDismissesSelf() throws {
        let expectation = sut.on(\.didAppear) { inspectView in
            try inspectView.simulateTapOnNext()
            try inspectView.simulateTapOnNext()
            try inspectView.simulateTapOnStartTesting()

            XCTAssertEqual(self.dismissCallsCount, 1)
        }

        ViewHosting.host(view: sut)

        wait(for: [expectation], timeout: 0.1)
    }

}

private extension InspectableView where View == ViewType.View<OnboardingScreen> {

    func simulateTapOnNext() throws {
        try find(button: "Next").tap()
    }

    func simulateTapOnStartTesting() throws {
        try find(button: "Start testing").tap()
    }

    func simulateTapGestureOnDot(index: Int) throws {
        let dotsIndexView = try find(OnboardingDotsIndexView.self)
        try dotsIndexView.find(viewWithId: index).callOnTapGesture()
    }

}
