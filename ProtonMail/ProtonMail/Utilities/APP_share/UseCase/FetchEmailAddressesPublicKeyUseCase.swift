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
import ProtonCoreServices

// sourcery: mock
protocol FetchEmailAddressesPublicKeyUseCase: Sendable {
    func execute(email: String) async throws -> KeysResponse
}

extension FetchEmailAddressesPublicKeyUseCase {
    func execute(emails: [String]) async throws -> [String: KeysResponse] {
        let uniqueEmails = Set(emails)
        return try await withThrowingTaskGroup(of: (String, KeysResponse).self) { group in
            for email in uniqueEmails {
                group.addTask {
                    let response = try await self.execute(email: email)
                    return (email, response)
                }
            }

            var results: [String: KeysResponse] = [:]
            for try await (email, response) in group {
                results[email] = response
            }

            return results
        }
    }
}

struct FetchEmailAddressesPublicKey: FetchEmailAddressesPublicKeyUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func execute(email: String) async throws -> KeysResponse {
        let request = UserEmailPubKeys(email: email)
        let response = await dependencies.apiService.perform(request: request, response: KeysResponse()).1

        if let error = response.error {
            throw error
        } else {
            return response
        }
    }
}

extension FetchEmailAddressesPublicKey {

    struct Dependencies {
        let apiService: APIService

        init(apiService: APIService) {
            self.apiService = apiService
        }
    }
}
