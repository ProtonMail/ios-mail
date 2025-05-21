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

import XCTest

@available(iOS 15.0, *)
@available(macOS 12.0, *)
public class MeasurementContext: NSObject, XCTestObservation {
    public static let shared = MeasurementContext(MeasurementConfig.self)

    private var measurementProfiles: [String: MeasurementProfile] = [:]
    private var measurementConfig: MeasurementConfig.Type

    public init(_ measurementConfig: MeasurementConfig.Type) {
        self.measurementConfig = measurementConfig
        super.init()
        XCTestObservationCenter.shared.addTestObserver(self)
    }

    public func setWorkflow(_ workflow: String, forTest testName: String) -> MeasurementProfile {
        let profile = MeasurementProfile(workflow: workflow)
        measurementProfiles[testName] = profile
        return profile
    }

    public func addMetric(_ key: String, _ value: String, forTest testName: String) {
        guard let profile = measurementProfiles[testName] else { return }
        profile.addMetricToMeasures(key, value)
    }

    public func addMetadata(_ key: String, _ value: String, forTest testName: String) {
        guard let profile = measurementProfiles[testName] else { return }
        for measure in profile.measuresList {
            measure.addMetadata(key: key, value: value)
        }
    }

    public func addTestRunData(testName: String, status: String) {
        guard let profile = measurementProfiles[testName] else { return }
        for measure in profile.measuresList {
            measure.addTestNameMetadata(key: "test", value: testName)
        }
        profile.addMetricToMeasures("status", status)
    }

    public func pushToLoki() async throws {
        let payload: [String: Any] = ["streams": getProfilesStreams()]
        try await LokiClient().pushToLoki(entry: payload.jsonString(), lokiEndpoint: measurementConfig.lokiEndpoint!)
    }

    private func getProfilesStreams() -> [[String: Any]] {
        var streams: [[String: Any]] = []
        for (_, profile) in measurementProfiles {
            streams.append(contentsOf: profile.getProfileMetricsStreams())
        }
        return streams
    }

    private var allTestResults: [(testName: String, status: String)] = []

    public func testCaseDidFinish(_ testCase: XCTestCase) {
        guard let testRun = testCase.testRun else { return }
        let status = testRun.totalFailureCount == 0 ? "succeeded" : "failed"
        allTestResults.append((testName: testCase.name, status: status))
    }

    public func testBundleDidFinish(_ testBundle: Bundle) {
        for result in allTestResults {
            self.addTestRunData(testName: result.testName, status: result.status)
        }

        let expectation = XCTestExpectation(description: "Push metrics to Loki")

        Task {
            do {
                try await self.pushToLoki()
                expectation.fulfill()
            } catch {
                XCTFail("Failed to push metrics to Loki: \(error)")
            }
        }

        let result = XCTWaiter().wait(for: [expectation], timeout: 30.0)
        if result != .completed {
            XCTFail("Failed to push metrics to Loki within the timeout period")
        }
    }
}
