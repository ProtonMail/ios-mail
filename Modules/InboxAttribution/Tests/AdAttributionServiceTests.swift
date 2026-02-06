// Copyright (c) 2026 Proton Technologies AG
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

import AdAttributionKit
import Foundation
import Testing

@testable import InboxAttribution

@Suite(.serialized)
struct AdAttributionServiceTests {
    struct ConversionTestCase {
        let events: [ConversionEvent]
        let expectedFinalValue: ConversionTrackerSpy.CapturedConversionValue
    }

    var sut: AdAttributionService
    var conversionTrackerSpy: ConversionTrackerSpy
    var userDefaults: UserDefaults

    init() {
        userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        conversionTrackerSpy = .init()
        self.sut = AdAttributionService(
            conversionTracker: conversionTrackerSpy,
            userDefaults: userDefaults
        )
    }

    @Test(
        arguments: [
            ConversionTestCase(
                events: [.loggedIn],
                expectedFinalValue: .init(fineConversionValue: 1, coarseConversionValue: .low, lockPostback: false)
            ),
            ConversionTestCase(
                events: [.loggedIn, .firstActionPerformed],
                expectedFinalValue: .init(fineConversionValue: 3, coarseConversionValue: .medium, lockPostback: false)
            ),
            ConversionTestCase(
                events: [.loggedIn, .firstActionPerformed, .subscribed(plan: .unlimited, duration: .year)],
                expectedFinalValue: .init(fineConversionValue: 47, coarseConversionValue: .high, lockPostback: true)
            ),
            ConversionTestCase(
                events: [.loggedIn, .subscribed(plan: .unlimited, duration: .year)],
                expectedFinalValue: .init(fineConversionValue: 45, coarseConversionValue: .high, lockPostback: true)
            ),
        ]
    )
    func conversionEventsProduceCorrectValues(testCase: ConversionTestCase) async throws {
        for event in testCase.events {
            await sut.handle(event: event)
        }

        let capturedConversionValue = try #require(conversionTrackerSpy.capturedConversionValue.last)
        #expect(capturedConversionValue == testCase.expectedFinalValue)
    }
}
