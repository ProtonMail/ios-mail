// Copyright (c) 2022 Proton Technologies AG
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
import Foundation

struct ContactPublicKeyModel {
    let encrypt: Bool
    // swiftlint:disable discouraged_optional_boolean
    let sign: Bool?
    let scheme: String?
    let mimeType: String?
    let email: String
    let publicKeys: ContactPublicKeys
    let trustedFingerprints: Set<String>
    let encryptionCapableFingerprints: Set<String>
    let verifyOnlyFingerprints: Set<String>
    let isPGPExternal: Bool
    let isPGPInternal: Bool
    let isPGPExternalWithWDKKeys: Bool
    let isPGPExternalWithoutWDKKeys: Bool
    let pgpAddressDisabled: Bool
    let isContact: Bool
}

extension ContactPublicKeyModel {
    var apiKeys: [CryptoKey] {
        return publicKeys.apiKeys
    }

    var pinnedKeys: [CryptoKey] {
        return publicKeys.pinnedKeys
    }

    var hasApiKeys: Bool {
        return !publicKeys.apiKeys.isEmpty
    }

    var hasPinnedKeys: Bool {
        return !publicKeys.pinnedKeys.isEmpty
    }

    var validApiSendKey: CryptoKey? {
        return apiKeys.first(where: { isValidForSending(fingerprint: $0.getFingerprint()) })
    }

    var primaryApiKey: CryptoKey? {
        return apiKeys.first
    }

    var primaryApiKeyFingerprint: String {
        return apiKeys.first?.getFingerprint() ?? ""
    }

    var isPrimaryApiKeyTrustedAndValid: Bool {
        return trustedFingerprints.contains(primaryApiKeyFingerprint) &&
            isValidForSending(fingerprint: primaryApiKeyFingerprint)
    }

    var primaryPinnedKey: CryptoKey? {
        return pinnedKeys.first
    }

    var primaryPinnedKeyFingerprint: String {
        return primaryPinnedKey?.getFingerprint() ?? ""
    }

    func isValidForSending(fingerprint: String) -> Bool {
        return !verifyOnlyFingerprints.contains(fingerprint) &&
            encryptionCapableFingerprints.contains(fingerprint)
    }
}
