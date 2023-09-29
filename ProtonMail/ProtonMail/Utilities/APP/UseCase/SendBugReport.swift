// Copyright (c) 2023 Proton Technologies AG
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

import UIKit

final class SendBugReport {
    private let bugReportService: BugReportService
    private let internetConnectionStatusProvider: InternetConnectionStatusProviderProtocol

    init(
        bugReportService: BugReportService,
        internetConnectionStatusProvider: InternetConnectionStatusProviderProtocol
    ) {
        self.bugReportService = bugReportService
        self.internetConnectionStatusProvider = internetConnectionStatusProvider
    }

    func execute(params: Params) async throws {
        let extraDetails: [String] = [
            "Reachability: \(internetConnectionStatusProvider.status)"
        ]

        let description = [params.reportBody].appending(extraDetails).joined(separator: "\n")

        let deviceProperties = await obtainDeviceProperties()

        var bugReport = BugReport(
            os: "\(deviceProperties.systemName) - \(deviceProperties.model)",
            osVersion: deviceProperties.systemVersion,
            client: "iOS_Native",
            clientVersion: Bundle.main.appVersion,
            clientType: 1,
            title: "Proton Mail App bug report",
            description: description,
            username: params.userName,
            email: params.emailAddress,
            country: "", // VPN only
            ISP: "", // VPN only
            plan: ""
        )

        if let logFile = params.logFile {
            bugReport.files.append(logFile)
        }

        try await bugReportService.reportBug(bugReport: bugReport)
    }

    @MainActor
    private func obtainDeviceProperties() -> DeviceProperties {
        let device = UIDevice.current
        return DeviceProperties(model: device.model, systemName: device.systemName, systemVersion: device.systemVersion)
    }
}

extension SendBugReport {
    struct DeviceProperties {
        let model: String
        let systemName: String
        let systemVersion: String
    }

    struct Params {
        let reportBody: String
        let userName: String
        let emailAddress: String
        let logFile: URL?
    }
}
