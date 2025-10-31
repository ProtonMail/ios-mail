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

        #expect(sut.isLoading == false, "First boundary at 2.5s - should stop")
    }

    // MARK: - Stop during later cycles tests

    @Test
    func stopLoading_After1_5s_CompletesTwoCycles() {
        /// Scenario: 3.0s elapsed means we're 0.5s into the 2nd cycle
        /// Should complete the 2nd cycle before stopping
        let t0 = Date(timeIntervalSince1970: 1000)

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
        }

        /// Simulate first boundary arriving before stop
        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == true)

        /// Stop at 3.0s (0.5s into 2nd cycle)
        withCurrentDate(t0.adding(seconds: 3.0)) {
            sut.handle(action: .stopLoading)
        }
        #expect(sut.isLoading == true)

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == false, "Second boundary at 5.0s - should stop")
    }

    @Test
    func stopLoading_After3_5s_CompletesThreeCycles() {
        /// 6.0s = 2 complete cycles + 1.0s into 3rd cycle
        let t0 = Date(timeIntervalSince1970: 1000)

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
        }

        sut.handle(action: .cycleCompleted)
        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == true)

        /// Stop at 6.0s
        withCurrentDate(t0.adding(seconds: 6.0)) {
            sut.handle(action: .stopLoading)
        }
        #expect(sut.isLoading == true)

        sut.handle(action: .cycleCompleted)
        #expect(sut.isLoading == false, "Third boundary at 7.5s - should stop")
    }

    // MARK: - Tolerance tests

    @Test
    func stopLoading_VeryCloseToBoundary_AddsExtraCycle() {

        let t0 = Date(timeIntervalSince1970: 1000)

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
        }

        /// Stop at 4.97s = 0.03s before 2nd boundary (within tolerance of 0.05s)
        /// Tolerance only applies when elapsed >= 1 cycle (2.5s)
        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == true, "Should wait for an extra cycle (3 total instead of 2)")

        /// Stop at 4.97s (0.03s before 2nd boundary at 5.0s)
        /// elapsed=4.97, ceil(4.97/2.5)=2, toBoundary=0.03 < tolerance=0.05, elapsed >= 2.5
        /// So requiredCycles = 2 + 1 = 3
        withCurrentDate(t0.adding(seconds: 4.97)) {
            sut.handle(action: .stopLoading)
        }

        #expect(sut.isLoading == true)

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == true, "Second boundary at 5.0s - should NOT stop yet (tolerance adds extra cycle)")

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == false, "Third boundary at 7.5s - should stop")
    }

    @Test
    func stopLoading_JustOutsideTolerance_DoesNotAddExtraCycle() {
        let t0 = Date(timeIntervalSince1970: 1000)

        withCurrentDate(t0) {
            sut.handle(action: .startLoading)
        }

        /// Stop at 4.94s = 0.06s before 2nd boundary (outside tolerance of 0.05s)
        /// Should stop at 2nd boundary (2 total cycles)
        sut.handle(action: .cycleCompleted)
        #expect(sut.isLoading == true)

        /// Stop at 4.94s (0.06s before 2nd boundary at 5.0s)
        /// elapsed=4.94, ceil(4.94/2.5)=2, toBoundary=0.06 >= tolerance=0.05
        /// So requiredCycles = 2 (no extra cycle added)
        withCurrentDate(t0.adding(seconds: 4.94)) {
            sut.handle(action: .stopLoading)
        }

        #expect(sut.isLoading == true)

        sut.handle(action: .cycleCompleted)

        #expect(sut.isLoading == false, "Second boundary at 5.0s - should stop (outside tolerance)")
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
