// Copyright (c) 2024 Proton Technologies AG
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

// sourcery: mock
protocol TelemetryServiceProtocol {
    func sendEvent(_ event: TelemetryEvent) async
}

struct TelemetryService: TelemetryServiceProtocol {
    typealias Dependencies = AnyObject & HasAPIService & HasUserDefaults

    private let userID: UserID
    private let shouldBuildSendTelemetry: Bool
    private let isTelemetrySettingOn: () -> Bool
    private unowned let dependencies: Dependencies

    init(
        userID: UserID,
        shouldBuildSendTelemetry: Bool,
        isTelemetrySettingOn: @escaping () -> Bool,
        dependencies: Dependencies
    ) {
        self.userID = userID
        self.shouldBuildSendTelemetry = shouldBuildSendTelemetry
        self.isTelemetrySettingOn = isTelemetrySettingOn
        self.dependencies = dependencies
    }

    func sendEvent(_ event: TelemetryEvent) async {
        guard
            isTelemetrySettingOn(),
            frequencyAllowsSending(event: event)
        else { return }

        let request = TelemetryRequest(event: event)

        if shouldBuildSendTelemetry {
            do {
                _ = try await dependencies.apiService.perform(request: request)
                setEventSentAtIfNecessary(event)
            } catch {
                SystemLogger.log(error: error)
            }
        } else {
            SystemLogger.log(message: "Would send telemetry: \(event)")
        }
    }
}

extension TelemetryService {

    private func frequencyAllowsSending(event: TelemetryEvent) -> Bool {
        switch event.frequency {
        case .always:
            return true
        case .onceEvery24Hours:
            return frequencyOnceEvery24HoursAllowsSending(event: event)
        }
    }

    private func frequencyOnceEvery24HoursAllowsSending(event: TelemetryEvent) -> Bool {
        guard
            let eventSentAt = eventSentAt(event),
            let hoursPassed = Calendar.current.dateComponents([.hour], from: eventSentAt, to: Date()).hour
        else {
            return true
        }
        return hoursPassed > 24
    }

    private func eventSentAt(_ event: TelemetryEvent) -> Date? {
        let telemetryFrequency = dependencies.userDefaults[.telemetryFrequency]
        let userSentEvents = telemetryFrequency[userID.rawValue]
        guard let lastTimeStamp = userSentEvents?[event.type] else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(lastTimeStamp))
    }

    private func setEventSentAtIfNecessary(_ event: TelemetryEvent) {
        guard event.frequency != .always else { return }
        var telemetryFrequency = dependencies.userDefaults[.telemetryFrequency]
        let nowTimeStamp = Int(Date().timeIntervalSince1970)
        telemetryFrequency[userID.rawValue] = [event.type: nowTimeStamp]
        dependencies.userDefaults[.telemetryFrequency] = telemetryFrequency
    }
}

struct TelemetryEvent: Equatable {
    let measurementGroup: String
    let name: String
    let values: [String: Float]
    let dimensions: [String: String]
    let frequency: ReportFrequency

    /// Uniquely identifies the type of event
    var type: String {
        "\(measurementGroup)-\(name)"
    }
}

extension TelemetryEvent {

    enum ReportFrequency {
        /// all events are reported
        case always
        /// reports the event if no other event of the same type was reported in the previous 24 hours
        case onceEvery24Hours
    }
}
