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
import ProtonCoreServices
import enum ProtonCoreUtilities.Either

protocol MessageActionUpdateUseCase {
    typealias MessageURI = String
    func execute(ids: Either<[MessageURI], [MessageID]>, action: MessageActionUpdate.Action) async throws
}

extension MessageActionUpdate {
    enum Action: String {
        case read, unread, delete
    }

    final class Dependencies {
        let apiService: APIService
        let contextProvider: CoreDataContextProviderProtocol

        init(apiService: APIService, contextProvider: CoreDataContextProviderProtocol) {
            self.apiService = apiService
            self.contextProvider = contextProvider
        }
    }
}

final class MessageActionUpdate: MessageActionUpdateUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func execute(ids: Either<[MessageURI], [MessageID]>, action: Action) async throws {
        let rawMessageIDs: [String]
        switch ids {
        case .left(let objectIDs):
            rawMessageIDs = try getMessageID(from: objectIDs)
        case .right(let messageIDs):
            rawMessageIDs = messageIDs.map(\.rawValue)
        }
        if rawMessageIDs.isEmpty {
            if !ProcessInfo.isRunningUnitTests {
                PMAssertionFailure("Raw messageIDs is empty, executing action: \(action)")
            }
            return
        }
        try await updateMessages(ids: rawMessageIDs, action: action)
    }

    private func getMessageID(from objectIDs: [MessageURI]) throws -> [String] {
        try dependencies.contextProvider.read { context in
            try objectIDs.compactMap({ uri in
                guard
                    let objectID = dependencies.contextProvider.managedObjectIDForURIRepresentation(uri),
                    let message = try context.existingObject(with: objectID) as? Message
                else { return nil }
                return message.messageID
            })
        }
    }

    private func updateMessages(ids: [String], action: Action) async throws {
        let request = MessageActionRequest(action: action.rawValue, ids: ids)
        let result: GeneralMultipleResponse = try await dependencies.apiService.perform(request: request).1
        if let errorResponse = result.responses.first(where: { responses in
            let succeedCodes = [APIErrorCode.resourceDoesNotExist, APIErrorCode.responseOK]
            guard !succeedCodes.contains(responses.response.code) else { return false }
            return responses.response.error != nil
        }) {
            let error = NSError(
                domain: "ch.protonmail.protonmail.message.action.update",
                code: errorResponse.response.code,
                localizedDescription: errorResponse.response.error ?? "Unknown empty error"
            )
            throw error
        }
    }
}
