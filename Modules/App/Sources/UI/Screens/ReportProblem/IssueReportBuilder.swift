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

import proton_app_uniffi

struct IssueReportBuilder {
    struct FormInfo {
        let summary: String
        let stepsToReproduce: String
        let expectedResults: String
        let actualResults: String
        let includeLogs: Bool
    }

    private let infoDictionary: [String: Any]?
    private let deviceInfo: DeviceInfo

    init(infoDictionary: [String: Any]?, deviceInfo: DeviceInfo) {
        self.infoDictionary = infoDictionary
        self.deviceInfo = deviceInfo
    }

    func build(with formInfo: FormInfo) -> IssueReport {
        .init(
            operatingSystem: "\(deviceInfo.systemName) - \(deviceInfo.model)",
            operatingSystemVersion: deviceInfo.systemVersion,
            client: "iOS_Native",
            clientVersion: clientVersion,
            clientType: .email,
            title: "Proton Mail App bug report".notLocalized,
            summary: formInfo.summary,
            stepstToReproduce: formInfo.stepsToReproduce,
            expectedResult: formInfo.expectedResults,
            actualResult: formInfo.actualResults,
            logs: formInfo.includeLogs
        )
    }

    // MARK: - Private

    private var targetReleaseVersion = "7.0.0"

    private var clientVersion: String {
        "\(appVersion) (\(buildNumber))"
    }

    private var appVersion: String {
        [infoPlistAppVersion, targetReleaseVersion].max { infoPlistAppVersion, targetReleaseVersion in
            infoPlistAppVersion.compare(targetReleaseVersion, options: .numeric) == .orderedAscending
        } ?? "Unknown"
    }

    private var infoPlistAppVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}
