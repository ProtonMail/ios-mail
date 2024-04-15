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
import ProtonCoreTestingToolkit
import XCTest

@testable import ProtonMail

final class UpsellOfferProviderTests: XCTestCase {
    private var sut: UpsellOfferProvider!
    private var apiService: APIServiceMock!
    private var user: UserManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        apiService = APIServiceMock()
        user = UserManager(api: apiService)
        sut = .init(dependencies: user.container)
    }

    override func tearDownWithError() throws {
        sut = nil
        apiService = nil
        user = nil

        try super.tearDownWithError()
    }

    func testUpdate_whenPlanMail2022IsAvailable_thenFetchesThatPlan() async throws {
        stubPlans(named: ["vpn2022", "mail2022", "mail2023"])

        try await withFeatureFlags([.dynamicPlans]) {
            try await sut.update()

            XCTAssertNotNil(sut.availablePlan)
        }
    }

    func testUpdate_whenPlanMail2022IsNotAvailable_thenDoesntFetchThatPlan() async throws {
        stubPlans(named: ["vpn2022", "mail2023"])

        try await withFeatureFlags([.dynamicPlans]) {
            try await sut.update()

            XCTAssertNil(sut.availablePlan)
        }
    }

    private func stubPlans(named names: [String]) {
        apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, completion in
            switch path {
            case "/payments/v5/status/apple":
                completion(nil, .success([:]))
            case "/payments/v5/plans":
                completion(nil, .success(AvailablePlansTestData.availablePlans(named: names)))
            default:
                fatalError("unexpected path: \(path)")
            }
        }
    }
}
