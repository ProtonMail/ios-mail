// Copyright (c) 2022 Proton AG
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
import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

final class LabelsDataServiceTests: XCTestCase {
    private var mockApiService: APIServiceMock!
    private var mockContextProvider: MockCoreDataContextProvider!
    private var userID = UUID().uuidString
    private var sut: LabelsDataService!

    override func setUp() {
        super.setUp()
        mockApiService = APIServiceMock()
        mockContextProvider = MockCoreDataContextProvider()
        let mockLastUpdatedStore = MockLastUpdatedStore()
        let mockCacheService = MockCacheServiceProtocol()

        sut = LabelsDataService(api: mockApiService,
                                userID: UserID(userID),
                                contextProvider: mockContextProvider,
                                lastUpdatedStore: mockLastUpdatedStore,
                                cacheService: mockCacheService)
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
        mockApiService = nil
        mockContextProvider = nil
    }

    func testRemoveDeletedLabelAndFolder() throws {
        let context = mockContextProvider.viewContext
        try prepareTestLabelData(context: context)
        let expectation1 = expectation(description: "Closure is called")

        sut.cleanLabelsAndFolders(except: ["1", "3"]) {
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(mockApiService.requestJSONStub.wasNotCalled)

        let request = NSFetchRequest<Label>(entityName: Label.Attributes.entityName)
        request.predicate = NSPredicate(
            format: "%K == %@ AND (%K == 1 OR %K == 3)",
            Label.Attributes.userID,
            userID,
            Label.Attributes.type,
            Label.Attributes.type)
        let result = try context.fetch(request)
        let ids = result.compactMap { $0.labelID }.sorted()
        XCTAssertTrue(result.count == 2)
        XCTAssertEqual(ids, ["1", "3"])

        let groupRequest = NSFetchRequest<Label>(entityName: Label.Attributes.entityName)
        groupRequest.predicate = NSPredicate(
            format: "%K == %@ AND %K == 2",
            Label.Attributes.userID,
            userID,
            Label.Attributes.type)
        let result2 = try context.fetch(groupRequest)
        XCTAssertEqual(result2.count, 1)
    }
}

extension LabelsDataServiceTests {
    private func prepareTestLabelData(context: NSManagedObjectContext) throws {
        let label = Label(context: context)
        label.labelID = "1"
        label.type = NSNumber(1)
        label.userID = userID

        let groupLabel = Label(context: context)
        groupLabel.labelID = "2"
        groupLabel.type = NSNumber(2)
        groupLabel.userID = userID

        let folderLabel = Label(context: context)
        folderLabel.labelID = "3"
        folderLabel.type = NSNumber(3)
        folderLabel.userID = userID

        let folderLabel2 = Label(context: context)
        folderLabel2.labelID = "4"
        folderLabel2.type = NSNumber(3)
        folderLabel2.userID = userID
        try context.save()
    }
}
