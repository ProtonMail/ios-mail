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

import Foundation
import InboxCore
import proton_app_uniffi

/// This is a wrapper to make the Keychain accessible from the SDK. Notice that even though the protocol does not
/// mention the expected type of error to be thrown due to the Swift language limitations, we should
/// use `OsKeyChainError`.
public final class KeychainSDKWrapper: OsKeyChain, @unchecked Sendable {
    private let keychain: Keychain

    public init() {
        self.keychain = Keychain(service: Bundle.defaultIdentifier, accessGroup: AppGroup.mail)
    }

    public func store(kind: OsKeyChainEntryKind, key: String) throws {
        AppLogger.logTemporarily(message: "Storing \(kind) in Keychain", category: .rustLibrary)
        do {
            try keychain.setOrError(key, forKey: kind.key)
        } catch let error {
            throw osKeyChainError(error: error)
        }
    }

    public func delete(kind: OsKeyChainEntryKind) throws {
        AppLogger.logTemporarily(message: "Deleting \(kind) from Keychain", category: .rustLibrary)
        do {
            try keychain.removeOrError(forKey: kind.key)
        } catch let error {
            throw osKeyChainError(error: error)
        }
    }

    public func load(kind: OsKeyChainEntryKind) throws -> String? {
        AppLogger.logTemporarily(message: "Loading \(kind) from Keychain", category: .rustLibrary)
        do {
            return try keychain.stringOrError(forKey: kind.key)
        } catch let error {
            throw osKeyChainError(error: error)
        }
    }
}

// MARK: - Private

extension KeychainSDKWrapper {
    private func osKeyChainError(error: Error, function: String = #function) -> OsKeyChainError {
        AppLogger.log(message: "KeychainSDKWrapper \(function): \(String(describing: error))", isError: true)
        return OsKeyChainError.Os(String(describing: error))
    }
}

private extension OsKeyChainEntryKind {
    var key: String {
        switch self {
        case .encryptionKey: "mailApplicationKey"
        default: String(describing: self)
        }
    }
}
