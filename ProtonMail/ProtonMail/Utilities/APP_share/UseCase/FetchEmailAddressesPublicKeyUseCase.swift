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
    private let serialQueue = DispatchQueue(label: "com.protonmail.FetchEmailAddressesPublicKey")

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Params, callback: @escaping Callback) {
        var keysByEmail = [String: KeysResponse]()
        var requestError = [NSError]()

        let uniqueEmails = Array(Set(params.emails))
        let group = DispatchGroup()
        uniqueEmails.forEach { email in
            let request = UserEmailPubKeys(email: email)
            group.enter()
            dependencies.apiService.GET(request) { [weak self] _, response, error in
                guard let self = self else { return }
                self.serialQueue.sync {
                    switch self.parseResponse(response: response, error: error) {
                    case .success(let keysResponse):
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

    private func parseResponse(response: [String: Any]?, error: NSError?) -> Result<KeysResponse, NSError> {
        if let error = error {
            return .failure(error)
        }
        let keysResponse = KeysResponse()
        _ = keysResponse.ParseResponse(response)
        return .success(keysResponse)
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
