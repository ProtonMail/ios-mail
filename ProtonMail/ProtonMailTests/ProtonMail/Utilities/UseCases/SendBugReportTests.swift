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

import ProtonCoreTestingToolkitUnitTestsServices
import XCTest

@testable import ProtonMail

final class SendBugReportTests: XCTestCase {
    private var apiService: APIServiceMock!
    private var internetConnectionStatusProvider: MockInternetConnectionStatusProviderProtocol!
    private var sut: SendBugReport!

    override func setUpWithError() throws {
        try super.setUpWithError()

        apiService = APIServiceMock()
        internetConnectionStatusProvider = .init()
        let bugReportService = BugReportService(api: apiService)
        sut = SendBugReport(
            bugReportService: bugReportService,
            internetConnectionStatusProvider: internetConnectionStatusProvider
        )

        apiService.uploadFilesJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success([:]))
        }
    }

    override func tearDownWithError() throws {
        sut = nil
        apiService = nil
        internetConnectionStatusProvider = nil

        try super.tearDownWithError()
    }

    func testIncludesAllRelevantDataInTheReport() async throws {
        internetConnectionStatusProvider.statusStub.fixture = .connectedViaWiFi

        let logFileURL = URL(filePath: "file:///path/to/log_file.txt")

        let params = SendBugReport.Params(
            reportBody: "foo",
            userName: "bar",
            emailAddress: "xyz@example.com",
            logFile: logFileURL
        )
        try await sut.execute(params: params)

        XCTAssertEqual(apiService.uploadFilesJSONStub.callCounter, 1)

        let expectedDescription = """
foo
Reachability: connectedViaWiFi
"""

        let uploadCall = try XCTUnwrap(apiService.uploadFilesJSONStub.lastArguments)
        let receivedPayload = try XCTUnwrap(uploadCall.a2 as? [String: AnyHashable])
        XCTAssertEqual(receivedPayload["OS"] as? String, "iOS - iPhone")
        XCTAssertNotNil(receivedPayload["OSVersion"] as? String)
        XCTAssertEqual(receivedPayload["Client"] as? String, "iOS_Native")
        XCTAssertEqual(receivedPayload["ClientVersion"] as? String, Bundle.main.appVersion)
        XCTAssertEqual(receivedPayload["ClientType"] as? String, "1")
        XCTAssertEqual(receivedPayload["Title"] as? String, "Proton Mail App bug report")
        XCTAssertEqual(receivedPayload["Description"] as? String, expectedDescription)
        XCTAssertEqual(receivedPayload["Username"] as? String, "bar")
        XCTAssertEqual(receivedPayload["Email"] as? String, "xyz@example.com")

        let receivedFiles = uploadCall.a3
        XCTAssertEqual(receivedFiles, ["log_file.txt": logFileURL])
    }
}
