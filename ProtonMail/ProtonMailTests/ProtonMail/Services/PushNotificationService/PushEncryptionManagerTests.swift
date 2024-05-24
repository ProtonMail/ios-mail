// Copyright (c) 2023 Proton Technologies AG
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

@testable import ProtonMail
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest

final class PushEncryptionManagerTests: XCTestCase {
    typealias InMemorySaver = PushNotificationServiceTests.InMemorySaver

    private var sut: PushEncryptionManager!

    private var mockUsers: UsersManager!
    private var sessionsIDs: [String]!
    private var mockApiService: APIServiceMock!
    private var mockDeviceRegistration: MockDeviceRegistrationUseCase!
    private var mockKitsSaver: InMemorySaver<[EncryptionKit]>!
    private var mockFailedPushProvider: MockFailedPushDecryptionProvider!
    private var mockUserDefaults: UserDefaults!
    private var globalContainer: GlobalContainer!

    private let dummyDeviceToken = "dummy_token1"
    private let dummyEncryptionKit = EncryptionKit(passphrase: "a1", privateKey: "a2", publicKey: "a3")

    override func setUp() {
        super.setUp()
        mockApiService = APIServiceMock()
        globalContainer = .init()
        mockUsers = globalContainer.usersManager
        mockDeviceRegistration = .init()
        mockDeviceRegistration.executeStub.bodyIs { _, sessionsIDs, _, _ in
            sessionsIDs.map{ DeviceRegistrationResult(sessionID: $0, error: nil) }
        }
        mockKitsSaver = .init()
        mockUserDefaults = UserDefaults(suiteName: #fileID)
        mockUserDefaults.removePersistentDomain(forName: #fileID)
        mockFailedPushProvider = .init()

        let dependencies = PushEncryptionManager.Dependencies(
            usersManager: mockUsers,
            deviceRegistration: mockDeviceRegistration,
            encryptionKitsCache: mockKitsSaver,
            pushEncryptionProvider: mockUserDefaults,
            failedPushDecryptionDefaults: mockFailedPushProvider
        )

        sut = PushEncryptionManager(dependencies: dependencies)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockApiService = nil
        sessionsIDs = nil
        mockUsers = nil
        mockDeviceRegistration = nil
        mockKitsSaver = nil
        mockUserDefaults.removePersistentDomain(forName: #fileID)
        mockUserDefaults = nil
        mockFailedPushProvider = nil
        globalContainer = nil
    }

    // MARK: Tests for registerDeviceForNotifications

    func testRegisterDeviceForNotifications_whenNoTokenRegistered_itShouldRegisterAndSaveState() {
        prepareMockSessions(num: 1)

        sut.registerDeviceForNotifications(deviceToken: dummyDeviceToken)
        wait(self.mockKitsSaver.get() != nil, timeout: 5)

        // made request
        XCTAssertEqual(mockDeviceRegistration.executeStub.callCounter, 1)
        XCTAssertEqual(mockDeviceRegistration.executeStub.lastArguments?.a2, dummyDeviceToken)

        // encryption kit saved
        let kitsSaved = mockKitsSaver.get()!
        XCTAssertEqual(kitsSaved.count, 1)
        XCTAssertEqual(kitsSaved.first?.publicKey, mockDeviceRegistration.executeStub.lastArguments?.a3)

        // token saved
        let lastTokenRegistered = mockUserDefaults.object(forKey: "pushEncryptionLastRegisteredDeviceToken") as! String
        XCTAssertEqual(lastTokenRegistered, dummyDeviceToken)
    }

    func testRegisterDeviceForNotifications_whenMultipleSessions_andAllSucceed_itSavesTokenAndKey() {
        prepareMockSessions(num: 4)

        sut.registerDeviceForNotifications(deviceToken: dummyDeviceToken)
        wait(self.mockKitsSaver.get() != nil, timeout: 5)

        // made request
        XCTAssertEqual(mockDeviceRegistration.executeStub.callCounter, 1)
        XCTAssertEqual(mockDeviceRegistration.executeStub.lastArguments?.a2, dummyDeviceToken)

        // encryption kit saved
        let kitsSaved = mockKitsSaver.get()!
        XCTAssertEqual(kitsSaved.count, 1)
        XCTAssertEqual(kitsSaved.first?.publicKey, mockDeviceRegistration.executeStub.lastArguments?.a3)

        // token saved
        let lastTokenRegistered = mockUserDefaults.object(forKey: "pushEncryptionLastRegisteredDeviceToken") as? String
        XCTAssertEqual(lastTokenRegistered, dummyDeviceToken)
    }

    func testRegisterDeviceForNotifications_whenMultipleSessions_andOneFails_itSavesTokenAndKeyAndFlagToRetry() {
        prepareMockSessions(num: 4)
        prepareOneSessionToFailRegistration(failingSession: sessionsIDs.randomElement()!)

        sut.registerDeviceForNotifications(deviceToken: dummyDeviceToken)
        wait(self.mockUserDefaults.bool(forKey: "pushEncryptionRetryDeviceTokenRegistration") == true, timeout: 5)

        // encryption kit saved
        let kitsSaved = mockKitsSaver.get()!
        XCTAssertEqual(kitsSaved.count, 1)
        XCTAssertEqual(kitsSaved.first?.publicKey, mockDeviceRegistration.executeStub.lastArguments?.a3)

        // token saved
        let lastTokenRegistered = mockUserDefaults.object(forKey: "pushEncryptionLastRegisteredDeviceToken") as! String
        XCTAssertEqual(lastTokenRegistered, dummyDeviceToken)

        // retry flag set
        XCTAssertTrue(mockUserDefaults.bool(forKey: "pushEncryptionRetryDeviceTokenRegistration"))
    }

    func testRegisterDeviceForNotifications_whenMultipleSessions_andAllFail_itDoesNotSaveToken() {
        setLastUsedDeviceToken(dummyDeviceToken)
        prepareMockSessions(num: 4)
        prepareAllSessionsToFailRegistration()

        sut.registerDeviceForNotifications(deviceToken: "new token")
        wait(self.mockDeviceRegistration.executeStub.wasCalled)

        // made request
        XCTAssertEqual(mockDeviceRegistration.executeStub.callCounter, 1)
        XCTAssertEqual(mockDeviceRegistration.executeStub.lastArguments?.a2, "new token")

        // new token not saved
        let lastTokenRegistered = mockUserDefaults.object(forKey: "pushEncryptionLastRegisteredDeviceToken") as! String
        XCTAssertEqual(lastTokenRegistered, dummyDeviceToken)
    }

    func testRegisterDeviceForNotifications_whenMultipleSessions_andAllFail_itSavesFlagToRetry() {
        setLastUsedDeviceToken(dummyDeviceToken)
        prepareMockSessions(num: 4)
        prepareAllSessionsToFailRegistration()

        sut.registerDeviceForNotifications(deviceToken: "new token")

        // made request
        wait(self.mockDeviceRegistration.executeStub.callCounter == 1)
        XCTAssertEqual(mockDeviceRegistration.executeStub.lastArguments?.a2, "new token")

        // retry flag set
        wait(self.mockUserDefaults.bool(forKey: "pushEncryptionRetryDeviceTokenRegistration"))
    }

    func testRegisterDeviceForNotifications_whenMultipleSessions_andAllFail_itShouldNotStoreKeys() {
        prepareMockSessions(num: 4)
        mockKitsSaver.set(newValue: [])
        mockDeviceRegistration.executeStub.bodyIs { _, sessionsIDs, _, _ in
            sessionsIDs.map{ .init(sessionID: $0, error: .noSessionIdFound(sessionId: sessionsIDs.first!)) }
        }
        sut.registerDeviceForNotifications(deviceToken: dummyDeviceToken)
        wait(self.mockKitsSaver.get() != nil, timeout: 5)

        XCTAssertEqual(mockKitsSaver.get()?.count, 0)
    }

    func testRegisterDeviceForNotifications_whenSameTokenIsUsed_itShouldNotRegisterTheToken() {
        prepareMockSessions(num: 1)
        setLastUsedDeviceToken(dummyDeviceToken)

        sut.registerDeviceForNotifications(deviceToken: dummyDeviceToken)

        XCTAssertEqual(mockDeviceRegistration.executeStub.callCounter, 0)
    }

    func testRegisterDeviceForNotifications_whenNewToken_itRegistersTokenWithExistingKey() {
        prepareMockSessions(num: 1)
        setLastUsedDeviceToken(dummyDeviceToken)
        mockKitsSaver.set(newValue: [dummyEncryptionKit])

        sut.registerDeviceForNotifications(deviceToken: "new token")
        wait(self.mockDeviceRegistration.executeStub.lastArguments?.a2 == "new token", timeout: 5)

        XCTAssertEqual(mockDeviceRegistration.executeStub.lastArguments?.a2, "new token")
        XCTAssertEqual(mockDeviceRegistration.executeStub.lastArguments?.a3, dummyEncryptionKit.publicKey)
        XCTAssertEqual(mockKitsSaver.get()!.count, 1)
    }

    func testRegisterDeviceForNotifications_whenSameTokenButFailDecryptionFlagEnabled_itRegistersTokenWithNewKey() {
        prepareMockSessions(num: 1)
        setLastUsedDeviceToken(dummyDeviceToken)
        mockKitsSaver.set(newValue: [dummyEncryptionKit])
        mockFailedPushProvider.hadPushNotificationDecryptionFailedStub.fixture = true
        
        sut.registerDeviceForNotifications(deviceToken: dummyDeviceToken)
        wait(self.mockDeviceRegistration.executeStub.lastArguments?.a2 == self.dummyDeviceToken, timeout: 5)

        XCTAssertEqual(mockDeviceRegistration.executeStub.lastArguments?.a2, dummyDeviceToken)
        XCTAssertNotEqual(mockDeviceRegistration.executeStub.lastArguments?.a3, dummyEncryptionKit.publicKey)
        XCTAssertEqual(mockFailedPushProvider.clearPushNotificationDecryptionFailureStub.callCounter, 1)
    }

    func testRegisterDeviceForNotifications_whenSameTokenButRetryFlagEnabled_itRegistersTokenWithExistingKey() {
        prepareMockSessions(num: 1)
        setLastUsedDeviceToken(dummyDeviceToken)
        mockKitsSaver.set(newValue: [dummyEncryptionKit])
        setRetryTokenRegistrationFlag()

        sut.registerDeviceForNotifications(deviceToken: dummyDeviceToken)
        wait(self.mockDeviceRegistration.executeStub.lastArguments?.a2 == self.dummyDeviceToken, timeout: 5)

        XCTAssertEqual(mockDeviceRegistration.executeStub.lastArguments?.a2, dummyDeviceToken)
        XCTAssertEqual(mockDeviceRegistration.executeStub.lastArguments?.a3, dummyEncryptionKit.publicKey)
        XCTAssertFalse(mockUserDefaults.bool(forKey: "pushEncryptionRetryDeviceTokenRegistration"))
    }

    func testRegisterDeviceForNotifications_whenRegisteringWithDifferentKeys_itRemovesOldestKeyWhenOverMaxAllowed() {
        prepareMockSessions(num: 1)
        // it triggers a different key every time we register a new device token
        mockFailedPushProvider.hadPushNotificationDecryptionFailedStub.fixture = true

        // setup
        let maxKeysStored = PushEncryptionManager.maxNumberOfKitsInCache
        var tokens = (1...maxKeysStored+1).map {"token\($0)"}
        sut.registerDeviceForNotifications(deviceToken: tokens.first!)
        wait(self.mockKitsSaver.get() != nil, timeout: 5)
        let firstEncryptionKitUsed = mockKitsSaver.get()!.first!
        tokens.removeFirst(1)

        // test
        tokens.forEach(sut.registerDeviceForNotifications(deviceToken:))
        wait(
            self.mockKitsSaver.get()?.contains(where: { $0.privateKey == firstEncryptionKitUsed.privateKey }) == false,
            timeout: 5
        )

        // expectations
        XCTAssertEqual(mockKitsSaver.get()!.count, maxKeysStored)
        XCTAssertFalse(mockKitsSaver.get()!.contains(where: { $0.privateKey == firstEncryptionKitUsed.privateKey }))
        XCTAssertFalse(mockKitsSaver.get()!.contains(where: { $0.passphrase == firstEncryptionKitUsed.passphrase }))
    }

    // MARK: Tests for rotatePushNotificationsEncryptionKey

    func testRegisterDeviceAfterNewAccountSignIn_whenNoTokenHasBeenRegistered_itDoesNotRegisterAnyNewKey() {
        mockKitsSaver.set(newValue: [])

        sut.registerDeviceAfterNewAccountSignIn()
        wait(self.mockKitsSaver.get() != nil, timeout: 5)

        XCTAssertEqual(mockDeviceRegistration.executeStub.callCounter, 0)
        XCTAssertEqual(mockKitsSaver.get()!.count, 0)
    }

    func testRegisterDeviceAfterNewAccountSignIn_whenTokenHasBeenRegistered_itRegistersTheSameTokenAndSameKey() {
        prepareMockSessions(num: 1)
        setLastUsedDeviceToken(dummyDeviceToken)
        mockKitsSaver.set(newValue: [dummyEncryptionKit])

        sut.registerDeviceAfterNewAccountSignIn()
        wait(self.mockDeviceRegistration.executeStub.lastArguments?.a2 == self.dummyDeviceToken, timeout: 5)

        XCTAssertEqual(mockDeviceRegistration.executeStub.callCounter, 1)
        XCTAssertEqual(mockDeviceRegistration.executeStub.lastArguments?.a2, dummyDeviceToken)
        let publicKeyUsed = mockDeviceRegistration.executeStub.lastArguments?.a3
        XCTAssertNotNil(publicKeyUsed)
        XCTAssertEqual(publicKeyUsed, dummyEncryptionKit.publicKey)
        XCTAssertEqual(mockKitsSaver.get()!.count, 1)
    }

    // MARK: Tests for deleteAllCachedData

    func testDeleteAllCachedData_itShouldClearSuccessfully() {
        let lastRegisteredDeviceTokenKey = "pushEncryptionLastRegisteredDeviceToken"
        let retryTokenRegistrationKey = "pushEncryptionRetryDeviceTokenRegistration"

        mockKitsSaver.set(newValue: [dummyEncryptionKit])
        mockUserDefaults.set(dummyDeviceToken, forKey: lastRegisteredDeviceTokenKey)
        mockUserDefaults.set(true, forKey: retryTokenRegistrationKey)

        sut.deleteAllCachedData()

        XCTAssertEqual(mockKitsSaver.get()?.count, 0)
        XCTAssertNil(mockUserDefaults.object(forKey: lastRegisteredDeviceTokenKey))
        XCTAssertFalse(mockUserDefaults.object(forKey: retryTokenRegistrationKey) as! Bool)
        XCTAssertEqual(mockFailedPushProvider.clearPushNotificationDecryptionFailureStub.callCounter, 1)
    }
}

extension PushEncryptionManagerTests {

    private func prepareMockSessions(num: UInt) {
        sessionsIDs = (1...num).map { "session\($0)" }
        sessionsIDs.map { createUserManager(userID: $0, apiService: mockApiService) }.forEach { mockUser in
            mockUsers.add(newUser: mockUser)
        }
    }

    private func setLastUsedDeviceToken(_ token: String) {
        mockUserDefaults.set(token, forKey: "pushEncryptionLastRegisteredDeviceToken")
    }

    private func setRetryTokenRegistrationFlag() {
        mockUserDefaults.set(true, forKey: "pushEncryptionRetryDeviceTokenRegistration")
    }

    private func prepareOneSessionToFailRegistration(failingSession: String) {
        let response = ResponseError(httpCode: 400, responseCode: nil, userFacingMessage: nil, underlyingError: nil)
        mockDeviceRegistration.executeStub.bodyIs { (_, sessionsIDs, _, _) in
            sessionsIDs.map{
                if $0 == failingSession {
                    return .init(sessionID: $0, error: .responseError(error: response))
                } else {
                    return .init(sessionID: $0, error: nil)
                }
            }
        }
    }

    private func prepareAllSessionsToFailRegistration() {
        let response = ResponseError(httpCode: 400, responseCode: nil, userFacingMessage: nil, underlyingError: nil)
        mockDeviceRegistration.executeStub.bodyIs { (_, sessionsIDs, _, _) in
            sessionsIDs.map{
                .init(sessionID: $0, error: .responseError(error: response))
            }
        }
    }

    func createUserManager(userID: String, apiService: APIServiceMock) -> UserManager {
        let auth = AuthCredential(
            Credential(
                UID: "\(userID)",
                accessToken: "",
                refreshToken: "",
                userName: userID,
                userID: userID,
                scopes: []
            )
        )
        return UserManager(api: apiService, authCredential: auth)
    }
}
