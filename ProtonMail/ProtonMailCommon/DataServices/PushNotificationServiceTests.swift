//
//  PushNotificationServiceTests.swift
//  ProtonMailTests - Created on 06/11/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

class PushNotificationServiceTests: XCTestCase {
    typealias SubscriptionWithSettings = PushNotificationService.SubscriptionWithSettings
    
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
            
                if let current = currentSubscriptionPin.get()?.first, current.state == .pending {
                    XCTAssertTrue(true)
                } else {
                    XCTFail("did not put to pending while calling api")
                }
            
                return nil // no error
        },
            unregistration: { old in return nil },
            registrationDone: { expect.fulfill() },
            unregistrationDone: { })
        
        
        let service = PushNotificationService.init(service: nil,
                                                   subscriptionSaver: currentSubscriptionPin,
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
            
                if let current = currentSubscriptionPin.get()?.first, current.state == .pending { // should be pending with new settings
                    XCTAssertTrue(true)
                } else {
                    XCTFail("did not put to pending while calling api")
                }

                return NSError.init(domain: "String", code: 0, userInfo: nil) // error
        },
            unregistration: { old in return nil },
            registrationDone: { expect.fulfill() },
            unregistrationDone: { })
        
        let service = PushNotificationService.init(service: nil,
                                                   subscriptionSaver: currentSubscriptionPin,
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
            
            
                if let current = currentSubscriptionPin.get()?.first, current.state == .pending { // should be pending with new settings
                    XCTAssertEqual(new.token, current.settings.token)
                    XCTAssertEqual(new.UID, current.settings.UID)
                    XCTAssertEqual(new.encryptionKit, current.settings.encryptionKit)
                } else {
                    XCTFail("did not put to pending while calling api")
                }
                
                return nil // no error
        },
            unregistration: { old in
                XCTAssertEqual(old.token, oldToken) // should unregister old
                XCTAssertEqual(old.UID, session.sessionIDs.first)
                return nil // no error
        },
            registrationDone: { },
            unregistrationDone: { expect.fulfill() })
        
        let service = PushNotificationService.init(service: nil,
                                                   subscriptionSaver: currentSubscriptionPin,
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

    func testSameSettingsNoNeedToReport() {
        let oldToken = "Thou shalt not covet"
        let session = SessionIDMock()
        let currentSubscriptionPin = InMemorySaver<Set<PushNotificationService.SubscriptionWithSettings>>()
        
        let expect = expectation(description: "wait for registration")
        expect.isInverted = true // should not be fulfilled - api should not be called

        let api = APIMock(registration: { new in
                XCTFail("attempt of unnecessary registration")
                expect.fulfill()  // no need to continue, already not good
                return nil
        },
            unregistration: { old in
                XCTFail("attempt of unncessary unregistration")
                expect.fulfill()
                return nil // no need to continue, already not good
        },
            registrationDone: { },
            unregistrationDone: { })
        
        let service = PushNotificationService.init(service: nil,
                                                   subscriptionSaver: currentSubscriptionPin,
                                                   encryptionKitSaver: InMemorySaver(),
                                                   outdatedSaver: InMemorySaver(),
                                                   sessionIDProvider: session,
                                                   deviceRegistrator: api,
                                                   signInProvider: SignInMock(),
                                                   unlockProvider: UnlockMock())
        NotificationCenter.default.removeObserver(service)
        currentSubscriptionPin.set(newValue: Set([SubscriptionWithSettings(settings:.init(token: oldToken, UID: session.sessionIDs.first!), state: .reported)])) // already have some reported subscription
        
        service.didRegisterForRemoteNotifications(withDeviceToken: oldToken)

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            
            if let current = currentSubscriptionPin.get()?.first, current.state == .reported {  // should not be different
                XCTAssertEqual(current.settings, SubscriptionSettings(token: oldToken, UID: session.sessionIDs.first!))
            } else {
                 XCTFail("did change subscription altho did not need to")
            }
        }
    }

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
        
        let service = PushNotificationService.init(service: nil,
                                                   subscriptionSaver: currentSubscriptionPin,
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

}

// MARK: - Mocks

extension PushNotificationServiceTests {
    typealias SubscriptionSettings = PushSubscriptionSettings
    typealias Completion = CompletionBlock
    
    internal class InMemorySaver<T: Codable>: Saver<T> {
        convenience init() {
            self.init(key: "", store: StoreMock())
        }
    }
    
    class StoreMock: KeyValueStoreProvider {
        func int(forKey key: String) -> Int? { return nil }
        func set(_ intValue: Int, forKey key: String) { }
        func set(_ data: Data, forKey key: String) { }
        func data(forKey key: String) -> Data? { return nil }
        func remove(forKey key: String) { }
    }
    
    private struct SessionIDMock: SessionIdProvider {
        var sessionIDs = ["001100010010011110100001101101110011"]
    }
    
    private struct APIMock: DeviceRegistrator {
        var registration: (_ settings: SubscriptionSettings) -> NSError?
        var unregistration: (_ settings: SubscriptionSettings) -> NSError?
        var registrationDone: ()->Void
        var unregistrationDone: ()->Void
        
        func device(registerWith settings: SubscriptionSettings, authCredential: AuthCredential?, completion: Completion?) {
            completion?(nil, nil, self.registration(settings))
            registrationDone()
        }
        
        func deviceUnregister(_ settings: SubscriptionSettings, completion: @escaping Completion) {
            completion(nil, nil, self.unregistration(settings))
            unregistrationDone()
        }
    }
    
    private struct SignInMock: SignInProvider {
        let isSignedIn: Bool = true
    }
    
    private struct UnlockMock: UnlockProvider {
        let isUnlocked: Bool = true
    }
}
