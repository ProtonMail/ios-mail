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
import InboxTesting
import ViewInspector
import XCTest

@MainActor
class OnboardingScreenTests: BaseTestCase {

    private var sut: OnboardingScreen!
    private var dismissSpy: DismissSpy!

    override func setUp() async throws {
        try await super.setUp()
        dismissSpy = .init()
        sut = OnboardingScreen()
    }

    override func tearDown() async throws {
        dismissSpy = nil
        sut = nil
        try await super.tearDown()
    }

    func testOnAppear_ItHas1stPageSelected() throws {
        arrange { inspectSUT in
            let sut = try inspectSUT.actualView()

            XCTAssertEqual(sut.state.selectedPageIndex, 0)
            XCTAssertEqual(self.dismissSpy.callsCount, 0)
        }
    }

    func test_WhenTapOnNextOnce_ItHas2ndPageSelected() throws {
        arrange { inspectSUT in
            try inspectSUT.simulateTapOnNext()

            let sut = try inspectSUT.actualView()

            XCTAssertEqual(sut.state.selectedPageIndex, 1)
            XCTAssertEqual(self.dismissSpy.callsCount, 0)
        }
    }

    func test_WhenTapOnNextTwice_ItHas3rdPageSelected() throws {
        arrange { inspectSUT in
            try inspectSUT.simulateTapOnNext()
            try inspectSUT.simulateTapOnNext()

            let sut = try inspectSUT.actualView()

            XCTAssertEqual(sut.state.selectedPageIndex, 2)
            XCTAssertEqual(self.dismissSpy.callsCount, 0)
        }
    }

    func test_WhenTapOn2ndPageDot_ItHas2ndPageSelected() throws {
        arrange { inspectSUT in
            try inspectSUT.simulateTapGestureOnDot(atIndex: 1)

            let sut = try inspectSUT.actualView()

            XCTAssertEqual(sut.state.selectedPageIndex, 1)
            XCTAssertEqual(self.dismissSpy.callsCount, 0)
        }
    }

    func test_WhenTapOn3rdPageDot_ItHas3rdPageSelected() throws {
        arrange { inspectSUT in
            try inspectSUT.simulateTapGestureOnDot(atIndex: 2)

            let sut = try inspectSUT.actualView()

            XCTAssertEqual(sut.state.selectedPageIndex, 2)
            XCTAssertEqual(self.dismissSpy.callsCount, 0)
        }
    }

    func test_WhenTapOn3rdAnd1stPageDot_ItHas1stPageSelected() throws {
        arrange { inspectSUT in
            try inspectSUT.simulateTapGestureOnDot(atIndex: 2)
            try inspectSUT.simulateTapGestureOnDot(atIndex: 0)

            let sut = try inspectSUT.actualView()

            XCTAssertEqual(sut.state.selectedPageIndex, 0)
            XCTAssertEqual(self.dismissSpy.callsCount, 0)
        }
    }

    func test_WhenTapOnStartTesting_ItDismissesSelf() throws {
        arrange { inspectSUT in
            try inspectSUT.simulateTapOnNext()
            try inspectSUT.simulateTapOnNext()

            XCTAssertEqual(self.dismissSpy.callsCount, 0)

            try inspectSUT.simulateTapOnStartTesting()

            XCTAssertEqual(self.dismissSpy.callsCount, 1)
        }
    }

    private func arrange(
        function: String = #function,
        file: StaticString = #file,
        line: UInt = #line,
        perform: @escaping (InspectableView<ViewType.View<OnboardingScreen>>) throws -> Void
    ) {
        let expectation = sut.on(
            \.didAppear,
            function: function,
            file: file,
            line: line,
            perform: perform
        )

        ViewHosting.host(view: sut.environment(\.dismissTestable, dismissSpy))

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

    func simulateTapGestureOnDot(atIndex index: Int) throws {
        let dotsIndexView = try find(OnboardingDotsIndexView.self)
        try dotsIndexView.find(viewWithId: index).callOnTapGesture()
    }

}
