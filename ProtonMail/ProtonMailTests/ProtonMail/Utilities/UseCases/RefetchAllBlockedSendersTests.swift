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

final class RefetchAllBlockedSendersTests: XCTestCase {
    private var apiService: APIServiceMock!
    private var contextProvider: MockCoreDataContextProvider!
    private var sut: RefetchAllBlockedSenders!

    private var userInfo: UserInfo {
        .dummy
    }

    private let stubbedAPIPages: [[IncomingDefaultDTO]] = (0..<3).map { _ in
        (0..<3).map { _ in
            IncomingDefaultDTO(
                email: String.randomString(10),
                id: String.randomString(10),
                location: .blocked,
                time: .distantPast
            )
        }
    }

    private var allResources: [IncomingDefaultDTO] {
        stubbedAPIPages.flatMap { $0 }
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        apiService = APIServiceMock()
        contextProvider = MockCoreDataContextProvider()

        let incomingDefaultService = IncomingDefaultService(
            dependencies: .init(apiService: apiService, contextProvider: contextProvider, userInfo: userInfo)
        )
        sut = RefetchAllBlockedSenders(dependencies: .init(incomingDefaultService: incomingDefaultService))
    }

    override func tearDownWithError() throws {
        sut = nil
        apiService = nil
        contextProvider = nil

        try super.tearDownWithError()
    }

    func testFetchesAllPagesAndStoresThemInDatabase() async throws {
        apiService.requestDecodableStub.bodyIs { _, _, _, params, _, _, _, _, _, _, completion in
            let parameters = params as! [String: Any]
            let requestedPageNumber = parameters["Page"] as! Int
            let requestedResources = self.stubbedAPIPages[requestedPageNumber]
            let response = GetIncomingDefaultsResponse(
                code: 0,
                incomingDefaults: requestedResources,
                total: self.allResources.count
            )
            completion(nil, .success(response))
        }

        try await sut.execute()

        XCTAssertEqual(apiService.requestDecodableStub.callCounter, 3)

        try contextProvider.read { context in
            let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.entity().name!)
            let incomingDefaults = try context.fetch(fetchRequest)

            for resource in allResources {
                let matchingStoredObject = try XCTUnwrap(incomingDefaults.first { $0.id == resource.id })
                XCTAssertEqual(resource.email, matchingStoredObject.email)
                XCTAssertEqual("\(resource.location.rawValue)", matchingStoredObject.location)
                XCTAssertEqual(resource.time, matchingStoredObject.time)
            }
        }
    }

    func testWhenOneOfTheRequestsFails_storesResourcesFetchedBeforeThat() async throws {
        apiService.requestDecodableStub.bodyIs { _, _, _, params, _, _, _, _, _, _, completion in
            let parameters = params as! [String: Any]
            let requestedPageNumber = parameters["Page"] as! Int

            let stubbedResult: Result<Any, NSError>
            if requestedPageNumber == 0 {
                stubbedResult = .success(
                    GetIncomingDefaultsResponse(
                        code: 0,
                        incomingDefaults: self.stubbedAPIPages[0],
                        total: self.allResources.count
                    )
                )
            } else {
                stubbedResult = .failure(NSError.badResponse())
            }
            completion(nil, stubbedResult)
        }

        do {
            try await sut.execute()
            XCTFail("Error expected")
        } catch {
        }

        XCTAssertEqual(apiService.requestDecodableStub.callCounter, 2)

        try contextProvider.read { context in
            let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.entity().name!)
            let incomingDefaults = try context.fetch(fetchRequest)

            for resource in stubbedAPIPages[0] {
                XCTAssert(incomingDefaults.contains { $0.id == resource.id })
            }

            for resource in stubbedAPIPages[1] + stubbedAPIPages[2] {
                XCTAssertFalse(incomingDefaults.contains { $0.id == resource.id })
            }
        }
    }

    func testRemovesPreviousEntitiesBeforeFetching() async throws {
        apiService.requestDecodableStub.bodyIs { _, _, _, _, _, _, _, _, _, _, completion in
            let response = GetIncomingDefaultsResponse(code: 0, incomingDefaults: [], total: 0)
            completion(nil, .success(response))
        }

        contextProvider.performAndWaitOnRootSavingContext { context in
            let incomingDefault = IncomingDefault(context: context)
            incomingDefault.id = "Old default"
            incomingDefault.location = "\(IncomingDefaultsAPI.Location.blocked.rawValue)"
            incomingDefault.time = .distantPast
            incomingDefault.userID = self.userInfo.userId
        }

        let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.Attribute.entityName)

        let countBeforeExecution = try contextProvider.read { context in
            try context.count(for: fetchRequest)
        }
        XCTAssertEqual(countBeforeExecution, 1)

        try await sut.execute()

        let countAfterExecution = try contextProvider.read { context in
            try context.count(for: fetchRequest)
        }
        XCTAssertEqual(countAfterExecution, 0)
    }
}

private extension RefetchAllBlockedSenders {
    func execute() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.execute { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
