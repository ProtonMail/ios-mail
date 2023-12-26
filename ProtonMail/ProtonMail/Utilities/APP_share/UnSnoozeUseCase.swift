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

protocol UnSnoozeUseCase {
    func execute(conversationID: ConversationID) async throws
}

final class UnSnooze: UnSnoozeUseCase {
    let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func execute(conversationID: ConversationID) async throws {
        let request = ConversationUnSnoozeRequest(conversationIDs: [conversationID])
        let result: GeneralMultipleResponse = try await dependencies.apiService.perform(request: request).1
        guard let response = result.responses.first,
              response.response.code == APIErrorCode.responseOK else {
            throw parseError(from: result.responses.first)
        }
    }

    private func parseError(from response: GeneralMultipleResponse.Responses?) -> Error {
        if let error = response?.response.error {
            return Error.responseError(error)
        } else {
            let responseCode = response?.response.code ?? -999
            return Error.unexpectedError(responseCode)
        }
    }
}

extension UnSnooze {
    struct Dependencies {
        let apiService: APIService
    }

    enum Error: LocalizedError {
        case responseError(String)
        case unexpectedError(Int)

        var errorDescription: String? {
            switch self {
            case .responseError(let string):
                return string
            case .unexpectedError(let code):
                return "\(LocalString._unknown_error) - \(code)"
            }
        }
    }
}
