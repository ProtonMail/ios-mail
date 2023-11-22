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
import ProtonCoreKeymaker

protocol FetchMobileSignatureUseCase {
    func execute(params: FetchMobileSignature.Parameters) -> String
}

final class FetchMobileSignature: FetchMobileSignatureUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func execute(params: Parameters) -> String {
        guard params.isPaidUser,
              let rawSignature = dependencies.cache.getEncryptedMobileSignature(userID: params.userID.rawValue),
              let mainKey = dependencies.coreKeyMaker.mainKey(by: dependencies.keychain.randomPinProtection),
              case let locked = Locked<String>(encryptedValue: rawSignature),
              let signature = try? locked.unlock(with: mainKey)
        else {
            dependencies.cache.removeEncryptedMobileSignature(userID: params.userID.rawValue)
            return Constants.defaultMobileSignature
        }
        return signature
    }
}

extension FetchMobileSignature {
    struct Dependencies {
        let coreKeyMaker: KeyMakerProtocol
        let cache: MobileSignatureCacheProtocol
        let keychain: Keychain
    }

    struct Parameters {
        let userID: UserID
        let isPaidUser: Bool
    }
}
