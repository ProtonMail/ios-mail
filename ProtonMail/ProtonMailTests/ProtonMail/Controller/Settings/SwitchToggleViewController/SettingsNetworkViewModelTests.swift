//
//  SettingsNetworkViewModelTests.swift
//  ProtonMailTests
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import XCTest
import ProtonCoreDoh
import ProtonCoreTestingToolkitUnitTestsDoh

@testable import ProtonMail

final class NetworkSettingViewModelTests: XCTestCase {

    var sut: NetworkSettingViewModel!
    var userDefaults: UserDefaults!
    var dohSettingStub: DohInterfaceMock!

    override func setUp() {
        super.setUp()

        userDefaults = TestContainer().userDefaults
        dohSettingStub = DohInterfaceMock()
        sut = NetworkSettingViewModel(userDefaults: userDefaults, dohSetting: dohSettingStub)
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
        userDefaults = nil
        dohSettingStub = nil
    }

    func testSections() throws {
        dohSettingStub.statusStub.fixture = .on
        XCTAssertEqual(sut.output.sectionNumber, 1)
        let data = try XCTUnwrap(sut.output.cellData(for: IndexPath(row: 0, section: 0)))
        XCTAssertEqual(data.title, LocalString._allow_alternative_routing)
    }

    func testDohStatus() throws {
        dohSettingStub.statusStub.fixture = .off
        let data = try XCTUnwrap(sut.output.cellData(for: IndexPath(row: 0, section: 0)))
        XCTAssertEqual(data.status, false)
    }

    func testSetDohStatus() {
        userDefaults[.isDohOn] = false

        let ex = expectation(description: "Closure is called")
        sut.input.toggle(for: IndexPath(row: 0, section: 0), to: true) { error in
            XCTAssertNil(error)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 1)
        XCTAssertTrue(userDefaults[.isDohOn])
        XCTAssertEqual(dohSettingStub.statusStub.setCallCounter, 1)
        XCTAssertEqual(dohSettingStub.statusStub.setLastArguments?.value, .on)
    }

    func testNetworkSettingsSection() throws {
        let header = try XCTUnwrap(sut.output.sectionHeader())
        let footer = try XCTUnwrap(sut.output.sectionFooter(section: 0))
        XCTAssertEqual(header, LocalString._settings_alternative_routing_title)
        switch footer {
        case .left(_):
            XCTFail("Should be an attributedString")
        case .right(let attributedString):
            let footerDesc = LocalString._settings_alternative_routing_footer
            let learnMore = LocalString._settings_alternative_routing_learn
            let text = attributedString.string
            XCTAssertEqual(String.localizedStringWithFormat(footerDesc, learnMore), text)
        }
    }
}
