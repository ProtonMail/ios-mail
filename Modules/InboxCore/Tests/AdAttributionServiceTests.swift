//
//  AdAttributionServiceTests.swift
//  InboxCore
//
//  Created by Maciej Gomółka on 03/02/2026.
//

import AdAttributionKit
import Testing

@testable import InboxCore

struct AdAttributionServiceTests {
    var sut: AdAttributionService
    var conversionTrackerSpy: ConversionTrackerSpy

    init() {
        conversionTrackerSpy = .init()
        self.sut = AdAttributionService(conversionTracker: conversionTrackerSpy)
    }

    @Test
    func userOpenedApp_NoSignIn_NoAction_ItCorrectlyUpdatesConvertionValue() async throws {
        await sut.handle(event: .appInstall)

        #expect(conversionTrackerSpy.capturedConversionValue.count == 1)
        let capturedConversionValue = try #require(conversionTrackerSpy.capturedConversionValue.first)

        #expect(
            capturedConversionValue
                == .init(
                    fineConversionValue: 0,
                    coarseConversionValue: .low,
                    lockPostback: false
                ))
    }

    @Test
    func userSignedIn_NoFirstActionYet_ItCorrectlyUpdatesConvertionValue() async throws {
        await sut.handle(event: .loggedIn)

        #expect(conversionTrackerSpy.capturedConversionValue.count == 1)
        let capturedConversionValue = try #require(conversionTrackerSpy.capturedConversionValue.first)

        #expect(
            capturedConversionValue
                == .init(
                    fineConversionValue: 1,
                    coarseConversionValue: .low,
                    lockPostback: false
                ))
    }

    @Test
    func userSignIn_PerformedFirstAction_BoughtUnlimitedPlanFor12Months_ItCorrectlyUpdatesConvertionValue() async throws {
        await sut.handle(event: .subscribed(plan: .unlimited, duration: .year))

        #expect(conversionTrackerSpy.capturedConversionValue.count == 1)
        let capturedConversionValue = try #require(conversionTrackerSpy.capturedConversionValue.first)

        #expect(
            capturedConversionValue
                == .init(
                    fineConversionValue: 47,
                    coarseConversionValue: .high,
                    lockPostback: true
                ))
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
