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
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest

@testable import ProtonMail

final class PurchasePlanTests: XCTestCase {
    private var sut: PurchasePlan!
    private var user: UserManager!
    private var purchaseManager: MockPurchaseManager!

    private var plan: InAppPurchasePlan!

    override func setUpWithError() throws {
        try super.setUpWithError()

        purchaseManager = .init()

        user = UserManager(api: APIServiceMock())
        let userContainer = user.container

        userContainer.purchaseManagerFactory.register {
            self.purchaseManager
        }

        sut = .init(dependencies: userContainer)

        plan = try XCTUnwrap(InAppPurchasePlan(storeKitProductId: "iosmail_mail2022_12_usd_auto_renewing"))
    }

    override func tearDownWithError() throws {
        sut = nil
        user = nil
        purchaseManager = nil

        plan = nil

        try super.tearDownWithError()
    }

    func testForwardsSuccess() async {
        let output = await executeSUT(stubbedPurchaseResult: .purchasedPlan(accountPlan: plan))

        switch output {
        case .planPurchased:
            break
        default:
            XCTFail("Unexpected output: \(output)")
        }
    }

    func testForwardsCancellation() async {
        let purchaseResultsLeadingToCancellation: [PurchaseResult] = [.purchaseCancelled, .toppedUpCredits]

        for purchaseResult in purchaseResultsLeadingToCancellation {
            let output = await executeSUT(stubbedPurchaseResult: purchaseResult)

            switch output {
            case .cancelled:
                break
            default:
                XCTFail("Unexpected output: \(output)")
            }
        }
    }

    func testForwardsErrors() async {
        let stubbedError = StoreKitManagerErrors.transactionFailedByUnknownReason

        let purchaseResultsLeadingToFailure: [(PurchaseResult)] = [
            .purchaseError(error: stubbedError, processingPlan: plan),
            .apiMightBeBlocked(message: "", originalError: stubbedError, processingPlan: plan)
        ]

        for purchaseResult in purchaseResultsLeadingToFailure {
            let output = await executeSUT(stubbedPurchaseResult: purchaseResult)

            switch output {
            case .error(let error as StoreKitManagerErrors):
                XCTAssertEqual(error, stubbedError)
            default:
                XCTFail("Unexpected output: \(output)")
            }
        }
    }

    func testTreatsAnotherPurchaseInProgressAsError() async {
        let output = await executeSUT(stubbedPurchaseResult: .planPurchaseProcessingInProgress(processingPlan: plan))

        switch output {
        case .error(PurchasePlanError.purchaseAlreadyInProgress):
            break
        default:
            XCTFail("Unexpected output: \(output)")
        }
    }

    func testSkipsOverRenewalNotificationAndForwardsAnotherResult() async {
        let output = await executeSUT(
            stubbedPurchaseResults: [.renewalNotification, .purchasedPlan(accountPlan: plan)]
        )

        switch output {
        case .planPurchased:
            break
        default:
            XCTFail("Unexpected output: \(output)")
        }
    }

    private func executeSUT(stubbedPurchaseResult: PurchaseResult) async -> PurchasePlan.Output {
        await executeSUT(stubbedPurchaseResults: [stubbedPurchaseResult])
    }

    private func executeSUT(stubbedPurchaseResults: [PurchaseResult]) async -> PurchasePlan.Output {
        purchaseManager.buyPlanStub.bodyIs { _, _, _, _, completion in
            for stubbedPurchaseResult in stubbedPurchaseResults {
                completion(stubbedPurchaseResult)
            }
        }

        return await withFeatureFlags([.dynamicPlans]) {
            await sut.execute(storeKitProductId: "")
        }
    }
}
