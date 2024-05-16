// Copyright (c) 2024 Proton Technologies AG
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

import Combine
import ProtonCoreDataModel
import ProtonCoreFeatures
import ProtonInboxRSVP

extension AnswerInvitationUseCase {
    struct RecipientProvider: RecipientProviding {
        typealias Dependencies = HasFetchEmailAddressesPublicKey

        private let dependencies: Dependencies

        init(dependencies: Dependencies) {
            self.dependencies = dependencies
        }

        func recipient(email: String) -> AnyPublisher<Recipient, Error> {
            Future(block: { try await dependencies.fetchEmailAddressesPublicKey.execute(email: email) })
                .map { (keysResponse: KeysResponse) -> Recipient in
                    Recipient(
                        email: email,
                        type: keysResponse.recipientType.coreEquivalent,
                        activePublicKeys: keysResponse.keys.map(\.coreEquivalent)
                    )
                }
                .eraseToAnyPublisher()
        }
    }
}

private extension KeysResponse.RecipientType {
    var coreEquivalent: ProtonCoreFeatures.RecipientType {
        switch self {
        case .internal:
            return .internal
        case .external:
            return .external
        }
    }
}

private extension KeyResponse {
    var coreEquivalent: ActivePublicKey {
        .init(flags: flags.coreEquivalent, publicKey: publicKey)
    }
}

private extension Key.Flags {
    var coreEquivalent: KeyFlags {
        .init(rawValue: UInt8(rawValue))
    }
}
