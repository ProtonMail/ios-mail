// Copyright (c) 2025 Proton Technologies AG
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

@testable import InboxCoreUI
import InboxCore
import Foundation
import Testing

@MainActor
class LoadingBarStateStoreTests {
    private let configuration = LoadingBarConfiguration()
    private lazy var sut = LoadingBarStateStore(configuration: configuration)

    // MARK: - Basic tests

    @Test
    func startLoading_SetsIsLoadingToTrue() {
        let t0 = Date(timeIntervalSince1970: 1000)

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
        }

        #expect(sut.isLoading == true)
    }

    @Test
    func stopLoading_WithoutStart_DoesNothing() {
        let t0 = Date(timeIntervalSince1970: 1000)

        withCurrentDate(t0) {
            sut.handle(action: .stopLoading)
        }

        #expect(sut.isLoading == false)
    }

    @Test
    func cycleBoundary_WithoutStart_DoesNothing() {
        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == false)
    }

    // MARK: - Immediate stop tests

    @Test
    func stopLoading_ExactlyOnBoundary_StopsImmediately() {
        let t0 = Date(timeIntervalSince1970: 1000)

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
        }

        withCurrentDate(t0.adding(seconds: configuration.cycleDuration)) {
            sut.handle(action: .stopLoading)
        }

        #expect(sut.isLoading == false)
    }

    @Test
    func stopLoading_AtStartTime_RequiresOneCycle() {
        let t0 = Date(timeIntervalSince1970: 1000)

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
            sut.handle(action: .stopLoading)
        }

        #expect(sut.isLoading == true, "Still loading, waiting for first cycle")

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == false, "After first cycle boundary - should stop")
    }

    // MARK: - Stop during first cycle tests

    @Test
    func stopLoading_After0_5s_CompletesFirstCycle() {
        let t0 = Date(timeIntervalSince1970: 1000)

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
        }

        withCurrentDate(t0.adding(seconds: 0.5)) {
            sut.handle(action: .stopLoading)
        }

        #expect(sut.isLoading == true, "Still loading, waiting for first cycle")

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == false, "First boundary - should stop")
    }

    // MARK: - Stop during later cycles tests

    @Test
    func stopLoading_After0_2CycleDurationOf2ndCycle_CompletesTwoCycles() {
        /// Scenario: Stop 0.2 * cycleDuration into the 2nd cycle
        /// Should complete the 2nd cycle before stopping
        let t0 = Date(timeIntervalSince1970: 1000)
        let cycle = configuration.cycleDuration

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
        }

        /// Simulate first boundary arriving before stop
        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == true)

        /// Stop 0.2 * cycle into 2nd cycle (e.g., 0.5s for 2.5s cycle)
        withCurrentDate(t0.adding(seconds: cycle + 0.2 * cycle)) {
            sut.handle(action: .stopLoading)
        }

        #expect(sut.isLoading == true)

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == false, "Second boundary - should stop")
    }

    @Test
    func stopLoading_After0_4CycleDurationOf3rdCycle_CompletesThreeCycles() {
        /// Stop 0.4 * cycleDuration into 3rd cycle (2 complete cycles + 0.4 into 3rd)
        let t0 = Date(timeIntervalSince1970: 1000)
        let cycle = configuration.cycleDuration

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
        }

        sut.handle(action: .cycleCompleted)
        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == true)

        /// Stop 0.4 * cycle into 3rd cycle
        withCurrentDate(t0.adding(seconds: 2 * cycle + 0.4 * cycle)) {
            sut.handle(action: .stopLoading)
        }

        #expect(sut.isLoading == true)

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == false, "Third boundary - should stop")
    }

    // MARK: - Tolerance tests

    @Test
    func stopLoading_VeryCloseToBoundary_AddsExtraCycle() {
        let t0 = Date(timeIntervalSince1970: 1000)
        let cycle = configuration.cycleDuration
        let tolerance = configuration.tolerance

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
        }

        /// Stop 0.03s before 2nd boundary (within tolerance of 0.05s)
        /// Tolerance only applies when elapsed >= 1 cycle
        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == true, "Should wait for an extra cycle (3 total instead of 2)")

        /// Stop just before 2nd boundary (within tolerance)
        /// toBoundary = 0.03 < tolerance = 0.05, so adds extra cycle
        /// requiredCycles = 2 + 1 = 3
        let stopTime = 2 * cycle - (tolerance - 0.02)  // 0.03s before boundary
        withCurrentDate(t0.adding(seconds: stopTime)) {
            sut.handle(action: .stopLoading)
        }

        #expect(sut.isLoading == true)

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == true, "Second boundary - should NOT stop yet (tolerance adds extra cycle)")

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == false, "Third boundary - should stop")
    }

    @Test
    func stopLoading_JustOutsideTolerance_DoesNotAddExtraCycle() {
        let t0 = Date(timeIntervalSince1970: 1000)
        let cycle = configuration.cycleDuration
        let tolerance = configuration.tolerance

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
        }

        /// Stop just outside tolerance before 2nd boundary
        /// Should stop at 2nd boundary (2 total cycles)
        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == true)

        /// Stop just outside tolerance (0.06s before boundary)
        /// toBoundary = 0.06 >= tolerance = 0.05, so NO extra cycle
        /// requiredCycles = 2
        let stopTime = 2 * cycle - (tolerance + 0.01)  // 0.06s before boundary
        withCurrentDate(t0.adding(seconds: stopTime)) {
            sut.handle(action: .stopLoading)
        }

        #expect(sut.isLoading == true)

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == false, "Second boundary - should stop (outside tolerance)")
    }

    // MARK: - Edge cases

    @Test
    func multipleCycleBoundaries_WithoutStop_KeepsLoading() {
        let t0 = Date(timeIntervalSince1970: 1000)

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
        }

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == true)

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == true)

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == true)
    }

    @Test
    func startLoading_AfterStop_ResetsState() {
        let t0 = Date(timeIntervalSince1970: 1000)

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
        }

        withCurrentDate(t0.adding(seconds: 0.5)) {
            sut.handle(action: .stopLoading)
        }

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == false)

        let t1 = t0.adding(seconds: 10)

        withCurrentDate(t1) {
            sut.handle(action: .startLoading)
        }

        #expect(sut.isLoading == true)

        /// Old boundaries shouldn't affect new session
        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == true)

        /// Stop new session
        withCurrentDate(t1.adding(seconds: 0.5)) {
            sut.handle(action: .stopLoading)
        }

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == false)
    }

    // MARK: - Edge Case: Late Boundaries

    @Test
    func cycleBoundary_ArrivesLateAfterStop_Ignores() {
        let t0 = Date(timeIntervalSince1970: 1000)

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
        }

        /// Stop before any boundary
        withCurrentDate(t0.adding(seconds: 0.3)) {
            sut.handle(action: .stopLoading)
        }

        #expect(sut.isLoading == true)

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == false, "Boundary arrives and completes the cycle")

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == false, "Late boundary arrives after already stopped - should be ignored")
    }

    @Test
    func cycleBoundary_RapidSequence_HandlesCorrectly() {
        let t0 = Date(timeIntervalSince1970: 1000)

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
        }

        /// First boundary
        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == true)

        /// Stop mid-second-cycle
        withCurrentDate(t0.adding(seconds: 1.8)) {
            sut.handle(action: .stopLoading)
        }

        #expect(sut.isLoading == true)

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == false, "Second boundary arrives - should stop")

        withCurrentDate(t0.adding(seconds: 10)) {
            sut.handle(action: .startLoading)
        }

        #expect(sut.isLoading == true, "Verify state is fully reset")
    }
}

@MainActor
private func withCurrentDate(_ date: Date, perform action: () -> Void) {
    DateEnvironment.$currentDate.withValue({ date }, operation: action)
}

private extension Date {
    func adding(seconds: TimeInterval) -> Date {
        addingTimeInterval(seconds)
    }
}
