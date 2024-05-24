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
import ProtonCoreKeymaker

class SettingsLockViewModelTests: XCTestCase {
    var sut: SettingsLockViewModel!
    var mockRouter: MockSettingsLockRouterProtocol!
    var biometricStub: MockBiometricStatusProvider!
    var mockKeymaker: MockKeyMakerProtocol!
    var isAppKeyEnabled: Bool = false
    var mockUI: MockSettingsLockUIProtocol!
    let waitTimeout = 2.0

    private var testContainer: TestContainer!

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockRouter = MockSettingsLockRouterProtocol()
        biometricStub = .init()
        biometricStub.biometricTypeStub.fixture = .faceID
        mockKeymaker = MockKeyMakerProtocol()
        mockKeymaker.activateStub.bodyIs { _, _, completion in completion(true) }
        mockKeymaker.deactivateStub.bodyIs { _, _ in return true }
        mockUI = MockSettingsLockUIProtocol()

        testContainer = .init()
        testContainer.biometricStatusProviderFactory.register {
            self.biometricStub
        }
        testContainer.keyMakerFactory.register {
            self.mockKeymaker
        }

        sut = SettingsLockViewModel(
            router: mockRouter,
            dependencies: testContainer,
            isAppKeyFeatureEnabled: { self.isAppKeyEnabled }
        )
        sut.setUIDelegate(mockUI)
    }

    override func tearDownWithError() throws {
        sut = nil
        testContainer = nil
        mockRouter = nil
        biometricStub = nil
        mockKeymaker = nil
        mockUI = nil

        try super.tearDownWithError()
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
        XCTAssertEqual(sut.sections, [.protection])
    }

    func testViewWillAppear_whenEnteringForTheFirstTime_protectionItemsAreCorrect() {
        sut.viewWillAppear()
        XCTAssertEqual(sut.protectionItems, [.none, .pinCode, .biometric])
    }

    func testViewWillAppear_whenPinEnabledAndAppKeyDisabled() {
        mockKeymaker.isPinCodeEnabledStub.fixture = true
        sut.viewWillAppear()
        XCTAssertEqual(sut.sections, [.protection, .changePin, .autoLockTime])
    }

    func testViewWillAppear_whenPinEnabledAndAppKeyEnabled() {
        isAppKeyEnabled = true
        mockKeymaker.isPinCodeEnabledStub.fixture = true
        sut.viewWillAppear()
        XCTAssertEqual(sut.sections, [.protection, .changePin, .appKeyProtection, .autoLockTime])
    }

    func testViewWillAppear_whenBiometricLockEnabledAndAppKeyDisabled() {
        mockKeymaker.isTouchIDEnabledStub.fixture = true
        sut.viewWillAppear()
        XCTAssertEqual(sut.sections, [.protection, .autoLockTime])
    }

    func testViewWillAppear_whenBiometricLockEnabledAndAppKeyEnabled() {
        isAppKeyEnabled = true
        mockKeymaker.isTouchIDEnabledStub.fixture = true
        sut.viewWillAppear()
        XCTAssertEqual(sut.sections, [.protection, .appKeyProtection, .autoLockTime])
    }

    func testDidTapNoProtection_notifiesAppLockProtectionDisabled() {
        let expect = expectation(description: "")
        testContainer.notificationCenter.addObserver(forName: .appLockProtectionDisabled, object: nil, queue: nil) { _ in
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
        testContainer.notificationCenter.addObserver(forName: .appLockProtectionEnabled, object: nil, queue: nil) { _ in
            expect.fulfill()
        }
        sut.didTapBiometricProtection()
        // RandomPinProtection is not easy to mock to be able to assert AppKey functionality
        XCTAssert(mockKeymaker.deactivateStub.capturedArguments[0].a1 is PinProtection)
        XCTAssert(mockKeymaker.activateStub.capturedArguments[0].a1 is BioProtection)
        XCTAssertNotEqual(testContainer.keychain[.keymakerRandomKey], nil)
        waitForExpectations(timeout: waitTimeout)
    }

    func testDidPickAutoLockTime_savesValue() {
        sut.input.didPickAutoLockTime(value: .minutes(37))
        XCTAssertEqual(sut.output.selectedAutolockTimeout, .minutes(37))
    }
}

extension AutolockTimeout: Equatable {
    
}
