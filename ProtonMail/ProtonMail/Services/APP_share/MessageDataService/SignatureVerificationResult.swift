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

import GoLibs
import ProtonCore_Crypto

enum SignatureVerificationResult {
    case success
    case signatureVerificationSkipped
    case messageNotSigned
    case failure

    init(gopenpgpOutput: Int) {
        switch gopenpgpOutput {
        case ConstantsSIGNATURE_OK:
            self = .success
        case ConstantsSIGNATURE_NOT_SIGNED:
            self = .messageNotSigned
        case ConstantsSIGNATURE_FAILED, ConstantsSIGNATURE_NO_VERIFIER:
            self = .failure
        default:
            assertionFailure("Unknown value \(gopenpgpOutput)")
            self = .failure
        }
    }

    init(error: SignatureVerifyError) {
        switch error.code {
        case ConstantsSIGNATURE_NOT_SIGNED, ConstantsSIGNATURE_FAILED, ConstantsSIGNATURE_NO_VERIFIER:
            self.init(gopenpgpOutput: error.code)
        default:
            assertionFailure("Unexpected error: \(error.message) (code \(error.code))")
            self = .failure
        }
    }

    init<T>(message: VerifiedMessage<T>) {
        switch message {
        case .verified:
            self = .success
        case let .unverified(_, error as SignatureVerifyError):
            self = SignatureVerificationResult(error: error)
        case let .unverified(_, error):
            assertionFailure("Unrecognized error: \(error)")
            self = .failure
        }
    }
}
