// Copyright (c) 2022 Proton Technologies AG
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
import protocol ProtonCoreDoh.DoHInterface
import protocol ProtonCoreServices.APIService
import ProtonCoreNetworking

// sourcery: mock
protocol FetchAttachmentMetadataUseCase {
    func execution(params: FetchAttachmentMetadata.Params) async throws -> AttachmentMetadata
}

final class FetchAttachmentMetadata: FetchAttachmentMetadataUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func execution(params: Params) async throws -> AttachmentMetadata {
        let request = AttachmentMetadataRequest(attID: params.attachmentID.rawValue)
        let response = await dependencies.apiService.perform(request: request, response: AttachmentMetadataResponse())
        if let keyPacket = response.1.keyPacket {
            return AttachmentMetadata(id: params.attachmentID, keyPacket: keyPacket)
        } else {
            throw FetchAttachmentMetadataError(attachmentID: params.attachmentID)
        }
    }
}

extension FetchAttachmentMetadata {
    struct Params {
        let attachmentID: AttachmentID
    }

    struct Dependencies {
        let apiService: APIService

        init(apiService: APIService) {
            self.apiService = apiService
        }
    }
}

struct AttachmentMetadata: Decodable {
    let id: AttachmentID
    let keyPacket: String
}

struct FetchAttachmentMetadataError: LocalizedError {
    let attachmentID: AttachmentID

    var errorDescription: String? {
        "FetchAttachmentMetadataError: Key Packets Not Found"
    }
}
