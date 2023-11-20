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

import ProtonCoreTestingToolkit
@testable import ProtonMail

final class MockFetchAttachmentMetadata: FetchAttachmentMetadataUseCase {
    let uuid: UUID = UUID()
    private(set) var executeWasCalled: Bool = false
    var result: Result<AttachmentMetadata, Error> = .success(.init(id: AttachmentID(String.randomString(100)),
                                                                   keyPacket: String.randomString(100)))

    init() {
        super.init(dependencies: .init(apiService: APIServiceMock()))
    }
    override func execution(params: Params) async throws -> AttachmentMetadata {
        executeWasCalled = true
        return try self.result.get()
    }
}
