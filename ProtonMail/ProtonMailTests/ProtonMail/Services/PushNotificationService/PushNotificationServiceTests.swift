//
//  PushNotificationServiceTests.swift
//  ProtonMailTests - Created on 06/11/2018.
//
//
//  Copyright (c) 2019 Proton AG
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
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_TestingToolkit
@testable import ProtonMail

class PushNotificationServiceTests: XCTestCase {
    typealias SubscriptionWithSettings = PushNotificationService.SubscriptionWithSettings

    private var sut: PushNotificationService!
    private var sessionIdProvider: SessionIdProvider!
    private var subscriptionSaver: InMemorySaver<Set<SubscriptionWithSettings>>!
    private var mockRegisterDevice: MockRegisterDeviceUseCase!

    private let dummyToken = "dummy_token"
    private var firstSessionId: String { sessionIdProvider.sessionIDs.first! }

    override func setUpWithError() throws {
        try super.setUpWithError()
        sessionIdProvider = SessionIDMock()
        subscriptionSaver = .init()
        mockRegisterDevice = .init()
        sut = PushNotificationService(
            subscriptionSaver: subscriptionSaver,
            encryptionKitSaver: InMemorySaver(),
            outdatedSaver: InMemorySaver(),
            sessionIDProvider: sessionIdProvider,
            deviceRegistrator: MockDeviceRegistrator(),
            signInProvider: SignInMock(),
            unlockProvider: UnlockMock(),
            notificationCenter: .default,
            dependencies: .init(lockCacheStatus: MockLockCacheStatus(), registerDevice: mockRegisterDevice)
        )
        NotificationCenter.default.removeObserver(sut!)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        sessionIdProvider = nil
        subscriptionSaver = nil
        mockRegisterDevice = nil
    }

    func testDidRegisterForRemoteNotifications_whenRegisterDeviceSucceeds_itStoresTheTokenAsReported() {
        let expect = expectation(description: "wait for registration")
        mockRegisterDevice.callExecutionBlock.bodyIs { _, _, callback in
            callback(.success(()))
            expect.fulfill()
        }
        subscriptionSaver.set(newValue: nil)

        sut.didRegisterForRemoteNotifications(withDeviceToken: dummyToken)

        waitForExpectations(timeout: 1.0)

        let subsWithSetting = subscriptionSaver.get()!.first!
        XCTAssertEqual(subsWithSetting.state, .reported)
        XCTAssertEqual(subsWithSetting.settings.token, dummyToken)
        XCTAssertEqual(subsWithSetting.settings.UID, firstSessionId)

        XCTAssertEqual(mockRegisterDevice.callExecutionBlock.lastArguments!.a1.deviceToken, dummyToken)
        XCTAssertEqual(mockRegisterDevice.callExecutionBlock.lastArguments!.a1.uid, firstSessionId)
    }

    func testDidRegisterForRemoteNotifications_whenRegisterDeviceFails_itStoresTheTokenAsNotReported() {
        let expect = expectation(description: "wait for registration")

        mockRegisterDevice.callExecutionBlock.bodyIs { _, _, callback in
            callback(.failure(NSError(domain: "dummy_domain", code: 0, userInfo: nil)))
            expect.fulfill()
        }
        subscriptionSaver.set(newValue: nil)

        sut.didRegisterForRemoteNotifications(withDeviceToken: dummyToken)

        waitForExpectations(timeout: 1.0)
        let subsWithSetting = subscriptionSaver.get()!.first!
        XCTAssertEqual(subsWithSetting.state, .notReported)
        XCTAssertEqual(subsWithSetting.settings.token, dummyToken)
        XCTAssertEqual(subsWithSetting.settings.UID, firstSessionId)

        XCTAssertEqual(mockRegisterDevice.callExecutionBlock.lastArguments!.a1.deviceToken, dummyToken)
        XCTAssertEqual(mockRegisterDevice.callExecutionBlock.lastArguments!.a1.uid, firstSessionId)
    }

    func testDidRegisterForRemoteNotifications_whenRegisterDeviceSucceeds_itOverwritesTheTokenForTheSameSession() {
        let expect = expectation(description: "wait for registration")

        mockRegisterDevice.callExecutionBlock.bodyIs { _, _, callback in
            callback(.success(()))
            expect.fulfill()
        }
        let subs = [SubscriptionWithSettings(settings: .init(token: "oldToken", UID: firstSessionId), state: .reported)]
        subscriptionSaver.set(newValue: Set(subs))

        sut.didRegisterForRemoteNotifications(withDeviceToken: dummyToken)

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(subscriptionSaver.get()?.count, 1)
        let subsWithSetting = subscriptionSaver.get()!.first!
        XCTAssertEqual(subsWithSetting.state, .reported)
        XCTAssertEqual(subsWithSetting.settings.token, dummyToken)
        XCTAssertEqual(subsWithSetting.settings.UID, firstSessionId)

        XCTAssertEqual(mockRegisterDevice.callExecutionBlock.lastArguments!.a1.deviceToken, dummyToken)
        XCTAssertEqual(mockRegisterDevice.callExecutionBlock.lastArguments!.a1.uid, firstSessionId)
    }

    /// This test expects to register the reported token again because it follows the current
    /// implementation even though indicates lack of confidence in the report status.
    func testDidRegisterForRemoteNotifications_whenTokenAlreadyReported_itShouldRegisterTheSameToken() {
        let expect = expectation(description: "wait for registration")

        mockRegisterDevice.callExecutionBlock.bodyIs { _, _, callback in
            callback(.success(()))
            expect.fulfill()
        }
        let subs = [SubscriptionWithSettings(settings: .init(token: dummyToken, UID: firstSessionId), state: .reported)]
        subscriptionSaver.set(newValue: Set(subs))

        sut.didRegisterForRemoteNotifications(withDeviceToken: dummyToken)

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(subscriptionSaver.get()?.count, 1)
        let subsWithSetting = subscriptionSaver.get()!.first!
        XCTAssertEqual(subsWithSetting.state, .reported)
        XCTAssertEqual(subsWithSetting.settings.token, dummyToken)
        XCTAssertEqual(subsWithSetting.settings.UID, firstSessionId)

        XCTAssertEqual(mockRegisterDevice.callExecutionBlock.lastArguments!.a1.deviceToken, dummyToken)
        XCTAssertEqual(mockRegisterDevice.callExecutionBlock.lastArguments!.a1.uid, firstSessionId)
    }

    func testUpdateSettingsIfNeeded_notInCurrentSubscription_UpdateClosureCalled() {
        let settingToReport = PushSubscriptionSettings(token: "token1", UID: "UID1")
        let result = [settingToReport: PushNotificationService.SubscriptionState.reported]
        let expection1 = expectation(description: "closure is called")

        let sut = PushNotificationService.updateSettingsIfNeeded
        sut(result, []) { result in
            XCTAssertEqual(result.0, settingToReport)
            XCTAssertEqual(result.1, .reported)
            XCTAssertEqual(result.0.encryptionKit, settingToReport.encryptionKit)
            expection1.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testUpdateSettingsIfNeeded_inCurrentSubscriptionAndReported_updateClosureNotCalled() {
        let settingToReport = PushSubscriptionSettings(token: "token1", UID: "UID1")
        let result = [settingToReport: PushNotificationService.SubscriptionState.reported]

        let subscription = SubscriptionWithSettings(settings: settingToReport, state: .reported)
        let currentSubscriptions: Set<SubscriptionWithSettings> = [subscription]

        let expection1 = expectation(description: "closure is called")
        expection1.isInverted = true
        let sut = PushNotificationService.updateSettingsIfNeeded

        sut(result, currentSubscriptions) { _ in
            expection1.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testUpdateSettingsIfNeeded_inCurrentSubscriptionAndReportedWithDifferentEncryptionkit_updateClosureIsCalled() throws {
        var settingToReport = PushSubscriptionSettings(token: "token1", UID: "UID1")
        try settingToReport.generateEncryptionKit()

        var settingInSubscription = PushSubscriptionSettings(token: "token1", UID: "UID1")
        try settingInSubscription.generateEncryptionKit()

        let result = [settingToReport: PushNotificationService.SubscriptionState.reported]

        let subscription = SubscriptionWithSettings(settings: settingInSubscription, state: .reported)
        let currentSubscriptions: Set<SubscriptionWithSettings> = [subscription]

        let expection1 = expectation(description: "closure is called")
        let sut = PushNotificationService.updateSettingsIfNeeded

        sut(result, currentSubscriptions) { result in

            XCTAssertEqual(result.0, settingToReport)
            XCTAssertEqual(result.1, .reported)
            XCTAssertEqual(result.0.encryptionKit, settingToReport.encryptionKit)
            expection1.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
    }
}

// MARK: - Mocks

extension PushNotificationServiceTests {
    typealias SubscriptionSettings = PushSubscriptionSettings
    typealias Completion = JSONCompletion
    
    class InMemorySaver<T: Codable>: Saver<T> {
        
        convenience init(store: StoreMock = StoreMock()) {
            self.init(key: "", store: store)
        }
    }
    
    class StoreMock: KeyValueStoreProvider {
        enum Errors: Error {
            case noData
        }
        private(set) var dict = [String: Any]()

        func set(_ intValue: Int, forKey key: String) { dict[key] = intValue }
        func set(_ data: Data, forKey key: String) { dict[key] = data }
        func set(_ value: Bool, forKey defaultName: String) { dict[defaultName] = value }

        func int(forKey key: String) -> Int? { return dict[key] as? Int }
        func bool(forKey defaultName: String) -> Bool { return dict[defaultName] as? Bool ?? false }
        func data(forKey key: String) -> Data? { return dict[key] as? Data }

        func remove(forKey key: String) { dict[key] = nil }

        func decodeData<D: Decodable>(_ type: D.Type, forKey key: String) throws -> D {
            guard let data = dict[key] as? Data else {
                throw Errors.noData
            }
            return try PropertyListDecoder().decode(type, from: data)
        }
    }
    
    private struct SessionIDMock: SessionIdProvider {
        var sessionIDs = ["001100010010011110100001101101110011"]
    }
    
    private class MockDeviceRegistrator: DeviceRegistrator {
        private(set) var deviceTokensUnregisteredCalled = [PushSubscriptionSettings]()
        var deviceUnregisterSuccess: Bool = true
        var completionError: NSError?

        func deviceUnregister(_ settings: PushSubscriptionSettings, completion: @escaping Completion) {
            deviceTokensUnregisteredCalled.append(settings)
            if deviceUnregisterSuccess {
                completion(nil, .success([:]))
            } else {
                completion(nil, .failure(completionError!))
            }
        }
    }
    
    private struct SignInMock: SignInProvider {
        let isSignedIn: Bool = true
    }
    
    private struct UnlockMock: UnlockProvider {
        let isUnlocked: Bool = true
    }
}
