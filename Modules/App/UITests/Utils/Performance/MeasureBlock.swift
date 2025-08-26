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

import Foundation
import XCTest

public class MeasureBlock {
    internal let profile: MeasurementProfile
    private var labels: [String: Any] = [:]
    private var metrics: [String: Any] = [:]
    private var metadata: [String: Any] = [:]

    public init(profile: MeasurementProfile) {
        self.profile = profile
        self.labels = profile.sharedLabels
        self.metadata = profile.sharedMetadata
        self.labels["sli"] = profile.serviceLevelIndicator ?? "unknown"
    }

    internal func startMeasurement() {
        profile.measuresList.append(self)
        if self.labels["sli"] as! String == "unknown" {
            XCTFail(
                "MeasurementProfile: measure block for profile with workflow: \"\(profile.workflow)\" expected Service Level Indicator to be set via profile.setServiceLevelIndicator() but it wasn't. Current value is \"null\"."
            )
        }
        profile.measurements.forEach { $0.onStartMeasurement(measurementProfile: profile) }
    }

    @discardableResult
    internal func stopMeasurement() -> MeasureBlock {
        profile.measurements.forEach { $0.onStopMeasurement(measurementProfile: profile) }
        return self
    }

    public func getMeasureStream() -> [String: Any] {
        let timestamp = Int(Date().timeIntervalSince1970 * 1_000_000_000)  // Nanoseconds since epoch

        let values: [[Any]] = [
            [
                "\(timestamp)",
                metrics.jsonString(),
                metadata,
            ]
        ]

        return [
            "stream": profile.sharedLabels,
            "values": values,
        ]
    }

    internal func addLabel(key: String, value: String) {
        labels[key] = value
    }

    internal func addLabels(_ data: [String: String]) {
        labels.merge(data) { (_, new) in new }
    }

    public func addMetric(key: String, value: String) {
        validateMetricsSize {
            metrics[key] = value
        }
    }

    public func addMetrics(_ data: [String: String]) {
        validateMetricsSize {
            metrics.merge(data) { (_, new) in new }
        }
    }

    public func addMetadata(key: String, value: String) {
        metadata[key] = value
    }

    public func addTestNameMetadata(key: String, value: String) {
        metadata[key] = trimSpecialChars(value)
    }

    private func trimSpecialChars(_ name: String) -> String {
        let trimmedString = name.trimmingCharacters(in: CharacterSet(charactersIn: "-[]{}"))
        let components = trimmedString.split(separator: " ")
        return components.joined(separator: "_")
    }

    public func addMetadata(_ data: [String: String]) {
        metadata.merge(data) { (_, new) in new }
    }

    private func validateMetricsSize(_ block: () -> Void) {
        if metrics.count <= 10 {
            block()
        } else {
            fatalError("MeasureBlock: you have exceeded the maximum metrics size count. For performance reasons, it is not allowed to push more than 10 metrics.")
        }
    }
}

extension Dictionary {
    func jsonString() -> String {
        if let jsonData = try? JSONSerialization.data(withJSONObject: self, options: []) {
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        }
        return "{}"
    }
}
