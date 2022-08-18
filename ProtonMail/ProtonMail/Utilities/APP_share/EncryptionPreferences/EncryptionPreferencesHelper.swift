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
import ProtonCore_DataModel

// swiftlint:disable type_body_length
enum EncryptionPreferencesHelper {
    // swiftlint:disable function_body_length
    static func getEncryptionPreferences(email: String,
                                         keysResponse: KeysResponse,
                                         userDefaultSign: Bool,
                                         userAddresses: [Address],
                                         contact: PreContact?) -> EncryptionPreferences {
        let selfAddress = userAddresses.first(where: { $0.email == email && $0.receive == .active })

        var selfSendConfig: SelfSendConfig?
        let apiKeysConfig: APIKeysConfig
        let pinnedKeysConfig: PinnedKeysConfig
        if let selfAddress = selfAddress {
            let publicKey = selfAddress.keys.first?.publicKey
            let key = convertToCryptoKey(from: publicKey)
            selfSendConfig = SelfSendConfig(address: selfAddress, publicKey: key)
            // For own addresses, we use the decrypted keys in selfSend and do not fetch any data from the API
            apiKeysConfig = APIKeysConfig(keys: [], publicKeys: [], recipientType: .internal)
            pinnedKeysConfig = PinnedKeysConfig(encrypt: false,
                                                sign: nil,
                                                scheme: nil,
                                                mimeType: nil,
                                                pinnedKeys: [],
                                                isContact: false)
        } else {
            let apiKeys: [(KeyResponse, CryptoKey)] = keysResponse.keys.compactMap { keyResponse in
                var error: NSError?
                if let key = CryptoNewKey(keyResponse.publicKey?.unArmor, &error) {
                    return error != nil ? nil : (keyResponse, key)
                }
                return nil
            }

            apiKeysConfig = APIKeysConfig(keys: apiKeys.map { $0.0 },
                                          publicKeys: apiKeys.map { $0.1 },
                                          recipientType: keysResponse.recipientType)

            let rawContactKeys: [Data] = contact?.pgpKeys ?? []
            let keys: [CryptoKey] = rawContactKeys.compactMap { rawKey in
                var error: NSError?
                let key = CryptoNewKey(rawKey, &error)
                return error != nil ? nil : key
            }
            pinnedKeysConfig = PinnedKeysConfig(encrypt: contact?.encrypt ?? false,
                                                sign: contact?.sign,
                                                scheme: contact?.scheme,
                                                mimeType: contact?.mimeType,
                                                pinnedKeys: keys,
                                                isContact: contact != nil)
        }

        let contactPublicKeyModel = getContactPublicKeyModel(email: email,
                                                             apiKeysConfig: apiKeysConfig,
                                                             pinnedKeysConfig: pinnedKeysConfig)
        return extractEncryptionPreferences(model: contactPublicKeyModel,
                                            defaultSign: userDefaultSign,
                                            selfSend: selfSendConfig)
    }

    /**
     * Extract the encryption preferences from a public-key model corresponding to a certain email address
     */
    static func extractEncryptionPreferences(model: ContactPublicKeyModel,
                                             defaultSign: Bool,
                                             selfSend: SelfSendConfig?) -> EncryptionPreferences {
        // Determine encrypt and sign flags, plus PGP scheme and MIME type.
        // Take mail settings into account if they are present
        let newModel = ContactPublicKeyModel(encrypt: model.encrypt,
                                             sign: model.sign ?? defaultSign,
                                             scheme: model.scheme,
                                             mimeType: model.mimeType,
                                             email: model.email,
                                             publicKeys: model.publicKeys,
                                             trustedFingerprints: model.trustedFingerprints,
                                             encryptionCapableFingerprints: model.encryptionCapableFingerprints,
                                             verifyOnlyFingerprints: model.verifyOnlyFingerprints,
                                             isPGPExternal: model.isPGPExternal,
                                             isPGPInternal: model.isPGPInternal,
                                             isPGPExternalWithWDKKeys: model.isPGPExternalWithWDKKeys,
                                             isPGPExternalWithoutWDKKeys: model.isPGPExternalWithoutWDKKeys,
                                             pgpAddressDisabled: model.pgpAddressDisabled,
                                             isContact: model.isContact)

        if let selfSend = selfSend { // case of own address
            return generateEncryptionPrefFromOwnAddress(selfSendConfig: selfSend, publicKeyModel: newModel)
        } else if model.isPGPInternal { // case of internal user
            return generateEncryptionPrefInternal(publicKeyModel: newModel)
        } else if model.isPGPExternalWithWDKKeys { // case of external user with WKD keys
            return generateEncryptionPrefExternalWithWDKKeys(publicKeyModel: newModel)
        } else { // case of external user without WKD keys
            return generateEncryptionPrefExternalWithoutWKDKeys(publicKeyModel: newModel)
        }
    }

    static func generateEncryptionPrefFromOwnAddress(selfSendConfig: SelfSendConfig,
                                                     publicKeyModel: ContactPublicKeyModel) -> EncryptionPreferences {
        let hasApiKeys = !selfSendConfig.address.keys.isEmpty
        let canAddressReceive = selfSendConfig.address.receive == .active
        var error: EncryptionPreferencesError?

        if !canAddressReceive {
            error = .internalUserDisable
        } else if !hasApiKeys {
            error = .internalUserNoApiKey
        } else if selfSendConfig.publicKey == nil {
            error = .internalUserNoValidApiKey
        }

        return .init(encrypt: true,
                     sign: true,
                     scheme: publicKeyModel.scheme,
                     mimeType: publicKeyModel.mimeType,
                     isInternal: true,
                     apiKeys: publicKeyModel.apiKeys,
                     pinnedKeys: [],
                     hasApiKeys: publicKeyModel.hasApiKeys,
                     hasPinnedKeys: false,
                     isContact: publicKeyModel.isContact,
                     sendKey: error == nil ? selfSendConfig.publicKey : nil,
                     isSendKeyPinned: false,
                     error: error)
    }

    static func generateEncryptionPrefInternal(publicKeyModel: ContactPublicKeyModel) -> EncryptionPreferences {
        if !publicKeyModel.hasApiKeys {
            return encryptionPrefInternal(publicKeyModel: publicKeyModel,
                                          sendKey: nil,
                                          isSendKeyPinned: false,
                                          error: .internalUserNoApiKey)
        }

        if publicKeyModel.validApiSendKey == nil {
            return encryptionPrefInternal(publicKeyModel: publicKeyModel,
                                          sendKey: nil,
                                          isSendKeyPinned: false,
                                          error: .internalUserNoValidApiKey)
        }
        if !publicKeyModel.hasPinnedKeys {
            // API keys are ordered in terms of user preference.
            // The primary key (first in the list) will be used for sending
            return encryptionPrefInternal(publicKeyModel: publicKeyModel,
                                          sendKey: publicKeyModel.primaryApiKey,
                                          isSendKeyPinned: false,
                                          error: nil)
        }
        // if there are pinned keys, make sure the primary API key is trusted and valid for sending
        let sendKey = publicKeyModel.pinnedKeys
            .first(where: { $0.getFingerprint() == publicKeyModel.primaryApiKeyFingerprint })
        if !publicKeyModel.isPrimaryApiKeyTrustedAndValid || sendKey == nil {
            return encryptionPrefInternal(publicKeyModel: publicKeyModel,
                                          sendKey: publicKeyModel.validApiSendKey,
                                          isSendKeyPinned: false,
                                          error: .primaryNotPinned)
        }
        return encryptionPrefInternal(publicKeyModel: publicKeyModel,
                                      sendKey: sendKey,
                                      isSendKeyPinned: true,
                                      error: nil)
    }

    static func generateEncryptionPrefExternalWithWDKKeys(
        publicKeyModel: ContactPublicKeyModel
    ) -> EncryptionPreferences {
        if publicKeyModel.validApiSendKey == nil {
            return encryptionPrefExternalWithWDKKeys(publicKeyModel: publicKeyModel,
                                                     sendKey: nil,
                                                     isSendKeyPinned: false,
                                                     error: .userNoValidWKDKey)
        }
        if !publicKeyModel.hasPinnedKeys {
            // WKD keys are ordered in terms of user preference.
            // The primary key (first in the list) will be used for sending
            return encryptionPrefExternalWithWDKKeys(publicKeyModel: publicKeyModel,
                                                     sendKey: publicKeyModel.primaryApiKey,
                                                     isSendKeyPinned: false,
                                                     error: nil)
        }
        // if there are pinned keys, make sure the primary API key is trusted and valid for sending
        let isPrimaryTrustedAndValid = publicKeyModel.isPrimaryApiKeyTrustedAndValid
        let sendKey = publicKeyModel.pinnedKeys
            .first(where: { $0.getFingerprint() == publicKeyModel.primaryApiKeyFingerprint })
        if !isPrimaryTrustedAndValid || sendKey == nil {
            return encryptionPrefExternalWithWDKKeys(publicKeyModel: publicKeyModel,
                                                     sendKey: publicKeyModel.validApiSendKey,
                                                     isSendKeyPinned: false,
                                                     error: .primaryNotPinned)
        }
        return encryptionPrefExternalWithWDKKeys(publicKeyModel: publicKeyModel,
                                                 sendKey: sendKey,
                                                 isSendKeyPinned: true,
                                                 error: nil)
    }

    static func generateEncryptionPrefExternalWithoutWKDKeys(
        publicKeyModel: ContactPublicKeyModel
    ) -> EncryptionPreferences {
        if !publicKeyModel.hasPinnedKeys {
            return encryptionPrefExternalWithoutWKDKeys(publicKeyModel: publicKeyModel,
                                                        sendKey: nil,
                                                        isSendKeyPinned: false,
                                                        error: nil)
        }
        // Pinned keys are ordered in terms of preference. Make sure the first is valid
        if !publicKeyModel.isValidForSending(fingerprint: publicKeyModel.primaryPinnedKeyFingerprint) {
            return encryptionPrefExternalWithoutWKDKeys(publicKeyModel: publicKeyModel,
                                                        sendKey: nil,
                                                        isSendKeyPinned: false,
                                                        error: .externalUserNoValidPinnedKey)
        }
        return encryptionPrefExternalWithoutWKDKeys(publicKeyModel: publicKeyModel,
                                                    sendKey: publicKeyModel.primaryPinnedKey,
                                                    isSendKeyPinned: true,
                                                    error: nil)
    }

    /**
     * For a given email address and its corresponding public keys (retrieved from the API
     * and/or the corresponding contact),
     * construct the contact public key model, which reflects the content of the contact.
     */
    static func getContactPublicKeyModel(email: String,
                                         apiKeysConfig: APIKeysConfig,
                                         pinnedKeysConfig: PinnedKeysConfig) -> ContactPublicKeyModel {
        var trustedFingerprints: Set<String> = []
        var encryptionCapableFingerprints: Set<String> = []
        let isInternal = apiKeysConfig.recipientType == .internal

        // keys from contact
        pinnedKeysConfig.pinnedKeys.forEach { key in
            let fingerprint = key.getFingerprint()
            trustedFingerprints.insert(fingerprint)
            if key.canEncrypt() {
                encryptionCapableFingerprints.insert(fingerprint)
            }
        }

        let sortedPinnedKeys = sortPinnedKeys(keys: pinnedKeysConfig.pinnedKeys,
                                              encryptionCapableFingerprints: encryptionCapableFingerprints)

        // keys from API
        var verifyOnlyFingerprints: Set<String> = []
        let apiKeys = apiKeysConfig.publicKeys
        apiKeys.forEach { key in
            if !key.isExpired() {
                let fingerprint = key.getFingerprint()
                if getKeyVerificationOnlyStatus(key: key, apiKeysConfig: apiKeysConfig) {
                    verifyOnlyFingerprints.insert(fingerprint)
                }
                if key.canEncrypt() {
                    encryptionCapableFingerprints.insert(fingerprint)
                }
            }
        }

        let sortedApiKeys = sortedApiKeys(keys: apiKeysConfig.publicKeys,
                                          trustedFingerprints: trustedFingerprints,
                                          verifyOnlyFingerprints: verifyOnlyFingerprints)

        return .init(encrypt: pinnedKeysConfig.encrypt,
                     sign: pinnedKeysConfig.sign,
                     scheme: pinnedKeysConfig.scheme,
                     mimeType: pinnedKeysConfig.mimeType,
                     email: email,
                     publicKeys: ContactPublicKeys(apiKeys: sortedApiKeys,
                                                   pinnedKeys: sortedPinnedKeys),
                     trustedFingerprints: trustedFingerprints,
                     encryptionCapableFingerprints: encryptionCapableFingerprints,
                     verifyOnlyFingerprints: verifyOnlyFingerprints,
                     isPGPExternal: !isInternal,
                     isPGPInternal: isInternal,
                     isPGPExternalWithWDKKeys: !isInternal && !apiKeys.isEmpty,
                     isPGPExternalWithoutWDKKeys: !isInternal && apiKeys.isEmpty,
                     pgpAddressDisabled: isDisableUser(apiKeysConfig: apiKeysConfig),
                     isContact: pinnedKeysConfig.isContact)
    }

    /**
     * Test if no key is enabled
     */
    static func isDisableUser(apiKeysConfig: APIKeysConfig) -> Bool {
        apiKeysConfig.recipientType == .internal &&
            !apiKeysConfig.keys.contains(where: { $0.flags.contains(.encryptionEnabled) })
    }

    /**
     * Given a public key retrieved from the API, return true if it has been marked as invalid for encryption,
     * and it is thus verification-only.
     * Return false if it's marked valid for encryption. Return undefined otherwise
     */
    static func getKeyVerificationOnlyStatus(key: CryptoKey, apiKeysConfig: APIKeysConfig) -> Bool {
        if let index = apiKeysConfig.publicKeys.firstIndex(of: key),
           let keyResponse = apiKeysConfig.keys[safe: index] {
            return !keyResponse.flags.contains(.encryptionEnabled)
        }
        return false
    }

    /**
     * Sort list of pinned keys retrieved from the API. Keys that can be used for sending take preference
     */
    static func sortPinnedKeys(keys: [CryptoKey],
                               encryptionCapableFingerprints: Set<String>) -> [CryptoKey] {
        let encryptionEnableKeys = keys.filter { encryptionCapableFingerprints.contains($0.getFingerprint()) }
        let otherKeys = keys.filter { !encryptionCapableFingerprints.contains($0.getFingerprint()) }
        return encryptionEnableKeys + otherKeys
    }

    /**
     * Sort list of keys retrieved from the API. Trusted keys take preference.
     * For two keys such that both are either trusted or not, non-verify-only keys take preference
     */
    static func sortedApiKeys(keys: [CryptoKey],
                              trustedFingerprints: Set<String>,
                              verifyOnlyFingerprints: Set<String>) -> [CryptoKey] {
        return keys.sorted { lhs, rhs in
            let lhsFingerprint = lhs.getFingerprint()
            let rhsFingerprint = rhs.getFingerprint()

            if trustedFingerprints.contains(lhsFingerprint), trustedFingerprints.contains(rhsFingerprint) {
                return verifyOnlyFingerprints.contains(lhsFingerprint)
            }

            return trustedFingerprints.contains(lhsFingerprint)
        }
    }

    static func convertToCryptoKey(from rawKey: String?) -> CryptoKey? {
        var error: NSError?
        guard let key = CryptoNewKey(rawKey?.unArmor, &error),
              error == nil else {
            return nil
        }
        return key
    }

    private static func encryptionPrefInternal(
        publicKeyModel: ContactPublicKeyModel,
        sendKey: CryptoKey?,
        isSendKeyPinned: Bool,
        error: EncryptionPreferencesError?
    ) -> EncryptionPreferences {
        return .init(
            encrypt: true,
            sign: true,
            scheme: publicKeyModel.scheme,
            mimeType: publicKeyModel.mimeType,
            isInternal: true,
            apiKeys: publicKeyModel.publicKeys.apiKeys,
            pinnedKeys: publicKeyModel.publicKeys.pinnedKeys,
            hasApiKeys: !publicKeyModel.publicKeys.apiKeys.isEmpty,
            hasPinnedKeys: !publicKeyModel.publicKeys.pinnedKeys.isEmpty,
            isContact: publicKeyModel.isContact,
            sendKey: sendKey,
            isSendKeyPinned: isSendKeyPinned,
            error: error
        )
    }

    private static func encryptionPrefExternalWithWDKKeys(
        publicKeyModel: ContactPublicKeyModel,
        sendKey: CryptoKey?,
        isSendKeyPinned: Bool,
        error: EncryptionPreferencesError?
    ) -> EncryptionPreferences {
        return .init(encrypt: true,
                     sign: true,
                     scheme: publicKeyModel.scheme,
                     mimeType: publicKeyModel.mimeType,
                     isInternal: false,
                     apiKeys: publicKeyModel.apiKeys,
                     pinnedKeys: publicKeyModel.pinnedKeys,
                     hasApiKeys: true,
                     hasPinnedKeys: publicKeyModel.hasPinnedKeys,
                     isContact: publicKeyModel.isContact,
                     sendKey: sendKey,
                     isSendKeyPinned: isSendKeyPinned,
                     error: error)
    }

    private static func encryptionPrefExternalWithoutWKDKeys(
        publicKeyModel: ContactPublicKeyModel,
        sendKey: CryptoKey?,
        isSendKeyPinned: Bool,
        error: EncryptionPreferencesError?
    ) -> EncryptionPreferences {
        .init(encrypt: publicKeyModel.encrypt,
              sign: publicKeyModel.sign ?? false,
              scheme: publicKeyModel.scheme,
              mimeType: publicKeyModel.mimeType,
              isInternal: false,
              apiKeys: publicKeyModel.apiKeys,
              pinnedKeys: publicKeyModel.pinnedKeys,
              hasApiKeys: false,
              hasPinnedKeys: publicKeyModel.hasPinnedKeys,
              isContact: publicKeyModel.isContact,
              sendKey: sendKey,
              isSendKeyPinned: isSendKeyPinned,
              error: error)
    }
}
