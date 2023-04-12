//
//  SettingsLockViewModelTests.swift
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
@testable import ProtonMail
import ProtonCore_Keymaker

class SettingsLockViewModelTests: XCTestCase {
    var sut: SettingsLockViewModel!
    var mockRouter: MockSettingsLockRouterProtocol!
    var biometricStub: BioMetricStatusStub!
    var mockKeymaker: MockKeymakerProtocol!
    var mockLockPreferences: MockLockPreferences!
    var mockNotificationCenter: NotificationCenter!
    var isAppKeyEnabled: Bool = false
    var mockUI: MockSettingsLockUIProtocol!
    let waitTimeout = 2.0

    override func setUpWithError() throws {
        mockRouter = MockSettingsLockRouterProtocol()
        biometricStub = BioMetricStatusStub()
        biometricStub.biometricTypeStub = .faceID
        mockKeymaker = MockKeymakerProtocol()
        mockKeymaker.activateStub.bodyIs { _, _, completion in completion(true) }
        mockKeymaker.deactivateStub.bodyIs { _, _ in return true }
        mockLockPreferences = MockLockPreferences()
        mockNotificationCenter = NotificationCenter()
        mockUI = MockSettingsLockUIProtocol()
        sut = SettingsLockViewModel(
            router: mockRouter,
            dependencies: .init(
                biometricStatus: biometricStub,
                userPreferences: mockLockPreferences,
                coreKeymaker: mockKeymaker,
                notificationCenter: mockNotificationCenter,
                enableAppKeyFeature: isAppKeyFeatureEnabled
            )
        )
        sut.setUIDelegate(mockUI)
    }

    override func tearDownWithError() throws {
        sut = nil
        mockRouter = nil
        biometricStub = nil
        mockKeymaker = nil
        mockLockPreferences = nil
        mockNotificationCenter = nil
        mockUI = nil
    }

    private func isAppKeyFeatureEnabled() -> Bool {
        isAppKeyEnabled
    }

    func testViewWillAppear_callsReloadData() {
        sut.viewWillAppear()
        XCTAssert(mockUI.reloadDataStub.wasCalled)
    }

    func testViewWillAppear_whenEnteringForTheFirstTime_sectionsAreCorrect() {
        sut.viewWillAppear()
        XCTAssert(sut.sections == [.protection])
    }

    func testViewWillAppear_whenEnteringForTheFirstTime_protectionItemsAreCorrect() {
        sut.viewWillAppear()
        XCTAssert(sut.protectionItems == [.none, .pinCode, .biometric])
    }

    func testViewWillAppear_whenPinEnabledAndAppKeyDisabled() {
        mockLockPreferences.isPinCodeEnabledStub.fixture = true
        sut.viewWillAppear()
        XCTAssert(sut.sections == [.protection, .changePin, .autoLockTime])
    }

    func testViewWillAppear_whenPinEnabledAndAppKeyEnabled() {
        isAppKeyEnabled = true
        mockLockPreferences.isPinCodeEnabledStub.fixture = true
        sut.viewWillAppear()
        XCTAssert(sut.sections == [.protection, .changePin, .appKeyProtection, .autoLockTime])
    }

    func testViewWillAppear_whenBiometricLockEnabledAndAppKeyDisabled() {
        mockLockPreferences.isTouchIDEnabledStub.fixture = true
        sut.viewWillAppear()
        XCTAssert(sut.sections == [.protection, .autoLockTime])
    }

    func testViewWillAppear_whenBiometricLockEnabledAndAppKeyEnabled() {
        isAppKeyEnabled = true
        mockLockPreferences.isTouchIDEnabledStub.fixture = true
        sut.viewWillAppear()
        XCTAssert(sut.sections == [.protection, .appKeyProtection, .autoLockTime])
    }

    func testDidTapNoProtection_notifiesAppLockProtectionDisabled() {
        let expect = expectation(description: "")
        mockNotificationCenter.addObserver(forName: .appLockProtectionDisabled, object: nil, queue: nil) { _ in
            expect.fulfill()
        }
        sut.input.didTapNoProtection()
        XCTAssert(mockUI.reloadDataStub.wasCalled)
        waitForExpectations(timeout: waitTimeout)
    }

    func testDidTapPinProtection_navigatesToPinSetup() {
        sut.input.didTapPinProtection()
        XCTAssert(mockRouter.goStub.wasCalledExactlyOnce)
    }

    func testDidTapChangePinCode_navigatesToPinSetup() {
        sut.input.didTapChangePinCode()
        XCTAssert(mockRouter.goStub.wasCalledExactlyOnce)
    }

    func testDidTapBiometricProtection_callsKeymakerAndNotifiesAppLockProtectionEnabled() {
        let expect = expectation(description: "")
        mockNotificationCenter.addObserver(forName: .appLockProtectionEnabled, object: nil, queue: nil) { _ in
            expect.fulfill()
        }
        sut.didTapBiometricProtection()
        // RandomPinProtection is not easy to mock to be able to assert AppKey functionality
        XCTAssert(mockKeymaker.deactivateStub.capturedArguments[0].a1 is PinProtection)
        XCTAssert(mockKeymaker.activateStub.capturedArguments[0].a1 is BioProtection)
        XCTAssert(mockLockPreferences.setKeymakerRandomkeyStub.capturedArguments[0].a1 != nil)
        waitForExpectations(timeout: waitTimeout)
    }

    func testDidPickAutoLockTime_savesValue() {
        sut.input.didPickAutoLockTime(value: 37)
        XCTAssert(mockLockPreferences.setLockTimeStub.capturedArguments.first!.value == .minutes(37))
    }
}
