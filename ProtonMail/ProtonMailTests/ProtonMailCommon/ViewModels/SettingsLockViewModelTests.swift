//
//  SettingsLockViewModelTests.swift
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
@testable import ProtonMail

class SettingsLockViewModelTests: XCTestCase {
    var sut: SettingsLockViewModel!
    var biometricStub: BioMetricStatusStub!
    var userCacheStatusStub: CacheStatusStub!

    override func setUpWithError() throws {
        biometricStub = BioMetricStatusStub()
        userCacheStatusStub = CacheStatusStub()
        sut = SettingsLockViewModelImpl(biometricStatus: biometricStub, userCacheStatus: userCacheStatusStub)
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testUpdateProtectionItemWithNoLockOn() throws {
        sut.updateProtectionItems()

        XCTAssertEqual(sut.sections.count, 1)
        XCTAssertEqual(sut.sections[0], .enableProtection)
        XCTAssertEqual(sut.bioLockItems.count, 0)
    }

    func testUpdateProtectionItemWithLockOnAndNoneBiometric() throws {
        biometricStub.biometricTypeStub = .none
        userCacheStatusStub.isPinCodeEnabledStub = true

        sut.updateProtectionItems()

        XCTAssertEqual(sut.sections.count, 3)
        XCTAssertEqual(sut.sections[0], .enableProtection)
        XCTAssertEqual(sut.sections[1], .changePin)
        XCTAssertEqual(sut.sections[2], .timing)
        XCTAssertEqual(sut.bioLockItems.count, 0)
    }

    func testUpdateProtectionItemWithLockOnAndTouchID() throws {
        biometricStub.biometricTypeStub = .touchID
        userCacheStatusStub.isPinCodeEnabledStub = true

        sut.updateProtectionItems()

        XCTAssertEqual(sut.sections.count, 4)
        XCTAssertEqual(sut.sections[0], .enableProtection)
        XCTAssertEqual(sut.sections[1], .changePin)
        XCTAssertEqual(sut.sections[2], .bioProtection)
        XCTAssertEqual(sut.sections[3], .timing)

        XCTAssertEqual(sut.bioLockItems.count, 1)
        XCTAssertEqual(sut.bioLockItems[0], .touchid)
    }

    func testUpdateProtectionItemWithLockOnAndFaceID() throws {
        biometricStub.biometricTypeStub = .faceID
        userCacheStatusStub.isPinCodeEnabledStub = true

        sut.updateProtectionItems()

        XCTAssertEqual(sut.sections.count, 4)
        XCTAssertEqual(sut.sections[0], .enableProtection)
        XCTAssertEqual(sut.sections[1], .changePin)
        XCTAssertEqual(sut.sections[2], .bioProtection)
        XCTAssertEqual(sut.sections[3], .timing)

        XCTAssertEqual(sut.bioLockItems.count, 1)
        XCTAssertEqual(sut.bioLockItems[0], .faceid)
    }

    func testBiometricType() {
        biometricStub.biometricTypeStub = .faceID

        XCTAssertEqual(sut.biometricType, .faceID)
    }

    func testBioProtectionSectionTitle() {
        biometricStub.biometricTypeStub = .faceID

        XCTAssertEqual(sut.getBioProtectionSectionTitle()?.string, "Face ID")

        biometricStub.biometricTypeStub = .touchID

        XCTAssertEqual(sut.getBioProtectionSectionTitle()?.string, "Touch ID")

        biometricStub.biometricTypeStub = .none

        XCTAssertEqual(sut.getBioProtectionSectionTitle(), nil)
    }
}
