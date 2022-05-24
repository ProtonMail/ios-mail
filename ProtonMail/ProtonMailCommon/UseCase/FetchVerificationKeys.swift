// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Crypto
import ProtonCore_DataModel
import ProtonCore_Log

protocol FetchVerificationKeysUseCase: UseCase {
    func execute(email: String, completion: @escaping UseCaseResult<[Data]>)
}

final class FetchVerificationKeys: FetchVerificationKeysUseCase {
    private let dependencies: Dependencies
    private let userAddresses: [Address]

    init(dependencies: Dependencies, userAddresses: [Address]) {
        self.dependencies = dependencies
        self.userAddresses = userAddresses
    }

    func execute(email: String, completion: @escaping UseCaseResult<[Data]>) {
        if let userAddress = userAddresses.first(where: { $0.email == email }) {
            let validKeys = nonCompromisedUserAddressKeys(belongingTo: userAddress)
            completion(.success(validKeys))
        } else {
            fetchContactPinnedKeys(email: email, completion: completion)
        }
    }

    private func nonCompromisedUserAddressKeys(belongingTo address: Address) -> [Data] {
        address.keys
            .filter { $0.flags.contains(.verificationEnabled) }
            .compactMap { $0.publicKey.unArmor }
    }

    private func fetchContactPinnedKeys(email: String, completion: @escaping UseCaseResult<[Data]>) {
        `async` { [dependencies] in
            let result: Swift.Result<[Data], Error>

            do {
                let contacts = try `await`(dependencies.contactProvider.fetch(byEmails: [email]))

                guard let contact = contacts.first else {
                    DispatchQueue.main.async {
                        completion(.success([]))
                    }
                    return
                }

                // do we need to verify the contact, or is it already verified?

                let pinnedKeys = contact.pgpKeys

                let keysResponse = try `await`(dependencies.emailPublicKeysProvider.publicKeys(for: email))

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

                result = .success(validKeys)
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
