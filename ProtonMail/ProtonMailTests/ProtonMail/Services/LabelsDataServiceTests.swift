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
import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

final class LabelsDataServiceTests: XCTestCase {
    private var user: UserManager!
    private var mockApiService: APIServiceMock!
    private var mockContextProvider: MockCoreDataContextProvider!
    private var userID = UUID().uuidString
    private var sut: LabelsDataService!

    override func setUp() {
        super.setUp()
        mockApiService = APIServiceMock()
        mockContextProvider = MockCoreDataContextProvider()

        let globalContainer = GlobalContainer()
        globalContainer.contextProviderFactory.register { self.mockContextProvider }
        user = UserManager(api: mockApiService, globalContainer: globalContainer)

        sut = LabelsDataService(userID: UserID(userID), dependencies: user.container)
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
        user = nil
        mockApiService = nil
        mockContextProvider = nil
    }

    func testFetchV4Labels_overwritesLocalFoldersAndLabelsWithOnesReturnedByBackend() throws {
        mockApiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, _, completion in
            let type = Int(String(path.last!))!

            let id: String
            switch PMLabelType(rawValue: type) {
            case .label:
                id = "new custom label"
            case .folder:
                id = "new custom folder"
            default:
                fatalError("Unexpected call to \(path)")
            }

            let labelData: [[String: Any]] = [
                ["ID": id, "Type": type]
            ]

            completion(nil, .success(["Labels": labelData]))
        }

        mockContextProvider.performAndWaitOnRootSavingContext { context in
            let oldCustomLabel = Label(context: context)
            oldCustomLabel.labelID = "old custom label"
            oldCustomLabel.type = PMLabelType.label.rawValue as NSNumber
            oldCustomLabel.userID = self.userID

            XCTAssertNil(context.saveUpstreamIfNeeded())
        }

        let exp = expectation(description: "call has completed")

        sut.fetchV4Labels { result in
            XCTAssertNil(result.error)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let newLabels = sut.getAllLabels(of: .all)
        let menuLabels: [MenuLabel] = Array(labels: newLabels, previousRawData: [])
        let (labelItems, folderItems) = menuLabels.sortoutData()

        XCTAssertEqual(labelItems.map(\.location.rawLabelID), ["new custom label"])
        XCTAssertEqual(folderItems.map(\.location.rawLabelID), ["new custom folder"])
    }

    func testFetchV4Labels_regeneratesSystemFolders() throws {
        mockApiService.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success(["Labels": []]))
        }

        mockContextProvider.performAndWaitOnRootSavingContext { context in
            let inboxFolder = Label(context: context)
            inboxFolder.labelID = Message.Location.inbox.rawValue

            XCTAssertNil(context.saveUpstreamIfNeeded())
        }

        let exp = expectation(description: "call has completed")

        sut.fetchV4Labels { result in
            XCTAssertNil(result.error)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let systemFolderFetchRequest = NSFetchRequest<Label>(entityName: Label.Attributes.entityName)
        systemFolderFetchRequest.predicate = NSPredicate(format: "type == 0")

        let systemFolderIDs = try mockContextProvider.read { context in
            let systemFolders = try context.fetch(systemFolderFetchRequest)
            return systemFolders.map(\.labelID)
        }

        XCTAssertEqual(systemFolderIDs.sorted(), LabelsDataService.defaultFolderIDs.sorted())
    }

    func testFetchV4Labels_whenAPIFailed_shouldNotWipeDBData() throws {
        mockApiService.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .failure(NSError(domain: "test.proton", code: 998)))
        }

        mockContextProvider.performAndWaitOnRootSavingContext { context in
            let inboxFolder = Label(context: context)
            inboxFolder.labelID = Message.Location.inbox.rawValue

            XCTAssertNil(context.saveUpstreamIfNeeded())
        }

        let exp = expectation(description: "call has completed")

        sut.fetchV4Labels { result in
            XCTAssertNotNil(result.error)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let systemFolderFetchRequest = NSFetchRequest<Label>(entityName: Label.Attributes.entityName)
        systemFolderFetchRequest.predicate = NSPredicate(format: "type == 0")

        let systemFolderIDs = try mockContextProvider.read { context in
            let systemFolders = try context.fetch(systemFolderFetchRequest)
            return systemFolders.map(\.labelID)
        }

        XCTAssertEqual(systemFolderIDs.sorted(), [Message.Location.inbox.rawValue])
    }
}
