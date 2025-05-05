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

import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

final class TelemetryServiceTests: XCTestCase {
    private var sut: TelemetryService!
    private var userContainer: UserContainer!
    private var mockUserManager: UserManager!
    private var mockApiService: APIServiceMock!
    private var mockUserDefaults: UserDefaults!
    private var isTelemetrySettingOn: Bool = true
    private let dummyUserID = UserID(rawValue: "user-1")

    override func setUp() {
        super.setUp()
        mockApiService = .init()
        mockApiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, _, completion in
            XCTAssertEqual(path, "/data/v1/stats")
            let response = "{\"Code\": 1000}"
            completion(nil, .success(response.toDictionary()!))
        }
        mockUserDefaults = UserDefaults(suiteName: #fileID)
        mockUserDefaults.removePersistentDomain(forName: #fileID)

        let testContainer: TestContainer = .init()
        testContainer.userDefaultsFactory.register { self.mockUserDefaults }
        mockUserManager = UserManager(api: mockApiService, globalContainer: testContainer)
        userContainer = mockUserManager.container

        sut = .init(
            userID: dummyUserID,
            shouldBuildSendTelemetry: true,
            isTelemetrySettingOn: { self.isTelemetrySettingOn },
            dependencies: userContainer
        )
    }

    override func tearDown() {
        super.tearDown()
        mockApiService = nil
        mockUserManager = nil
        mockUserDefaults = nil
        userContainer = nil
        sut = nil
    }

    // telemetry enabled condition

    func testSendEvent_whenTelemetryIsEnabled_itSendsTheEvent() async {
        isTelemetrySettingOn = true
        await sut.sendEvent(.dummyEvent(frequency: .always))
        XCTAssertEqual(mockApiService.requestJSONStub.callCounter, 1)
    }

    func testSendEvent_whenTelemetryIsDisabled_itDoesNotSendTheEvent() async {
        isTelemetrySettingOn = false
        await sut.sendEvent(.dummyEvent(frequency: .always))
        XCTAssertEqual(mockApiService.requestJSONStub.callCounter, 0)
    }

    // ReportFrequency.onceEvery24Hours

    func testSendEvent_whenEventFrequencyIsOnceEvery24Hours_andPreviousIsOlderThan24h_itSendsTheEvent() async {
        let dummyEvent: TelemetryEvent = .dummyEvent(frequency: .onceEvery24Hours)
        let timestamp = timestampHoursAgo(25)
        userContainer.userDefaults[.telemetryFrequency] = [dummyUserID.rawValue: [dummyEvent.type: timestamp]]

        await sut.sendEvent(dummyEvent)
        XCTAssertEqual(mockApiService.requestJSONStub.callCounter, 1)
    }

    func testSendEvent_whenEventFrequencyIsOnceEvery24Hours_andPreviousIsNewerThan24h_itDoesNotSendTheEvent() async {
        let dummyEvent: TelemetryEvent = .dummyEvent(frequency: .onceEvery24Hours)
        let timestamp = timestampHoursAgo(23)
        userContainer.userDefaults[.telemetryFrequency] = [dummyUserID.rawValue: [dummyEvent.type: timestamp]]

        await sut.sendEvent(dummyEvent)
        XCTAssertEqual(mockApiService.requestJSONStub.callCounter, 0)
    }

    // timestamp persistence

    func testSendEvent_whenEventFrequencyIsOnceEvery24Hours_itPersistsTheTimestamp() async {
        let dummyEvent: TelemetryEvent = .dummyEvent(frequency: .onceEvery24Hours)

        await sut.sendEvent(dummyEvent)
        XCTAssertNotNil(readUserDefaultsTimestamp(for: dummyEvent))
    }

    func testSendEvent_whenEventFrequencyIsOnceEvery24Hours_andRequestFails_itDoesNotPersistTheTimestamp() async {
        mockApiService.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .failure(.badResponse()))
        }
        let dummyEvent: TelemetryEvent = .dummyEvent(frequency: .onceEvery24Hours)

        await sut.sendEvent(dummyEvent)
        XCTAssertNil(readUserDefaultsTimestamp(for: dummyEvent))
    }

    func testSendEvent_whenEventFrequencyIsAlways_itDoesNotPersistTheTimestamp() async {
        let dummyEvent: TelemetryEvent = .dummyEvent(frequency: .always)

        await sut.sendEvent(dummyEvent)
        XCTAssertNil(readUserDefaultsTimestamp(for: dummyEvent))
    }
}

extension TelemetryServiceTests {

    private func timestampHoursAgo(_ hours: Int) -> Int {
        let date = Calendar.current.date(byAdding: .hour, value: -hours, to: Date())!
        return Int(date.timeIntervalSince1970)
    }

    private func readUserDefaultsTimestamp(for event: TelemetryEvent) -> Int? {
        userContainer.userDefaults[.telemetryFrequency][dummyUserID.rawValue]?[event.type]
    }
}

private extension TelemetryEvent {

    static func dummyEvent(frequency: ReportFrequency) -> Self {
        .init(measurementGroup: "group", name: "name", values: [:], dimensions: [:], frequency: frequency)
    }
}
