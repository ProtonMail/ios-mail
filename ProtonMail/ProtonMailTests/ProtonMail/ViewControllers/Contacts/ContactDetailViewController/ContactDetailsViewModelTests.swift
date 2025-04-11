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

import ProtonCoreTestingToolkitUnitTestsServices
import XCTest

@testable import ProtonMail

final class ContactDetailsViewModelTests: XCTestCase {
    private var sut: ContactDetailsViewModel!
    private var apiService: APIServiceMock!

    override func setUpWithError() throws {
        try super.setUpWithError()

        apiService = APIServiceMock()

        let contact = ContactEntity.make(contactID: "foo", name: "John something", isDownloaded: false)
        let user = UserManager(api: apiService)
        let coreDataService = CoreDataService(container: MockCoreDataStore.testPersistentContainer)

        sut = ContactDetailsViewModel(contact: contact, dependencies: .init(user: user, coreDataService: coreDataService, contactService: user.contactService))
    }

    override func tearDownWithError() throws {
        sut = nil
        apiService = nil

        try super.tearDownWithError()
    }

    func testGetDetails_overwritesTheCurrentContactProperty() async throws {
        apiService.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, _, completion in
            let response: [String: Any] = [
                "Contact": [
                    "ID": "bar",
                    "Name": "John Doe"
                ]
            ]
            completion(nil, .success(response))
        }

        try await sut.getDetails {}

        XCTAssertEqual(sut.contact.contactID, "bar")
        XCTAssertEqual(sut.contact.name, "John Doe")
    }
}
