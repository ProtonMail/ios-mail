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

    @Test
    func userOpenedApp_NoSignIn_NoAction_ItCorrectlyUpdatesConvertionValue() async throws {
        await sut.handle(event: .appInstall)

        #expect(conversionTrackerSpy.capturedConversionValue.count == 1)
        let capturedConversionValue = try #require(conversionTrackerSpy.capturedConversionValue.last)

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
        await sut.handle(event: .appInstall)
        await sut.handle(event: .loggedIn)

        #expect(conversionTrackerSpy.capturedConversionValue.count == 2)
        let capturedConversionValue = try #require(conversionTrackerSpy.capturedConversionValue.last)

        #expect(
            capturedConversionValue
                == .init(
                    fineConversionValue: 1,
                    coarseConversionValue: .low,
                    lockPostback: false
                ))
    }

    @Test
    func userSignIn_PerformedFirstAction_SubscribedToUnlimitedYearlyPlan_ItCorrectlyUpdatesConvertionValue() async throws {
        await sut.handle(event: .appInstall)
        await sut.handle(event: .loggedIn)
        await sut.handle(event: .firstActionPerformed)
        await sut.handle(event: .subscribed(plan: .unlimited, duration: .year))

        #expect(conversionTrackerSpy.capturedConversionValue.count == 4)
        let capturedConversionValue = try #require(conversionTrackerSpy.capturedConversionValue.last)

        #expect(
            capturedConversionValue
                == .init(
                    fineConversionValue: 47,
                    coarseConversionValue: .high,
                    lockPostback: true
                ))
    }

    @Test
    func userSignIn_SubscribedToUnlimitedYearlyPlan_ItCorrectlyUpdatesConvertionValue() async throws {
        await sut.handle(event: .appInstall)
        await sut.handle(event: .loggedIn)
        await sut.handle(event: .subscribed(plan: .unlimited, duration: .year))

        #expect(conversionTrackerSpy.capturedConversionValue.count == 3)
        let capturedConversionValue = try #require(conversionTrackerSpy.capturedConversionValue.last)

        #expect(
            capturedConversionValue
                == .init(
                    fineConversionValue: 45,
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
