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

import Crypto
import ProtonCore_DataModel
import ProtonCore_Log

protocol FetchVerificationKeysUseCase: UseCase {
    typealias Output = (pinnedKeys: [Data], keysResponse: KeysResponse?)

    func execute(email: String, completion: @escaping UseCaseResult<Output>)
}

final class FetchVerificationKeys: FetchVerificationKeysUseCase {
    private let dependencies: Dependencies
    private let userAddresses: [Address]

    init(dependencies: Dependencies, userAddresses: [Address]) {
        self.dependencies = dependencies
        self.userAddresses = userAddresses
    }

    func execute(email: String, completion: @escaping UseCaseResult<Output>) {
        if let userAddress = userAddresses.first(where: { $0.email == email }) {
            let validKeys = nonCompromisedUserAddressKeys(belongingTo: userAddress)
            completion(.success((validKeys, nil)))
        } else {
            fetchContactPinnedKeys(email: email, completion: completion)
        }
    }

    private func nonCompromisedUserAddressKeys(belongingTo address: Address) -> [Data] {
        address.keys
            .filter { $0.flags.contains(.verificationEnabled) }
            .compactMap { $0.publicKey.unArmor }
    }

    private func fetchContactPinnedKeys(email: String, completion: @escaping UseCaseResult<Output>) {
        `async` { [dependencies] in
            let result: Swift.Result<Output, Error>

            do {
                let contacts = try `await`(dependencies.contactProvider.fetchAndVerifyContacts(byEmails: [email]))

                let keysResponse = try `await`(dependencies.emailPublicKeysProvider.publicKeys(for: email))

                guard let contact = contacts.first else {
                    DispatchQueue.main.async {
                        completion(.success(([], keysResponse.keys.isEmpty ? nil : keysResponse)))
                    }
                    return
                }

                let pinnedKeys = contact.pgpKeys

                let apiKeys = keysResponse.keys

                let bannedFingerprints = apiKeys
                    .filter { !$0.flags.contains(.verificationEnabled) }
                    .compactMap { $0.publicKey?.fingerprint }

                let validKeys = pinnedKeys
                    .filter { pinnedKey in
                        var error: NSError?
                        guard let pinnedCryptoKey = CryptoNewKey(pinnedKey, &error) else {
                            if let error = error {
                                PMLog.error(error)
                            }
                            return false
                        }

                        let pinnedKeyFingerprint = pinnedCryptoKey.getFingerprint()
                        return !bannedFingerprints.contains(pinnedKeyFingerprint)
                    }

                result = .success((validKeys, keysResponse))
            } catch {
                result = .failure(error)
            }

            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}

extension FetchVerificationKeys {
    struct Dependencies {
        let contactProvider: ContactProviderProtocol
        let emailPublicKeysProvider: EmailPublicKeysProviderProtocol
    }
}
