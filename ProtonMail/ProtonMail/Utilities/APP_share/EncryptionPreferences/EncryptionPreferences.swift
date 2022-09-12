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

struct EncryptionPreferences {
    let encrypt: Bool
    let sign: Bool
    let scheme: String?
    let mimeType: String?
    let isInternal: Bool
    let apiKeys: [CryptoKey]
    let pinnedKeys: [CryptoKey]
    let hasApiKeys: Bool
    let hasPinnedKeys: Bool
    let isContact: Bool
    let sendKey: CryptoKey?
    let isSendKeyPinned: Bool
    let error: EncryptionPreferencesError?
}

enum EncryptionPreferencesError: Error, Equatable {
    case internalUserDisable
    case internalUserNoApiKey
    case internalUserNoValidApiKey
    case primaryNotPinned
    case userNoValidWKDKey
    case externalUserNoValidPinnedKey

    var message: String {
        switch self {
        case .internalUserDisable:
            return LocalString._encPref_error_internal_user_disable
        case .internalUserNoApiKey:
            return LocalString._encPref_error_internal_user_no_apiKey
        case .internalUserNoValidApiKey:
            return LocalString._encPref_error_internal_user_no_valid_apiKey
        case .primaryNotPinned:
            return LocalString._encPref_error_internal_user_primary_not_pinned
        case .userNoValidWKDKey:
            return LocalString._encPref_error_internal_user_no_valid_wkd_key
        case .externalUserNoValidPinnedKey:
            return LocalString._encPref_error_internal_user_no_valid_pinned_key
        }
    }
}
