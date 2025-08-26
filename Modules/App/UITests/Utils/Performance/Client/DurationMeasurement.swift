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

public class DurationMeasurement: Measurement {

    private var startTime: TimeInterval = 0.0
    private var stopTime: TimeInterval = 0.0
    private var elapsedTime: TimeInterval {
        return stopTime - startTime
    }

    public init(startTime: TimeInterval = Date().timeIntervalSince1970, stopTime: TimeInterval = Date().timeIntervalSince1970) {
        self.startTime = startTime
        self.stopTime = stopTime
    }

    public func onStartMeasurement(measurementProfile: MeasurementProfile) {
        startTime = Date().timeIntervalSince1970
    }

    public func onStopMeasurement(measurementProfile: MeasurementProfile) {
        stopTime = Date().timeIntervalSince1970
        let durationString = String(format: "%.2f", elapsedTime)
        measurementProfile.addMetricToMeasures("duration", durationString)
    }
}
