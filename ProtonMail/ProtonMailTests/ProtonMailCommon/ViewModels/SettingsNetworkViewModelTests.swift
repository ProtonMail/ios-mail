//
//  SettingsNetworkViewModelTests.swift
//  ProtonMailTests
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import XCTest
import ProtonCore_Doh
@testable import ProtonMail

class SettingsNetworkViewModelTests: XCTestCase {

    var sut: SettingsNetworkViewModel!
    var dohLocalCacheStub: DohStub!
    var dohSettingStub: DohStatusStub!

    override func setUp() {
        super.setUp()

        dohLocalCacheStub = DohStub()
        dohSettingStub = DohStatusStub()
        sut = SettingsNetworkViewModel(userCache: dohLocalCacheStub, dohSetting: dohSettingStub)
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
        dohLocalCacheStub = nil
        dohSettingStub = nil
    }

    func testSections() {
        XCTAssertEqual(sut.sections.count, 1)
        XCTAssertEqual(sut.sections.first, .alternativeRouting)
    }

    func testDohStatus() {
        dohSettingStub.status = .off

        XCTAssertEqual(sut.isDohOn, false)
    }

    func testSetDohStatus() {
        dohSettingStub.status = .off
        dohLocalCacheStub.isDohOn = false

        sut.setDohStatus(true)

        XCTAssertTrue(dohLocalCacheStub.isDohOn)
        XCTAssertEqual(dohSettingStub.status, .on)
    }

    func testNetworkSettingsSection() {
        let alternativeRouting = SettingsNetworkViewModel.SettingSection.alternativeRouting
        XCTAssertEqual(alternativeRouting.title, LocalString._allow_alternative_routing)
        XCTAssertEqual(alternativeRouting.foot, LocalString._settings_alternative_routing_footer)
        XCTAssertEqual(alternativeRouting.head, LocalString._settings_alternative_routing_title)
    }
}
