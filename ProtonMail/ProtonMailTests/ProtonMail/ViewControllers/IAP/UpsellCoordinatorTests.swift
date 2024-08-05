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

import ProtonCorePayments
import ProtonCorePaymentsUI
import ProtonCoreTestingToolkitUnitTestsServices
import ProtonMailUI
import XCTest

@testable import ProtonMail

final class UpsellCoordinatorTests: XCTestCase {
    private var sut: UpsellCoordinator!
    private var upsellOfferProvider: MockUpsellOfferProvider!
    private var user: UserManager!
    private var rootViewController: UIViewController!

    private let mockedAvailablePlan = AvailablePlans.AvailablePlan(
        ID: nil,
        type: nil,
        name: nil,
        title: "",
        instances: [],
        entitlements: [],
        decorations: []
    )

    private var entryPoint = UpsellPageEntryPoint.header

    override func setUp() async throws {
        try await super.setUp()

        upsellOfferProvider = .init()
        user = UserManager(api: APIServiceMock(), globalContainer: TestContainer())

        user.container.upsellOfferProviderFactory.register {
            self.upsellOfferProvider
        }

        rootViewController = await MainActor.run {
            let rootViewController = UIViewController()
            UIApplication.firstKeyWindow?.rootViewController = rootViewController
            return rootViewController
        }

        sut = await .init(dependencies: user.container, rootViewController: rootViewController)

        upsellOfferProvider.updateStub.bodyIs { _ in
            self.upsellOfferProvider.availablePlan = self.mockedAvailablePlan
        }
    }

    override func tearDown() {
        sut = nil
        upsellOfferProvider = nil
        user = nil
        rootViewController = nil

        super.tearDown()
    }

    func testGivenNoPlansAreReturnedByAPI_whenStarting_thenFallsBackToCorePaymentUI() async throws {
        upsellOfferProvider.updateStub.bodyIs { _ in }

        await sut.start(entryPoint: entryPoint)

        let topMostViewController = await UIApplication.firstKeyWindow?.topMostViewController
        XCTAssertNotNil(topMostViewController as? PaymentsUIViewController)
    }

    func testGivenThePlanIsNotYetFetched_whenStarting_thenFetchesThePlan() async {
        await sut.start(entryPoint: entryPoint)

        XCTAssertEqual(upsellOfferProvider.updateStub.callCounter, 1)
    }

    func testGivenThePlanIsAlreadyFetched_whenStarting_thenDoesNotRefetchThePlan() async {
        upsellOfferProvider.availablePlan = mockedAvailablePlan

        await sut.start(entryPoint: entryPoint)

        XCTAssertEqual(upsellOfferProvider.updateStub.callCounter, 0)
    }

    func testPresentsTheUpsellPage() async {
        await sut.start(entryPoint: entryPoint)

        let presentedViewController = await rootViewController.presentedViewController
        XCTAssertNotNil(presentedViewController as? SheetLikeSpotlightViewController<UpsellPage>)
    }

    @MainActor
    func testOnDismissCallback_inModernFlow() async {
        var onDismissCalled = false

        await sut.start(entryPoint: entryPoint) {
            onDismissCalled = true
        }

        let presentedViewController = rootViewController.presentedViewController
        await presentedViewController?.dismiss(animated: false)

        XCTAssert(onDismissCalled)
    }

    @MainActor
    func testOnDismissCallback_inLegacyFlow() async {
        upsellOfferProvider.updateStub.bodyIs { _ in }

        var onDismissCalled = false

        await sut.start(entryPoint: entryPoint) {
            onDismissCalled = true
        }

        let topMostViewController = UIApplication.firstKeyWindow?.topMostViewController
        await topMostViewController?.dismiss(animated: false)

        XCTAssert(onDismissCalled)
    }
}
