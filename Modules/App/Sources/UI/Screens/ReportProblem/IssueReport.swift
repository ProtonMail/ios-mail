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

// FIXME: - To remove when Rust SDK API is available

import proton_app_uniffi
import Foundation

struct IssueReport: Equatable {
    let operatingSystem: String
    let operatingSystemVersion: String
    let client: String
    let clientVersion: String
    let clientType: ClientType
    let title: String
    let summary: String
    let stepsToReproduce: String
    let expectedResult: String
    let actualResult: String
    let includeLogs: Bool
}

enum ClientType: Int {
    case email = 1;
}

protocol ReportProblemService: Sendable {
    func send(report: IssueReport) async throws (ActionError)
}

final class ReportProblemServiceImplementation: ReportProblemService {

    func send(report: IssueReport) async throws (ActionError) {
        try! await Task.sleep(for: .seconds(5))
    }

}
