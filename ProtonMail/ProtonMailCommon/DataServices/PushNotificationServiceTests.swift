//
//  PushNotificationServiceTests.swift
//  ProtonMailTests
//
//  Created by Anatoly Rosencrantz on 06/11/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import XCTest
@testable import ProtonMail

class PushNotificationServiceTests: XCTestCase {
    
    func testNoneToReported() {
        let newToken = "TO ALL FREE MEN OF OUR KINGDOM we have also granted, for us and our heirs for ever, all the liberties written out below, to have and to keep for them and their heirs, of us and our heirs"
        let session = SessionIDMock()
        let currentSubscriptionPin = InMemorySaver<Subscription>()
        let expect = expectation(description: "wait for registration")
        
        let api = APIMock(registration: { new in
                XCTAssertEqual(new.token, newToken)
                XCTAssertEqual(new.UID, session.sessionID)
                XCTAssertFalse(new.encryptionKit.passphrase.isEmpty)
                XCTAssertFalse(new.encryptionKit.publicKey.isEmpty)
                XCTAssertFalse(new.encryptionKit.privateKey.isEmpty)
            
                switch currentSubscriptionPin.get() ?? .none { // should be pending with new settings
                case .pending: XCTAssertTrue(true)
                default: XCTFail("did not put to pending while calling api")
                }
            
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
                                                   signInProvider: SignInMock())
        currentSubscriptionPin.set(newValue: Optional.none)
        
        
        service.didRegisterForRemoteNotifications(withDeviceToken: newToken)
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            
            switch currentSubscriptionPin.get() ?? .none { // should be reported
            case .reported(let settings): XCTAssertEqual(settings, SubscriptionSettings(token: newToken, UID: session.sessionID!))
            default: XCTFail("did not report altho api did not return error")
            }
        }
    }
    
    func testNoneToNotReported() {
        let newToken = "TO ALL FREE MEN OF OUR KINGDOM we have also granted, for us and our heirs for ever, all the liberties written out below, to have and to keep for them and their heirs, of us and our heirs"
        let session = SessionIDMock()
        let currentSubscriptionPin = InMemorySaver<Subscription>()
        let expect = expectation(description: "wait for registration")
        
        let api = APIMock(registration: { new in
                XCTAssertEqual(new.token, newToken)
                XCTAssertEqual(new.UID, session.sessionID)
                XCTAssertFalse(new.encryptionKit.passphrase.isEmpty)
                XCTAssertFalse(new.encryptionKit.publicKey.isEmpty)
                XCTAssertFalse(new.encryptionKit.privateKey.isEmpty)
            
                switch currentSubscriptionPin.get() ?? .none { // should be pending with new settings
                case .pending: XCTAssertTrue(true)
                default: XCTFail("did not put to pending while calling api")
                }
            
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
                                                   signInProvider: SignInMock())
        currentSubscriptionPin.set(newValue: Optional.none)
        
        service.didRegisterForRemoteNotifications(withDeviceToken: newToken)
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            
            switch currentSubscriptionPin.get() ?? .none { // should be notReported
            case .notReported(let settings): XCTAssertEqual(settings, SubscriptionSettings(token: newToken, UID: session.sessionID!))
            default: XCTFail("did not report altho api did not return error")
            }
        }
    }
    
    func testReportedToReported() {
        let oldToken = "Thou shalt not covet"
        let newToken = "TO ALL FREE MEN OF OUR KINGDOM we have also granted, for us and our heirs for ever, all the liberties written out below, to have and to keep for them and their heirs, of us and our heirs"
        let session = SessionIDMock()
        let currentSubscriptionPin = InMemorySaver<Subscription>()
        let outdatedPin = InMemorySaver<Set<SubscriptionSettings>>()
        let expect = expectation(description: "wait for registration")
        
        let api = APIMock(registration: { new in
                XCTAssertEqual(new.token, newToken)
                XCTAssertEqual(new.UID, session.sessionID)
                XCTAssertFalse(new.encryptionKit.passphrase.isEmpty)
                XCTAssertFalse(new.encryptionKit.publicKey.isEmpty)
                XCTAssertFalse(new.encryptionKit.privateKey.isEmpty)
            
                switch currentSubscriptionPin.get() ?? .none { // should be pending with new settings
                case .pending(let settings):
                    XCTAssertEqual(new.token, settings.token)
                    XCTAssertEqual(new.UID, settings.UID)
                    XCTAssertEqual(new.encryptionKit, settings.encryptionKit)
                default: XCTFail("did not put to pending while calling api")
                }
                return nil // no error
        },
            unregistration: { old in
                XCTAssertEqual(old.token, oldToken) // should unregister old
                XCTAssertEqual(old.UID, session.sessionID)
                return nil // no error
        },
            registrationDone: { },
            unregistrationDone: { expect.fulfill() })
        
        let service = PushNotificationService.init(subscriptionSaver: currentSubscriptionPin,
                                                   encryptionKitSaver: InMemorySaver(),
                                                   outdatedSaver: outdatedPin,
                                                   sessionIDProvider: session,
                                                   deviceRegistrator: api,
                                                   signInProvider: SignInMock())
        
        currentSubscriptionPin.set(newValue: .reported(.init(token: oldToken, UID: session.sessionID!))) // already have some reported subscription
        
        service.didRegisterForRemoteNotifications(withDeviceToken: newToken)
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            
            switch currentSubscriptionPin.get() ?? .none { // reported with new token
            case .reported(let settings): XCTAssertEqual(settings, SubscriptionSettings(token: newToken, UID: session.sessionID!))
            default: XCTFail("did not report altho api did not return error")
            }
            
            XCTAssertTrue(outdatedPin.get()!.isEmpty) // outdated should be empty
        }
    }

    func testSameSettingsNoNeedToReport() {
        let oldToken = "Thou shalt not covet"
        let session = SessionIDMock()
        let currentSubscriptionPin = InMemorySaver<Subscription>()
        
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
        
        let service = PushNotificationService.init(subscriptionSaver: currentSubscriptionPin,
                                                   encryptionKitSaver: InMemorySaver(),
                                                   outdatedSaver: InMemorySaver(),
                                                   sessionIDProvider: session,
                                                   deviceRegistrator: api,
                                                   signInProvider: SignInMock())
        
        currentSubscriptionPin.set(newValue: .reported(.init(token: oldToken, UID: session.sessionID!))) // already have some reported subscription
        
        service.didRegisterForRemoteNotifications(withDeviceToken: oldToken)
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            
            switch currentSubscriptionPin.get() ?? .none { // should not be different
            case .reported(let settings): XCTAssertEqual(settings, SubscriptionSettings(token: oldToken, UID: session.sessionID!))
            default: XCTFail("did change subscription altho did not need to")
            }
        }
    }
    
    func testSameSettingsNeedToReport() {
        let oldToken = "TO ALL FREE MEN OF OUR KINGDOM we have also granted, for us and our heirs for ever, all the liberties written out below, to have and to keep for them and their heirs, of us and our heirs"
        let session = SessionIDMock()
        let currentSubscriptionPin = InMemorySaver<Subscription>()
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
                                                   signInProvider: SignInMock())
        
        currentSubscriptionPin.set(newValue: .notReported(.init(token: oldToken, UID: session.sessionID!))) // already have not reported subscription
        
        service.didRegisterForRemoteNotifications(withDeviceToken: oldToken) // same settings
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            
            switch currentSubscriptionPin.get() ?? .none { // should not be different
            case .reported(let settings): XCTAssertEqual(settings, SubscriptionSettings(token: oldToken, UID: session.sessionID!))
            default: XCTFail("did not report subscription altho did not have reported previous with same settings")
            }
        }
    }

}

// MARK: - Mocks

extension PushNotificationServiceTests {
    typealias Subscription = PushNotificationService.Subscription
    typealias SubscriptionSettings = PushSubscriptionSettings
    typealias Completion = APIService.CompletionBlock
    
    private class InMemorySaver<T: Codable>: Saver<T> {
        convenience init() {
            self.init(key: "", store: StoreMock())
        }
    }
    
    class StoreMock: KeyValueStoreProvider {
        func data(forKey key: String) -> Data? { return nil }
        func removeItem(forKey key: String) { }
        func setData(_ data: Data, forKey key: String) { }
    }
    
    private struct SessionIDMock: SessionIdProvider {
        var sessionID: String? = "001100010010011110100001101101110011"
    }
    
    private struct APIMock: DeviceRegistrator {
        var registration: (_ settings: SubscriptionSettings) -> NSError?
        var unregistration: (_ settings: SubscriptionSettings) -> NSError?
        var registrationDone: ()->Void
        var unregistrationDone: ()->Void
        
        func device(registerWith settings: SubscriptionSettings, completion: Completion?) {
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
}
