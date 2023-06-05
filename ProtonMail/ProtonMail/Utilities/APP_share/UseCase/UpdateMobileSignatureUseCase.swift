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
import ProtonCore_Keymaker

typealias UpdateMobileSignatureUseCase = NewUseCase<Void, UpdateMobileSignature.Parameters>

final class UpdateMobileSignature: UpdateMobileSignatureUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Parameters, callback: @escaping NewUseCase<Void, Parameters>.Callback) {
        guard let mainKey = dependencies.coreKeyMaker.mainKey(by: .randomPin) else {
            callback(.failure(UpdateMobileSignatureError.failedToGetMainKey))
            return
        }
        do {
            let locked = try Locked<String>(clearValue: params.signature, with: mainKey)
            dependencies.cache.setEncryptedMobileSignature(
                userID: params.userID.rawValue,
                signatureData: locked.encryptedValue
            )
            callback(.success(()))
        } catch {
            callback(.failure(error))
        }
    }
}

extension UpdateMobileSignature {
    enum UpdateMobileSignatureError: Error {
        case failedToGetMainKey
    }

    struct Dependencies {
        let coreKeyMaker: KeyMakerProtocol
        let cache: MobileSignatureCacheProtocol
    }

    struct Parameters {
        let signature: String
        let userID: UserID
    }
}
