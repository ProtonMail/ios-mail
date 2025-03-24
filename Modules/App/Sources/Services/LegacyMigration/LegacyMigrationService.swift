// Copyright (c) 2025 Proton Technologies AG
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
import Foundation
import InboxCore
import proton_app_uniffi

actor LegacyMigrationService {
    typealias PassMigrationPayloadToRustSDK = @Sendable (MigrationData) async throws -> Void

    struct EncryptedLegacyData: Equatable {
        let authCredentials: Data
        let userInfos: Data
    }

    enum MigrationError: Error {
        case failedToUnarchive(NSSecureCoding.Type)
    }

    enum MigrationState: Equatable {
        case notChecked
        case notNeeded
        case inProgress(encryptedLegacyData: EncryptedLegacyData, mainKey: Data)
        case awaitingProtectedMainKey(EncryptedLegacyData)
        case failed
    }

    var statePublisher: AnyPublisher<MigrationState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private let legacyKeychain: LegacyKeychain
    private let legacyUserDefaults = UserDefaults.legacy
    private let passMigrationPayloadToRustSDK: PassMigrationPayloadToRustSDK
    private let stateSubject = CurrentValueSubject<MigrationState, Never>(.notChecked)

    private var state: MigrationState {
        get {
            stateSubject.value
        }
        set {
            AppLogger.log(
                message: "State will change: \(stateSubject.value) -> \(newValue)",
                category: .legacyMigration
            )

            stateSubject.value = newValue
        }
    }

    init(legacyKeychain: LegacyKeychain, passMigrationPayloadToRustSDK: @escaping PassMigrationPayloadToRustSDK) {
        self.legacyKeychain = legacyKeychain
        self.passMigrationPayloadToRustSDK = passMigrationPayloadToRustSDK
    }

    private init() {
        self.init(legacyKeychain: .init()) {
            try await AppContext.shared.accountAuthCoordinator.migrateLegacySession(migrationData: $0)
        }
    }

    // MARK: entry points

    func proceed() async {
        let previousState = state

        switch state {
        case .notChecked:
            state = startMigrationIfNeeded()
        case .inProgress(let encryptedLegacyData, let mainKey):
            state = await performMigration(encryptedLegacyData: encryptedLegacyData, mainKey: mainKey)
        case .awaitingProtectedMainKey:
            break
        case .notNeeded, .failed:
            cleanUpLegacyData()
        }

        if state != previousState {
            await proceed()
        }
    }

    func resume(protectedMainKey: Data) async {
        switch state {
        case .awaitingProtectedMainKey(let encryptedLegacyData):
            state = .inProgress(encryptedLegacyData: encryptedLegacyData, mainKey: protectedMainKey)
            await proceed()
        default:
            onIllegalStateTransition()
        }
    }

    func abortWithoutProvidingProtectedMainKey() async {
        switch state {
        case .awaitingProtectedMainKey:
            state = .notNeeded
            await proceed()
        default:
            onIllegalStateTransition()
        }
    }

    // MARK: state transitions

    private func startMigrationIfNeeded() -> MigrationState {
        guard
            let authCredentialData = legacyUserDefaults.legacyData(forKey: .authCredentials),
            let userInfoData = legacyUserDefaults.legacyData(forKey: .userInfos)
        else {
            return .notNeeded
        }

        let encryptedLegacyData = EncryptedLegacyData(authCredentials: authCredentialData, userInfos: userInfoData)

        do {
            if let unprotectedMainKey = try legacyKeychain.data(forKey: .unprotectedMainKey) {
                return .inProgress(encryptedLegacyData: encryptedLegacyData, mainKey: unprotectedMainKey)
            } else {
                return .awaitingProtectedMainKey(encryptedLegacyData)
            }
        } catch {
            AppLogger.log(error: error, category: .legacyMigration)
            return .failed
        }
    }

    private func performMigration(encryptedLegacyData: EncryptedLegacyData, mainKey: Data) async -> MigrationState {
        Address.registerNamespacedClassName()
        AuthCredential.registerNamespacedClassName()

        do {
            let authCredentials: [AuthCredential] = try decryptAndDecode(
                data: encryptedLegacyData.authCredentials,
                using: mainKey
            )

            let userInfos: [UserInfo] = try decryptAndDecode(data: encryptedLegacyData.userInfos, using: mainKey)
            let migrationPayloads = prepareMigrationPayloads(authCredentials: authCredentials, userInfos: userInfos)

            for migrationPayload in migrationPayloads {
                try await passMigrationPayloadToRustSDK(migrationPayload)
            }

            return .notNeeded
        } catch {
            AppLogger.log(error: error, category: .legacyMigration)
            return .failed
        }
    }

    // MARK: other methods

    private func decryptAndDecode<T: NSSecureCoding>(data encryptedData: Data, using key: Data) throws -> [T] {
        let iv = encryptedData[0..<16]
        let ciphertext = encryptedData[16...]
        let decryptedArchives = try AES.CTR.decrypt(ciphertext: ciphertext, key: key, iv: iv)
        let decodedArchive = try PropertyListDecoder().decode([Data].self, from: decryptedArchives)[0]

        let relevantClasses: [AnyClass] = [
            NSArray.self,
            NSString.self,
            Address.self,
            AuthCredential.self,
            UserInfo.self,
        ]

        guard let unarchived = try NSKeyedUnarchiver.unarchivedObject(
            ofClasses: relevantClasses,
            from: decodedArchive
        ) as? [T] else {
            throw MigrationError.failedToUnarchive(T.self)
        }

        return unarchived
    }

    private func prepareMigrationPayloads(authCredentials: [AuthCredential], userInfos: [UserInfo]) -> [MigrationData] {
        authCredentials.compactMap { authCredential in
            guard let userInfo = userInfos.first(where: { $0.userId == authCredential.userID }) else {
                return nil
            }

            return MigrationData(
                username: authCredential.userName,
                displayName: userInfo.displayName,
                primaryAddr: userInfo.userAddresses.first { $0.receive == 1 && $0.status == 1}?.email ?? "",
                keySecret: authCredential.mailboxPassword,
                userId: authCredential.userID,
                sessionId: authCredential.sessionID,
                passwordMode: userInfo.passwordMode == 2 ? .two : .one,
                refreshToken: authCredential.refreshToken
            )
        }
    }

    private func cleanUpLegacyData() {
        legacyKeychain.removeEverything()
        legacyUserDefaults.removeLegacyKeys()
    }

    private func onIllegalStateTransition(
        function: StaticString = #function,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let errorMessage = "\(function) should not be called in this state: \(state)"
        AppLogger.log(message: errorMessage, category: .legacyMigration, isError: true)
        assertionFailure(errorMessage, file: file, line: line)
    }
}

extension LegacyMigrationService {
    static let shared = LegacyMigrationService()
}

extension LegacyMigrationService: ApplicationServiceSetUp {
    nonisolated func setUpService() {
        Task {
            await proceed()
        }
    }
}
