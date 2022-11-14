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
@testable import ProtonMail

class PushNotificationServiceTests: XCTestCase {
    typealias SubscriptionWithSettings = PushNotificationService.SubscriptionWithSettings

    private var sut: PushNotificationService!

    private let mockReportedSetting1 = PushSubscriptionSettings(token: "reported_123", UID: "reported_abc")
    private lazy var mockSubscriptionWithSettings = PushNotificationService.SubscriptionWithSettings(settings: mockReportedSetting1, state: .reported)
    private lazy var mockReportedPushSettings: Set<PushNotificationService.SubscriptionWithSettings> = [mockSubscriptionWithSettings]

    private let mockOutdatedSetting1 = PushSubscriptionSettings(token: "outdated_456", UID: "outdated_def")
    private let mockOutdatedSetting2 = PushSubscriptionSettings(token: "outdated_789", UID: "outdated_ghi")
    private lazy var mockOutdatedPushSettings: Set<PushSubscriptionSettings> = [mockOutdatedSetting1, mockOutdatedSetting2]

    private let storeKey = "store-key"

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testReceivedNotificationSignOut_whenThereAreNoDeviceTokensToDelete() {
        let mockDeviceRegistrator = MockDeviceRegistrator()
        let notificationCenter = NotificationCenter()

        sut = makeSUT(mockDeviceRegistrator: mockDeviceRegistrator, notificationCenter: notificationCenter)
        notificationCenter.post(name: .didSignOut, object: nil)

        XCTAssert(mockDeviceRegistrator.deviceTokensUnregisteredCalled.isEmpty)
    }

    func testReceivedNotificationSignOut_whenThereAreDeviceTokensToDelete_requestSucceeds() {
        let mockDeviceRegistrator = MockDeviceRegistrator()
        let notificationCenter = NotificationCenter()
        let mockOutdatePushStore = StoreMock()

        sut = makeSUT(
            subscriptionSaver: mockReportedSettingsSaverForSignOutTest(),
            outdatedSaver: mockOutdatedSettingsSaverForSignOutTest(key: storeKey, keyValueProvider: mockOutdatePushStore),
            mockDeviceRegistrator: mockDeviceRegistrator,
            notificationCenter: notificationCenter
        )
        notificationCenter.post(name: .didSignOut, object: nil)

        // Requests to unregister device are executed
        XCTAssert(mockDeviceRegistrator.deviceTokensUnregisteredCalled.contains(mockOutdatedSetting1) == true)
        XCTAssert(mockDeviceRegistrator.deviceTokensUnregisteredCalled.contains(mockOutdatedSetting2) == true)
        XCTAssert(mockDeviceRegistrator.deviceTokensUnregisteredCalled.contains(mockReportedSetting1) == true)

        // Outdated push settings are removed from the data storage
        let outdatePushStoreValues = try! mockOutdatePushStore.decodeData(Set<PushSubscriptionSettings>.self, forKey: storeKey)
        XCTAssert(outdatePushStoreValues.count == 0)
    }

    func testReceivedNotificationSignOut_whenThereAreDeviceTokensToDelete_requestFails_errorDeviceUnknown() {
        let mockDeviceRegistrator = MockDeviceRegistrator()
        mockDeviceRegistrator.deviceUnregisterSuccess = false
        mockDeviceRegistrator.completionError = NSError(ErrorResponse(code: APIErrorCode.deviceTokenDoesNotExist, error: "", errorDescription: ""))
        let notificationCenter = NotificationCenter()
        let mockOutdatePushStore = StoreMock()

        sut = makeSUT(
            subscriptionSaver: mockReportedSettingsSaverForSignOutTest(),
            outdatedSaver: mockOutdatedSettingsSaverForSignOutTest(key: storeKey, keyValueProvider: mockOutdatePushStore),
            mockDeviceRegistrator: mockDeviceRegistrator,
            notificationCenter: notificationCenter
        )
        notificationCenter.post(name: .didSignOut, object: nil)

        // Outdated push settings are deleted from the data storage
        let outdatePushStoreValues = try! mockOutdatePushStore.decodeData(Set<PushSubscriptionSettings>.self, forKey: storeKey)
        XCTAssert(outdatePushStoreValues.count == 0)
    }

    func testReceivedNotificationSignOut_whenThereAreDeviceTokensToDelete_requestFails_deviceTokenInvalid() {
        let mockDeviceRegistrator = MockDeviceRegistrator()
        mockDeviceRegistrator.deviceUnregisterSuccess = false
        mockDeviceRegistrator.completionError = NSError(ErrorResponse(code: APIErrorCode.deviceTokenIsInvalid, error: "", errorDescription: ""))
        let notificationCenter = NotificationCenter()
        let mockOutdatePushStore = StoreMock()

        sut = makeSUT(
            subscriptionSaver: mockReportedSettingsSaverForSignOutTest(),
            outdatedSaver: mockOutdatedSettingsSaverForSignOutTest(key: storeKey, keyValueProvider: mockOutdatePushStore),
            mockDeviceRegistrator: mockDeviceRegistrator,
            notificationCenter: notificationCenter
        )
        notificationCenter.post(name: .didSignOut, object: nil)

        // Outdated push settings are deleted from the data storage
        let outdatePushStoreValues = try! mockOutdatePushStore.decodeData(Set<PushSubscriptionSettings>.self, forKey: storeKey)
        XCTAssert(outdatePushStoreValues.count == 0)
    }

    func testReceivedNotificationSignOut_whenThereAreDeviceTokensToDelete_requestFailsUnknownError() {
        let mockDeviceRegistrator = MockDeviceRegistrator()
        mockDeviceRegistrator.deviceUnregisterSuccess = false
        mockDeviceRegistrator.completionError = NSError(ErrorResponse(code: 400, error: "", errorDescription: ""))
        let notificationCenter = NotificationCenter()
        let mockOutdatePushStore = StoreMock()

        sut = makeSUT(
            subscriptionSaver: mockReportedSettingsSaverForSignOutTest(),
            outdatedSaver: mockOutdatedSettingsSaverForSignOutTest(key: storeKey, keyValueProvider: mockOutdatePushStore),
            mockDeviceRegistrator: mockDeviceRegistrator,
            notificationCenter: notificationCenter
        )
        notificationCenter.post(name: .didSignOut, object: nil)

        // Requests to unregister device are executed
        XCTAssert(mockDeviceRegistrator.deviceTokensUnregisteredCalled.contains(mockOutdatedSetting1) == true)
        XCTAssert(mockDeviceRegistrator.deviceTokensUnregisteredCalled.contains(mockOutdatedSetting2) == true)
        XCTAssert(mockDeviceRegistrator.deviceTokensUnregisteredCalled.contains(mockReportedSetting1) == true)

        // Outdated push settings are kept in the data storage
        let outdatePushStoreValues = try! mockOutdatePushStore.decodeData(Set<PushSubscriptionSettings>.self, forKey: storeKey)
        XCTAssert(outdatePushStoreValues.count == 3)
    }
    
    func testNoneToReported() {
        let newToken = "TO ALL FREE MEN OF OUR KINGDOM we have also granted, for us and our heirs for ever, all the liberties written out below, to have and to keep for them and their heirs, of us and our heirs"
        let session = SessionIDMock()
        let currentSubscriptionPin = InMemorySaver<Set<PushNotificationService.SubscriptionWithSettings>>()
        let expect = expectation(description: "wait for registration")

        let api = APIMock(registration: { new in
            XCTAssertEqual(new.token, newToken)
            XCTAssertEqual([new.UID], session.sessionIDs)
            XCTAssertFalse(new.encryptionKit.passphrase.isEmpty)
            XCTAssertFalse(new.encryptionKit.publicKey.isEmpty)
            XCTAssertFalse(new.encryptionKit.privateKey.isEmpty)

            return nil // no error
        },
                          unregistration: { old in return nil },
                          registrationDone: { expect.fulfill() },
                          unregistrationDone: { })


        let service = PushNotificationService.init(subscriptionSaver: currentSubscriptionPin,
                                                   encryptionKitSaver: InMemorySaver(),
                                                   outdatedSaver: InMemorySaver(),
                                                   sessionIDProvider: session,
                                                   deviceRegistrator: api,
                                                   signInProvider: SignInMock(),
                                                   unlockProvider: UnlockMock())
        NotificationCenter.default.removeObserver(service)
        currentSubscriptionPin.set(newValue: Optional.none)


        service.didRegisterForRemoteNotifications(withDeviceToken: newToken)

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)

            if let current = currentSubscriptionPin.get()?.first, current.state == .reported {
                XCTAssertEqual(current.settings, SubscriptionSettings(token: newToken, UID: session.sessionIDs.first!))
            } else {
                XCTFail("did not report altho api did not return error")
            }
        }
    }

    func testNoneToNotReported() {
        let newToken = "TO ALL FREE MEN OF OUR KINGDOM we have also granted, for us and our heirs for ever, all the liberties written out below, to have and to keep for them and their heirs, of us and our heirs"
        let session = SessionIDMock()
        let currentSubscriptionPin = InMemorySaver<Set<PushNotificationService.SubscriptionWithSettings>>()
        let expect = expectation(description: "wait for registration")

        let api = APIMock(registration: { new in
            XCTAssertEqual(new.token, newToken)
            XCTAssertEqual([new.UID], session.sessionIDs)
            XCTAssertFalse(new.encryptionKit.passphrase.isEmpty)
            XCTAssertFalse(new.encryptionKit.publicKey.isEmpty)
            XCTAssertFalse(new.encryptionKit.privateKey.isEmpty)

            return NSError.init(domain: "String", code: 0, userInfo: nil) // error
        },
                          unregistration: { old in return nil },
                          registrationDone: { expect.fulfill() },
                          unregistrationDone: { })

        let service = PushNotificationService.init(subscriptionSaver: currentSubscriptionPin,
                                                   encryptionKitSaver: InMemorySaver(),
                                                   outdatedSaver: InMemorySaver(),
                                                   sessionIDProvider: session,
                                                   deviceRegistrator: api,
                                                   signInProvider: SignInMock(),
                                                   unlockProvider: UnlockMock())
        NotificationCenter.default.removeObserver(service)
        currentSubscriptionPin.set(newValue: Optional.none)

        service.didRegisterForRemoteNotifications(withDeviceToken: newToken)

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            sleep(1)
            if let current = currentSubscriptionPin.get()?.first, current.state == .notReported { // should be notReported
                XCTAssertEqual(current.settings, SubscriptionSettings(token: newToken, UID: session.sessionIDs.first!))
            } else {
                XCTFail("did not report altho api did not return error")
            }
        }
    }

    func testReportedToReported() {
        let oldToken = "Thou shalt not covet"
        let newToken = "TO ALL FREE MEN OF OUR KINGDOM we have also granted, for us and our heirs for ever, all the liberties written out below, to have and to keep for them and their heirs, of us and our heirs"
        let session = SessionIDMock()
        let currentSubscriptionPin = InMemorySaver<Set<PushNotificationService.SubscriptionWithSettings>>()
        let outdatedPin = InMemorySaver<Set<SubscriptionSettings>>()
        let expect = expectation(description: "wait for registration")

        let api = APIMock(registration: { new in
            XCTAssertEqual(new.token, newToken)
            XCTAssertEqual([new.UID], session.sessionIDs)
            XCTAssertFalse(new.encryptionKit.passphrase.isEmpty)
            XCTAssertFalse(new.encryptionKit.publicKey.isEmpty)
            XCTAssertFalse(new.encryptionKit.privateKey.isEmpty)

            return nil // no error
        },
                          unregistration: { old in
            XCTAssertEqual(old.token, oldToken) // should unregister old
            XCTAssertEqual(old.UID, session.sessionIDs.first)
            return nil // no error
        },
                          registrationDone: { expect.fulfill() },
                          unregistrationDone: { } )

        let service = PushNotificationService.init(subscriptionSaver: currentSubscriptionPin,
                                                   encryptionKitSaver: InMemorySaver(),
                                                   outdatedSaver: outdatedPin,
                                                   sessionIDProvider: session,
                                                   deviceRegistrator: api,
                                                   signInProvider: SignInMock(),
                                                   unlockProvider: UnlockMock())
        NotificationCenter.default.removeObserver(service)
        currentSubscriptionPin.set(newValue: Set([SubscriptionWithSettings(settings: .init(token: oldToken, UID: session.sessionIDs.first!), state: .reported)])) // already have some reported subscription

        service.didRegisterForRemoteNotifications(withDeviceToken: newToken)

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)

            if let current = currentSubscriptionPin.get()?.first, current.state == .reported { // reported with new token
                XCTAssertEqual(current.settings, SubscriptionSettings(token: newToken, UID: session.sessionIDs.first!))
            } else {
                XCTFail("did not report altho api did not return error")
            }

            XCTAssertTrue(outdatedPin.get()?.isEmpty == true) // outdated should be empty
        }
    }

    //    //TODO:: enable the test
    //    func testSameSettingsNoNeedToReport() {
    //        let oldToken = "Thou shalt not covet"
    //        let session = SessionIDMock()
    //        let currentSubscriptionPin = InMemorySaver<Set<PushNotificationService.SubscriptionWithSettings>>()
    //
    //        let expect = expectation(description: "wait for registration")
    //        expect.isInverted = true // should not be fulfilled - api should not be called
    //        let api = APIMock(registration: { new in
    //                XCTFail("attempt of unnecessary registration")
    //                expect.fulfill()  // no need to continue, already not good
    //                return nil
    //        },
    //            unregistration: { old in
    //                XCTFail("attempt of unncessary unregistration")
    //                expect.fulfill()
    //                return nil // no need to continue, already not good
    //        },
    //            registrationDone: { },
    //            unregistrationDone: { })
    //
    //        let service = PushNotificationService.init(service: nil,
    //                                                   subscriptionSaver: currentSubscriptionPin,
    //                                                   encryptionKitSaver: InMemorySaver(),
    //                                                   outdatedSaver: InMemorySaver(),
    //                                                   sessionIDProvider: session,
    //                                                   deviceRegistrator: api,
    //                                                   signInProvider: SignInMock(),
    //                                                   unlockProvider: UnlockMock())
    //        NotificationCenter.default.removeObserver(service)
    //        currentSubscriptionPin.set(newValue: Set([SubscriptionWithSettings(settings:.init(token: oldToken, UID: session.sessionIDs.first!), state: .reported)])) // already have some reported subscription
    //
    //        service.didRegisterForRemoteNotifications(withDeviceToken: oldToken)
    //
    //        waitForExpectations(timeout: 5) { error in
    //            XCTAssertNil(error)
    //
    //            if let current = currentSubscriptionPin.get()?.first, current.state == .reported {  // should not be different
    //                XCTAssertEqual(current.settings, SubscriptionSettings(token: oldToken, UID: session.sessionIDs.first!))
    //            } else {
    //                 XCTFail("did change subscription altho did not need to")
    //            }
    //        }
    //    }

    func testSameSettingsNeedToReport() {
        let oldToken = "TO ALL FREE MEN OF OUR KINGDOM we have also granted, for us and our heirs for ever, all the liberties written out below, to have and to keep for them and their heirs, of us and our heirs"
        let session = SessionIDMock()
        let currentSubscriptionPin = InMemorySaver<Set<PushNotificationService.SubscriptionWithSettings>>()
        let expect = expectation(description: "wait for registration")

        let api = APIMock(registration: { new in
            XCTAssertTrue(true) // registers - good
            return nil
        },
                          unregistration: { old in
            XCTFail("attempt of unncessary unregistration")
            return nil // no need to continue, already not good
        },
                          registrationDone: { expect.fulfill() },
                          unregistrationDone: { })

        let service = PushNotificationService.init(subscriptionSaver: currentSubscriptionPin,
                                                   encryptionKitSaver: InMemorySaver(),
                                                   outdatedSaver: InMemorySaver(),
                                                   sessionIDProvider: session,
                                                   deviceRegistrator: api,
                                                   signInProvider: SignInMock(),
                                                   unlockProvider: UnlockMock())
        NotificationCenter.default.removeObserver(service)
        currentSubscriptionPin.set(newValue: Set([SubscriptionWithSettings(settings:.init(token: oldToken, UID: session.sessionIDs.first!), state: .notReported)])) // already have some reported subscription

        service.didRegisterForRemoteNotifications(withDeviceToken: oldToken) // same settings

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)

            if let current = currentSubscriptionPin.get()?.first, current.state == .reported {  // should not be different
                XCTAssertEqual(current.settings, SubscriptionSettings(token: oldToken, UID: session.sessionIDs.first!))
            } else {
                XCTFail("did not report subscription altho did not have reported previous with same settings")
            }
        }
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

        let subscription = PushNotificationService.SubscriptionWithSettings(settings: settingToReport,
                                                                            state: .reported)
        let currentSubscriptions: Set<PushNotificationService.SubscriptionWithSettings> = [subscription]

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

        let subscription = PushNotificationService.SubscriptionWithSettings(settings: settingInSubscription,
                                                                            state: .reported)
        let currentSubscriptions: Set<PushNotificationService.SubscriptionWithSettings> = [subscription]

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

extension PushNotificationServiceTests {

    private func makeSUT(
        subscriptionSaver: Saver<Set<SubscriptionWithSettings>> = InMemorySaver(),
        outdatedSaver: Saver<Set<SubscriptionSettings>> = InMemorySaver(),
        mockDeviceRegistrator: MockDeviceRegistrator = MockDeviceRegistrator(),
        notificationCenter: NotificationCenter = NotificationCenter.default
    ) -> PushNotificationService {
        let service = PushNotificationService(
            subscriptionSaver: subscriptionSaver,
            encryptionKitSaver: InMemorySaver(),
            outdatedSaver: outdatedSaver,
            sessionIDProvider: SessionIDMock(),
            deviceRegistrator: mockDeviceRegistrator,
            signInProvider: SignInMock(),
            unlockProvider: UnlockMock(),
            notificationCenter: notificationCenter
        )
        return service
    }

    private func mockOutdatedSettingsSaverForSignOutTest(key: String, keyValueProvider: KeyValueStoreProvider) -> Saver<Set<PushSubscriptionSettings>> {
        let outdatedPushSettingsSaver: Saver<Set<PushSubscriptionSettings>> = InMemorySaver(key: storeKey, store: keyValueProvider)
        outdatedPushSettingsSaver.set(newValue: mockOutdatedPushSettings)
        return outdatedPushSettingsSaver
    }

    private func mockReportedSettingsSaverForSignOutTest() -> Saver<Set<SubscriptionWithSettings>> {
        let pushSettingsSaver: Saver<Set<PushNotificationService.SubscriptionWithSettings>> = InMemorySaver()
        pushSettingsSaver.set(newValue: mockReportedPushSettings)
        return pushSettingsSaver
    }
}

// MARK: - Mocks

extension PushNotificationServiceTests {
    typealias SubscriptionSettings = PushSubscriptionSettings
    typealias Completion = API.JSONCompletion
    
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
    
    private struct APIMock: DeviceRegistrator {
        var registration: (_ settings: SubscriptionSettings) -> NSError?
        var unregistration: (_ settings: SubscriptionSettings) -> NSError?
        var registrationDone: ()->Void
        var unregistrationDone: ()->Void
        
        func device(registerWith settings: SubscriptionSettings, authCredential: AuthCredential?, completion: @escaping Completion) {
            if let error = self.registration(settings) {
                completion(nil, .failure(error))
            } else {
                completion(nil, .success([:]))
            }
            registrationDone()
        }
        
        func deviceUnregister(_ settings: SubscriptionSettings, completion: @escaping Completion) {
            if let error = self.unregistration(settings) {
                completion(nil, .failure(error))
            } else {
                completion(nil, .success([:]))
            }
            unregistrationDone()
        }
    }

    private class MockDeviceRegistrator: DeviceRegistrator {
        private(set) var deviceTokensRegisteredCalled = [PushSubscriptionSettings]()
        private(set) var deviceTokensUnregisteredCalled = [PushSubscriptionSettings]()

        var deviceRegisterSuccess: Bool = true
        var deviceUnregisterSuccess: Bool = true
        var completionError: NSError?

        func device(registerWith settings: PushSubscriptionSettings, authCredential: AuthCredential?, completion: @escaping Completion) {
            deviceTokensRegisteredCalled.append(settings)
            if deviceRegisterSuccess {
                completion(nil, .success([:]))
            } else {
                completion(nil, .failure(completionError!))
            }
        }

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
