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

@testable import ProtonMail
import XCTest
import ProtonCoreTestingToolkitUnitTestsServices

final class PrivacyAndDataSettingViewModelTests: XCTestCase {

    private var testContainer: TestContainer!
    var sut: PrivacyAndDataSettingViewModel!
    var user: UserManager!
    var api: APIServiceMock!

    override func setUpWithError() throws {
        try super.setUpWithError()

        testContainer = .init()
        api = .init()
        user = try UserManager.prepareUser(apiMock: api, globalContainer: testContainer)
        sut = .init(dependencies: user.container)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        user = nil
        api = nil
        testContainer = nil
    }
    
    func testCellData() {
        let telemetry = Bool.random()
        let crashReport = Bool.random()
        user.userInfo.telemetry = telemetry.intValue
        user.userInfo.crashReports = crashReport.intValue

        XCTAssertEqual(
            sut.cellData(for: .init(row: 0, section: 0))?.title,
            PrivacyAndDataSettingViewModel.PrivacyAndDataSettingItem.anonymousTelemetry.description
        )
        XCTAssertEqual(
            sut.cellData(for: .init(row: 0, section: 0))?.status,
            telemetry
        )

        XCTAssertEqual(
            sut.cellData(for: .init(row: 0, section: 1))?.title,
            PrivacyAndDataSettingViewModel.PrivacyAndDataSettingItem.anonymousCrashReport.description
        )
        XCTAssertEqual(
            sut.cellData(for: .init(row: 0, section: 1))?.status,
            crashReport
        )
    }

    func testSectionFooter() {
        switch sut.sectionFooter(section: 0) {
        case .left(let value):
            XCTAssertEqual(value, L10n.PrivacyAndDataSettings.telemetrySubtitle)
        default:
            XCTFail("Should not be NSAttributed String")
        }

        switch sut.sectionFooter(section: 1) {
        case .left(let value):
            XCTAssertEqual(value, L10n.PrivacyAndDataSettings.crashReportSubtitle)
        default:
            XCTFail("Should not be NSAttributed String")
        }
    }

    func testToggle_telemetrySetting_settingIsUpdated() {
        user.userInfo.telemetry = 1
        api.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success([:]))
        }
        let e = expectation(description: "Closure is called")

        sut.toggle(for: .init(row: 0, section: 0), to: false) { error in
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertEqual(user.userInfo.telemetry, 0)
    }

    func testToggle_telemetrySetting_apiError_settingIsNotUpdated() {
        user.userInfo.telemetry = 1
        api.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .failure(NSError.badResponse()))
        }
        let e = expectation(description: "Closure is called")

        sut.toggle(for: .init(row: 0, section: 0), to: false) { error in
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertEqual(user.userInfo.telemetry, 1)
    }

    func testToggle_crashSetting_settingIsUpdated() {
        user.userInfo.crashReports = 1
        api.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success([:]))
        }
        let e = expectation(description: "Closure is called")

        sut.toggle(for: .init(row: 0, section: 1), to: false) { error in
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertEqual(user.userInfo.crashReports, 0)
    }

    func testToggle_crashSetting_apiError_settingIsNotUpdated() {
        user.userInfo.crashReports = 1
        api.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .failure(NSError.badResponse()))
        }
        let e = expectation(description: "Closure is called")

        sut.toggle(for: .init(row: 0, section: 1), to: false) { error in
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertEqual(user.userInfo.crashReports, 1)
    }
}
