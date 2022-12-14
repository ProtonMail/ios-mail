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
import ProtonCore_Services

typealias FetchEmailAddressesPublicKeyUseCase = NewUseCase<[String: KeysResponse], FetchEmailAddressesPublicKey.Params>

final class FetchEmailAddressesPublicKey: FetchEmailAddressesPublicKeyUseCase {
    private let dependencies: Dependencies
    private let serialQueue = DispatchQueue(label: "me.proton.mail.FetchEmailAddressesPublicKey")

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Params, callback: @escaping Callback) {
        var keysByEmail = [String: KeysResponse]()
        var requestError = [Error]()

        let uniqueEmails = Array(Set(params.emails))
        let group = DispatchGroup()
        uniqueEmails.forEach { email in
            let request = UserEmailPubKeys(email: email)
            group.enter()
            dependencies.apiService.perform(request: request) { [weak self] _, result in
                guard let self = self else { return }
                self.serialQueue.sync {
                    switch result {
                    case .success(let response):
                        let keysResponse = self.parseResponse(response: response)
                        keysByEmail[email] = keysResponse
                    case .failure(let error):
                        requestError.append(error)
                    }
                }
                group.leave()
            }
        }
        group.notify(queue: executionQueue) {
            if let error = requestError.first {
                callback(.failure(error))
            } else {
                callback(.success(keysByEmail))
            }
        }
    }

    private func parseResponse(response: [String: Any]) -> KeysResponse {
        let keysResponse = KeysResponse()
        _ = keysResponse.ParseResponse(response)
        return keysResponse
    }
}

extension FetchEmailAddressesPublicKey {

    struct Params {
        let emails: [String]
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
