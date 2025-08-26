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

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

public class MeasurementProfile: MeasurementProtocol {

    var workflow: String
    var measurements: [Measurement] = []
    var measuresList: [MeasureBlock] = []
    var serviceLevelIndicator: String?
    var sharedLabels: [String: String]
    var sharedMetadata: [String: String]

    public init(workflow: String) {
        self.workflow = workflow

        #if os(macOS)
            let platform = "macOS"
            let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
            let deviceModel = "Mac"
        #else
            let platform = "iOS"
            let systemVersion = UIDevice.current.systemVersion
            let deviceModel = UIDevice.current.model
        #endif

        self.sharedLabels = [
            "workflow": workflow,
            "product": MeasurementConfig.product,
            "platform": platform,
            "os_version": "\(platform) \(systemVersion)",
            "device_model": deviceModel,
            "sli": serviceLevelIndicator ?? "unknown",
            "environment": MeasurementConfig.environment,
        ]

        self.sharedMetadata = [
            "app_version": MeasurementConfig.version,
            "build_commit_sha1": MeasurementConfig.buildCommitShortSha,
            "ci_job_id": MeasurementConfig.ciJobId,
        ]
    }

    @discardableResult
    public func addMeasurement(_ measurement: Measurement) -> MeasurementProfile {
        measurements.append(measurement)
        return self
    }

    @discardableResult
    public func addTestName(_ testname: String) -> MeasurementProfile {
        sharedMetadata["test"] = transformTestName(testname)
        return self
    }

    private func transformTestName(_ name: String) -> String {
        let trimmedString = name.trimmingCharacters(in: CharacterSet(charactersIn: "-[]"))
        let components = trimmedString.split(separator: " ")
        return components.joined(separator: "_")
    }

    public func addMetricToMeasures(_ key: String, _ value: String) {
        measuresList.forEach { measure in
            measure.addMetric(key: key, value: value)
        }
    }

    @discardableResult
    public func addMetrics(data: [String: String]) -> MeasurementProfile {
        measuresList.forEach { measure in
            measure.addMetrics(data)
        }
        return self
    }

    @discardableResult
    public func setServiceLevelIndicator(_ sli: String) -> MeasurementProfile {
        self.serviceLevelIndicator = sli
        sharedLabels["sli"] = sli
        return self
    }

    public func measure(block: () -> Void) {
        sharedMetadata["id"] = UUID().uuidString
        let measureBlock = MeasureBlock(profile: self)

        measureBlock.startMeasurement()

        defer {
            measureBlock.stopMeasurement()
        }

        block()
    }

    func getProfileMetricsStreams() -> [[String: Any]] {
        return measuresList.compactMap { measure in
            return measure.getMeasureStream()
        }
    }
}
