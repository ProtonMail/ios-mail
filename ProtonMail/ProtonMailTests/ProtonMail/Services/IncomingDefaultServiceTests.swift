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

import CoreData
import ProtonCore_DataModel
import ProtonCore_TestingToolkit
import XCTest

@testable import ProtonMail

final class IncomingDefaultServiceTests: XCTestCase {
    private var apiService: APIServiceMock!
    private var contextProvider: MockCoreDataContextProvider!
    private var sut: IncomingDefaultService!

    private let emailAddress = String.randomString(10)
    private let location = IncomingDefaultsAPI.Location.inbox
    private var userInfo = UserInfo.dummy

    override func setUpWithError() throws {
        try super.setUpWithError()

        apiService = APIServiceMock()
        contextProvider = MockCoreDataContextProvider()

        sut = IncomingDefaultService(
            dependencies: .init(apiService: apiService, contextProvider: contextProvider, userInfo: userInfo)
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        apiService = nil
        contextProvider = nil

        try super.tearDownWithError()
    }

    func testFetchAll_overwritesOlderIncomingDefaultsForTheSameEmail() async throws {
        storeStubbedObject(id: "Old ID", time: .distantPast)

        let stubbedResponse = GetIncomingDefaultsResponse(
            code: 0,
            incomingDefaults: [
                IncomingDefaultDTO(
                    email: emailAddress,
                    id: "New ID",
                    location: location,
                    time: .distantFuture
                )
            ],
            total: 1
        )

        apiService.requestDecodableStub.bodyIs { _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success(stubbedResponse))
        }

        try await sut.fetchAll(location: location)

        let idsOfStoredIncomingDefaults = try listStoredObjects().map(\.id)
        XCTAssertEqual(idsOfStoredIncomingDefaults, ["New ID"])
    }

    func testFetchAll_doesntOverwriteNewerIncomingDefaultsForTheSameEmail() async throws {
        storeStubbedObject(id: "Old ID", time: .distantFuture)

        let stubbedResponse = GetIncomingDefaultsResponse(
            code: 0,
            incomingDefaults: [
                IncomingDefaultDTO(
                    email: emailAddress,
                    id: "New ID",
                    location: location,
                    time: .distantPast
                )
            ],
            total: 1
        )

        apiService.requestDecodableStub.bodyIs { _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success(stubbedResponse))
        }

        try await sut.fetchAll(location: location)

        let idsOfStoredIncomingDefaults = try listStoredObjects().map(\.id)
        XCTAssertEqual(idsOfStoredIncomingDefaults, ["Old ID"])
    }

    func testSave_overwritesExistingOlderIncomingDefaultsForTheSameEmail() throws {
        storeStubbedObject(id: "Old ID", time: .distantPast)

        let newIncomingDefault = IncomingDefaultDTO(
            email: emailAddress,
            id: "New ID",
            location: location,
            time: .distantFuture
        )
        try sut.save(dto: newIncomingDefault)

        let idsOfStoredIncomingDefaults = try listStoredObjects().map(\.id)
        XCTAssertEqual(idsOfStoredIncomingDefaults, ["New ID"])
    }

    func testSave_doesNotOverwriteExistingNewerIncomingDefaultsForTheSameEmail() throws {
        storeStubbedObject(id: "Old ID", time: .distantFuture)

        let newIncomingDefault = IncomingDefaultDTO(
            email: emailAddress,
            id: "New ID",
            location: location,
            time: .distantPast
        )
        try sut.save(dto: newIncomingDefault)

        let idsOfStoredIncomingDefaults = try listStoredObjects().map(\.id)
        XCTAssertEqual(idsOfStoredIncomingDefaults, ["Old ID"])
    }

    func testSave_overwritesExistingIncomingDefaultsWithNilIDForTheSameEmail() throws {
        storeStubbedObject(id: nil, time: .distantFuture)

        let newIncomingDefault = IncomingDefaultDTO(
            email: emailAddress,
            id: "New ID",
            location: location,
            time: .distantFuture
        )
        try sut.save(dto: newIncomingDefault)

        let idsOfStoredIncomingDefaults = try listStoredObjects().map(\.id)
        XCTAssertEqual(idsOfStoredIncomingDefaults, ["New ID"])
    }

    func testHardDelete_removesExistingIncomingDefaults() throws {
        let incomingDefaultID = "the ID"
        storeStubbedObject(id: incomingDefaultID, time: .distantFuture)
        try sut.hardDelete(query: .id(incomingDefaultID))

        XCTAssertEqual(try listStoredObjects().count, 0)
    }

    func testPerformLocalUpdate_replacesExistingObject_thusClearingID() throws {
        let id = String.randomString(16)

        storeStubbedObject(id: id, time: .distantPast)

        try sut.performLocalUpdate(emailAddress: emailAddress, newLocation: .blocked)

        XCTAssertEqual(apiService.requestDecodableStub.callCounter, 0)

        let updated = try XCTUnwrap(listStoredObjects().first)
        XCTAssertEqual(updated.email, emailAddress)
        XCTAssertEqual(updated.location, .blocked)
        XCTAssertNil(updated.id)
    }

    func testPerformLocalUpdate_createsNewObjectIfNeeded() throws {
        try sut.performLocalUpdate(emailAddress: emailAddress, newLocation: .blocked)

        XCTAssertEqual(apiService.requestDecodableStub.callCounter, 0)

        let updated = try XCTUnwrap(listStoredObjects().first)
        XCTAssertEqual(updated.email, emailAddress)
        XCTAssertEqual(updated.location, .blocked)
        XCTAssertNil(updated.id)
    }

    func testPerformRemoteUpdate_performsAPIRequestAndUpdatesLocalDataIfItExists() async throws {
        storeStubbedObject(id: nil, time: .distantPast)

        let stubbedResponse = AddIncomingDefaultsResponse(
            code: 0,
            incomingDefault: .init(email: emailAddress, id: "New ID", location: .blocked, time: .distantFuture),
            undoToken: UndoTokenData(token: "", tokenValidTime: 0)
        )
        apiService.requestDecodableStub.bodyIs { _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success(stubbedResponse))
        }

        try await sut.performRemoteUpdate(emailAddress: emailAddress, newLocation: .blocked)

        XCTAssertEqual(apiService.requestDecodableStub.callCounter, 1)

        let updated = try XCTUnwrap(listStoredObjects().first)
        XCTAssertEqual(updated.id, "New ID")
        XCTAssertEqual(updated.email, emailAddress)
        XCTAssertEqual(updated.location, .blocked)
        XCTAssertEqual(updated.time.timeIntervalSince1970, Date.distantFuture.timeIntervalSince1970, accuracy: 1.0)
    }

    func testPerformRemoteUpdate_performsAPIRequestAndDoesntCreateNewLocalData() async throws {
        let id = String.randomString(16)

        let stubbedResponse = AddIncomingDefaultsResponse(
            code: 0,
            incomingDefault: .init(email: emailAddress, id: id, location: .blocked, time: .distantFuture),
            undoToken: UndoTokenData(token: "", tokenValidTime: 0)
        )
        apiService.requestDecodableStub.bodyIs { _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success(stubbedResponse))
        }

        try await sut.performRemoteUpdate(emailAddress: emailAddress, newLocation: .blocked)

        XCTAssertEqual(apiService.requestDecodableStub.callCounter, 1)
        XCTAssertEqual(try listStoredObjects().count, 0)
    }

    // MARK: deletion

    func testSoftDelete_doesntActuallyRemoveObjects() throws {
        let id = String.randomString(16)

        storeStubbedObject(id: id, time: .distantPast)

        try sut.softDelete(query: .id(id))

        let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.Attribute.entityName)

        let existsAndIsSoftDeleted = try contextProvider.read { context in
            guard let incomingDefault = try context.fetch(fetchRequest).first else {
                return false
            }

            return incomingDefault.isSoftDeleted
        }

        XCTAssert(existsAndIsSoftDeleted)
    }

    func testSoftDelete_preventsListLocalFromReturningObjects() throws {
        let id = String.randomString(16)

        storeStubbedObject(id: id, time: .distantPast)

        XCTAssertNotEqual(try sut.listLocal(query: .location(location)), [])

        try sut.softDelete(query: .id(id))

        XCTAssertEqual(try sut.listLocal(query: .location(location)), [])
    }

    func testPerformRemoteDeletion_sendsIdsOfMatchingObjectsIncludingSoftDeleted() async throws {
        let id = String.randomString(16)

        storeStubbedObject(id: id, time: .distantPast)

        apiService.requestDecodableStub.bodyIs { _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success(DeleteIncomingDefaultsResponse()))
        }

        try await sut.performRemoteDeletion(emailAddress: emailAddress)

        XCTAssertEqual(apiService.requestDecodableStub.callCounter, 1)
        let deletionCall = try XCTUnwrap(apiService.requestDecodableStub.lastArguments)
        let parameters = try XCTUnwrap(deletionCall.a3 as? [String: Any])
        let deletedIDs = try XCTUnwrap(parameters["IDs"] as? [String])
        XCTAssertEqual(deletedIDs, [id])
    }

    func testPerformRemoteDeletion_doesntHardDeleteObjects() async throws {
        storeStubbedObject(id: nil, time: .distantPast)

        apiService.requestDecodableStub.bodyIs { _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success(DeleteIncomingDefaultsResponse()))
        }

        try await sut.performRemoteDeletion(emailAddress: emailAddress)

        XCTAssertNotEqual(try listStoredObjects(), [])
    }

    private func storeStubbedObject(id: String?, time: Date) {
        contextProvider.performAndWaitOnRootSavingContext { context in
            let incomingDefault = IncomingDefault(context: context)
            incomingDefault.email = self.emailAddress
            incomingDefault.id = id
            incomingDefault.location = "\(self.location.rawValue)"
            incomingDefault.time = time
            incomingDefault.userID = self.userInfo.userId
            _ = context.saveUpstreamIfNeeded()
        }
    }

    private func listStoredObjects() throws -> [IncomingDefaultEntity] {
        let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.Attribute.entityName)

        return try contextProvider.read { context in
            try context.fetch(fetchRequest).map(IncomingDefaultEntity.init)
        }
    }
}

private extension IncomingDefaultService {
    func fetchAll(location: IncomingDefaultsAPI.Location) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.fetchAll(location: location) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func performRemoteUpdate(emailAddress: String, newLocation: IncomingDefaultsAPI.Location) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.performRemoteUpdate(emailAddress: emailAddress, newLocation: newLocation) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func performRemoteDeletion(emailAddress: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.performRemoteDeletion(emailAddress: emailAddress) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
