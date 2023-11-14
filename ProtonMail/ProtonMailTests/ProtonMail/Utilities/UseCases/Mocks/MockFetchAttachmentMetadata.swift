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

import Foundation
@testable import ProtonMail

final class MockFetchAttachmentMetadata: FetchAttachmentMetadataUseCase {
    let uuid: UUID = UUID()
    private(set) var executeWasCalled: Bool = false
    var result: Result<AttachmentMetadata, Error> = .success(.init(id: AttachmentID(String.randomString(100)),
                                                                   keyPacket: String.randomString(100)))

    override func execute(params: FetchAttachmentMetadata.Params, 
                          callback: @escaping UseCase<AttachmentMetadata, FetchAttachmentMetadata.Params>.Callback) {
        executeWasCalled = true
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.3) {
            callback(self.result)
        }
    }
}
