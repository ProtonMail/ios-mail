//
//  AdAttributionServiceTests.swift
//  InboxCore
//
//  Created by Maciej Gomółka on 03/02/2026.
//

import AdAttributionKit
import Foundation
import Testing

@testable import InboxCore

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

class ConversionTrackerSpy: ConversionTracker {
    private(set) var capturedConversionValue: [CapturedConversionValue] = []

    struct CapturedConversionValue: Equatable {
        let fineConversionValue: Int
        let coarseConversionValue: CoarseValue
        let lockPostback: Bool
    }

    // MARK: - ConversionTracker

    func updateConversionValue(
        _ fineConversionValue: Int,
        coarseConversionValue: CoarseValue,
        lockPostback: Bool
    ) async throws {
        capturedConversionValue.append(
            .init(
                fineConversionValue: fineConversionValue,
                coarseConversionValue: coarseConversionValue,
                lockPostback: lockPostback
            ))
    }
}
