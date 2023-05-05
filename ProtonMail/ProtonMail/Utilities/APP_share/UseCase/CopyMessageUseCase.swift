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

import Foundation

// sourcery: mock
protocol CopyMessageUseCase {
    typealias CopyOutput = (Message, [MimeAttachment]?)

    func execute(parameters: CopyMessage.Parameters) throws -> CopyOutput
}

class CopyMessage: CopyMessageUseCase {
    let dependencies: Dependencies
    private(set) weak var userDataSource: UserDataSource?

    init(dependencies: Dependencies, userDataSource: UserDataSource) {
        self.dependencies = dependencies
        self.userDataSource = userDataSource
    }

    func execute(parameters: Parameters) throws -> CopyOutput {
        var result: Result<CopyOutput, Error>!

        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            guard let originalMessage = Message.messageForMessageID(parameters.messageID.rawValue, in: context) else {
                result = .failure(CopyMessageError.messageNotFoundForGivenMessageID)
                return
            }

            do {
                let copyOutput = try self.copy(
                    message: originalMessage,
                    copyAttachments: parameters.copyAttachments,
                    context: context
                )
                result = .success(copyOutput)
            } catch {
                result = .failure(error)
            }
        }

        return try result.get()
    }
}

extension CopyMessage {
    struct Dependencies {
        let contextProvider: CoreDataContextProviderProtocol
        let messageDecrypter: MessageDecrypterProtocol
    }

    struct Parameters {
        let copyAttachments: Bool
        let messageID: MessageID
    }
}

enum CopyMessageError: Swift.Error {
    case messageNotFoundForGivenMessageID
}
