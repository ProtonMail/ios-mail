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
        contextProvider.performAndWaitOnRootSavingContext { context in
            let incomingDefault = IncomingDefault(context: context)
            incomingDefault.email = self.emailAddress
            incomingDefault.id = "Old ID"
            incomingDefault.location = "\(self.location.rawValue)"
            incomingDefault.time = .distantPast
            incomingDefault.userID = self.userInfo.userId
        }

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

        let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.Attribute.entityName)

        let idsOfStoredIncomingDefaults = try contextProvider.read { context in
            try context.fetch(fetchRequest).map(\.id)
        }

        XCTAssertEqual(idsOfStoredIncomingDefaults, ["New ID"])
    }

    func testFetchAll_doesntOverwriteNewerIncomingDefaultsForTheSameEmail() async throws {
        contextProvider.performAndWaitOnRootSavingContext { context in
            let incomingDefault = IncomingDefault(context: context)
            incomingDefault.email = self.emailAddress
            incomingDefault.id = "Old ID"
            incomingDefault.location = "\(self.location.rawValue)"
            incomingDefault.time = .distantFuture
            incomingDefault.userID = self.userInfo.userId
        }

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

        let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.Attribute.entityName)

        let idsOfStoredIncomingDefaults = try contextProvider.read { context in
            try context.fetch(fetchRequest).map(\.id)
        }

        XCTAssertEqual(idsOfStoredIncomingDefaults, ["Old ID"])
    }

    func testSave_overwritesExistingOlderIncomingDefaultsForTheSameEmail() throws {
        contextProvider.performAndWaitOnRootSavingContext { context in
            let incomingDefault = IncomingDefault(context: context)
            incomingDefault.email = self.emailAddress
            incomingDefault.id = "Old ID"
            incomingDefault.location = "\(self.location.rawValue)"
            incomingDefault.time = .distantPast
            incomingDefault.userID = self.userInfo.userId
            _ = context.saveUpstreamIfNeeded()
        }

        let newIncomingDefault = IncomingDefaultDTO(
            email: emailAddress,
            id: "New ID",
            location: location,
            time: .distantFuture
        )
        try sut.save(dto: newIncomingDefault)

        let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.Attribute.entityName)
        let idsOfStoredIncomingDefaults = try contextProvider.read { context in
            try context.fetch(fetchRequest).map(\.id)
        }
        XCTAssertEqual(idsOfStoredIncomingDefaults, ["New ID"])
    }

    func testSave_doesNotOverwriteExistingNewerIncomingDefaultsForTheSameEmail() throws {
        contextProvider.performAndWaitOnRootSavingContext { context in
            let incomingDefault = IncomingDefault(context: context)
            incomingDefault.email = self.emailAddress
            incomingDefault.id = "Old ID"
            incomingDefault.location = "\(self.location.rawValue)"
            incomingDefault.time = .distantFuture
            incomingDefault.userID = self.userInfo.userId
            _ = context.saveUpstreamIfNeeded()
        }

        let newIncomingDefault = IncomingDefaultDTO(
            email: emailAddress,
            id: "New ID",
            location: location,
            time: .distantPast
        )
        try sut.save(dto: newIncomingDefault)

        let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.Attribute.entityName)
        let idsOfStoredIncomingDefaults = try contextProvider.read { context in
            try context.fetch(fetchRequest).map(\.id)
        }
        XCTAssertEqual(idsOfStoredIncomingDefaults, ["Old ID"])
    }

    func testSave_overwritesExistingIncomingDefaultsWithNilIDForTheSameEmail() throws {
        contextProvider.performAndWaitOnRootSavingContext { context in
            let incomingDefault = IncomingDefault(context: context)
            incomingDefault.email = self.emailAddress
            incomingDefault.id = nil
            incomingDefault.location = "\(self.location.rawValue)"
            incomingDefault.time = .distantFuture
            incomingDefault.userID = self.userInfo.userId
            _ = context.saveUpstreamIfNeeded()
        }

        let newIncomingDefault = IncomingDefaultDTO(
            email: emailAddress,
            id: "New ID",
            location: location,
            time: .distantFuture
        )
        try sut.save(dto: newIncomingDefault)

        let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.Attribute.entityName)
        let idsOfStoredIncomingDefaults = try contextProvider.read { context in
            try context.fetch(fetchRequest).map(\.id)
        }
        XCTAssertEqual(idsOfStoredIncomingDefaults, ["New ID"])
    }

    func testDelete_removesExistingIncomingDefaults() throws {
        let incomingDefaultID = "the ID"
        contextProvider.performAndWaitOnRootSavingContext { context in
            let incomingDefault = IncomingDefault(context: context)
            incomingDefault.email = self.emailAddress
            incomingDefault.id = incomingDefaultID
            incomingDefault.location = "\(self.location.rawValue)"
            incomingDefault.time = .distantFuture
            incomingDefault.userID = self.userInfo.userId
            _ = context.saveUpstreamIfNeeded()
        }
        try sut.delete(incomingDefaultID: incomingDefaultID)

        let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.Attribute.entityName)
        let numStoredIncomingDefaults = try contextProvider.read { context in
            try context.fetch(fetchRequest).count
        }
        XCTAssertEqual(numStoredIncomingDefaults, 0)
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
}
