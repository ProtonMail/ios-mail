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

import ProtonCoreTestingToolkitUnitTestsPayments
import ProtonCoreTestingToolkitUnitTestsServices
import ProtonMailUI
import XCTest

@testable import ProtonCorePayments
@testable @preconcurrency import ProtonMail

final class OnboardingUpsellCoordinatorTests: XCTestCase {
    private var sut: OnboardingUpsellCoordinator!
    private var user: UserManager!
    private var rootViewController: UIViewController!

    private let mockedAvailablePlans = AvailablePlans(
        plans: [
            .init(ID: nil, type: nil, name: "mail2022", title: "", instances: [], entitlements: [], decorations: [])
        ],
        defaultCycle: nil
    )

    override func setUp() async throws {
        try await super.setUp()

        let planService = PlansDataSourceMock()

        user = UserManager(api: APIServiceMock(), globalContainer: TestContainer())

        user.container.planServiceFactory.register {
            .right(planService)
        }

        rootViewController = await MainActor.run {
            let rootViewController = UIViewController()
            UIApplication.firstKeyWindow?.rootViewController = rootViewController
            return rootViewController
        }

        sut = await .init(dependencies: user.container, rootViewController: rootViewController)

        planService.availablePlansStub.fixture = mockedAvailablePlans
    }

    override func tearDown() {
        sut = nil
        user = nil
        rootViewController = nil

        super.tearDown()
    }

    @MainActor
    func testGivenPlansAreNotFetched_whenStarting_thenWillNotPresentUpsellPage() {
        sut.start {}

        XCTAssertNil(rootViewController.presentedViewController)
    }

    @MainActor
    func testGivenPlansAreFetched_whenStarting_thenWillPresentUpsellPage() async throws {
        try await user.container.upsellOfferProvider.update()

        sut.start {}

        try await Task.sleep(for: .milliseconds(100))

        let presentedViewController = try XCTUnwrap(rootViewController.presentedViewController)
        XCTAssertNotNil(presentedViewController as? SheetLikeSpotlightViewController<OnboardingUpsellPage>)
    }
}
