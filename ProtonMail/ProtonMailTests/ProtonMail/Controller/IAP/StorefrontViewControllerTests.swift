//
//  StorefrontViewControllerTests.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail. If not, see <https://www.gnu.org/licenses/>.

@testable import ProtonMail
import ProtonCore_PaymentsUI
import XCTest

class StorefrontViewControllerTests: XCTestCase {

    var sut: StorefrontViewController!
    var paymentsUIMock: PaymentsUIMock!
    var sideMenuMock: SideMenuMock!
    var eventsServiceMock: EventsServiceMock!

    override func setUp() {
        super.setUp()

        paymentsUIMock = PaymentsUIMock()
        sideMenuMock = SideMenuMock()
        eventsServiceMock = EventsServiceMock()
        let coordinator = StorefrontCoordinator(
            paymentsUI: paymentsUIMock,
            sideMenu: sideMenuMock,
            eventsService: eventsServiceMock
        )
        sut = StorefrontViewController(
            coordinator: coordinator,
            paymentsUI: paymentsUIMock,
            eventsService: eventsServiceMock
        )
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
        paymentsUIMock = nil
        sideMenuMock = nil
    }

    func testViewSetUp() {
        sut.loadViewIfNeeded()

        XCTAssertNotNil(sut.navigationItem.leftBarButtonItem)
        XCTAssertEqual(sut.title, LocalString._general_subscription)
    }

    func testPresentSubscriptions() {
        sut.loadViewIfNeeded()

        XCTAssertEqual(paymentsUIMock.showCurrentPlan.callCounter, 1)
        let arguments = paymentsUIMock.showCurrentPlan.arguments(forCallCounter: 0)
        XCTAssertEqual(arguments?.a1, PaymentsUIPresentationType.none)
        XCTAssertEqual(arguments?.a2, true)

        let paymentsViewController = createPaymentsUIViewController()
        arguments?.a3(.open(vc: paymentsViewController, opened: false))

        XCTAssertEqual(sut.children.count, 1)
        XCTAssertTrue(sut.children.contains(paymentsViewController))
        XCTAssertTrue(sut.view.subviews.contains(sut.children.first?.view))
    }

    func testPlanBought() {
        sut.loadViewIfNeeded()

        let arguments = paymentsUIMock.showCurrentPlan.arguments(forCallCounter: 0)
        arguments?.a3(.purchasedPlan(accountPlan: .mailPlus))
        XCTAssertTrue(eventsServiceMock.callStub.wasCalledExactlyOnce)
    }

    func testTopMenuTapped() {
        sut.loadViewIfNeeded()

        sut.navigationItem.leftBarButtonItem?.simulateTap()

        XCTAssertEqual(sideMenuMock.revealMenu.callCounter, 1)
    }

}

private func createPaymentsUIViewController() -> PaymentsUIViewController {
    UIStoryboard(name: "PaymentsUI", bundle: PaymentsUI.bundle)
        .instantiateViewController(withIdentifier: "PaymentsUI") as! PaymentsUIViewController
}
