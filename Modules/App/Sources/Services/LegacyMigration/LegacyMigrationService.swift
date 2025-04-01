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
    typealias PassMigrationPayloadsToRustSDK = @Sendable ([MigrationData]) async throws -> Void

    struct EncryptedLegacyData: Equatable {
        let authCredentials: Data
        let userInfos: Data
        let addressSignatureStatusPerUser: [String: Bool]
        let mobileSignatureContentPerUser: [String: Data]
        let mobileSignatureStatusPerUser: [String: Bool]
    }

    struct MigrationInputs: Equatable {
        let encryptedLegacyData: EncryptedLegacyData
        let mainKey: Data
        let protectionPreference: ProtectionPreference?
    }

    enum MigrationError: Error {
        case failedToUnarchive(NSSecureCoding.Type)
    }

    enum MigrationState: Equatable {
        case notChecked
        case notNeeded
        case inProgress(MigrationInputs)
        case awaitingProtectedMainKey(EncryptedLegacyData)
        case failed
    }

    enum ProtectionPreference: CustomStringConvertible, Equatable {
        case biometrics
        case pin(PIN)

        var description: String {
            switch self {
            case .biometrics:
                "biometrics"
            case .pin(let secretValue):
                "\(secretValue.digits.count)-digit PIN"
            }
        }
    }

    var statePublisher: AnyPublisher<MigrationState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private let legacyKeychain: LegacyKeychain
    private let legacyDataProvider: LegacyDataProvider
    private let getMailSession: () -> MailSessionProtocol
    private let passMigrationPayloadsToRustSDK: PassMigrationPayloadsToRustSDK
    private let settingsMigrator: SettingsMigrator
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

    init(
        legacyKeychain: LegacyKeychain,
        legacyDataProvider: LegacyDataProvider,
        getMailSession: @escaping () -> MailSessionProtocol,
        passMigrationPayloadsToRustSDK: @escaping PassMigrationPayloadsToRustSDK,
        appAppearanceStore: @escaping SettingsMigrator.AppAppearanceStoreGetter = { .shared }
    ) {
        self.legacyKeychain = legacyKeychain
        self.legacyDataProvider = legacyDataProvider
        self.getMailSession = getMailSession
        self.passMigrationPayloadsToRustSDK = passMigrationPayloadsToRustSDK
        settingsMigrator = .init(
            legacyKeychain: legacyKeychain,
            legacyDataProvider: legacyDataProvider,
            appAppearanceStore: appAppearanceStore
        )
    }

    private init() {
        self.init(
            legacyKeychain: .init(),
            legacyDataProvider: .init(),
            getMailSession: { AppContext.shared.mailSession },
            passMigrationPayloadsToRustSDK: {
                try await AppContext.shared.accountAuthCoordinator.migrateLegacySessions(migrationPayloads: $0)
            }
        )
    }

    // MARK: entry points

    func proceed() async {
        let previousState = state

        switch state {
        case .notChecked:
            state = startMigrationIfNeeded()
        case .inProgress(let inputs):
            state = await performMigration(inputs: inputs)
        case .awaitingProtectedMainKey:
            break
        case .notNeeded, .failed:
            cleanUpLegacyData()
        }

        if state != previousState {
            await proceed()
        }
    }

    func resume(protectedMainKey: Data, protectionPreference: ProtectionPreference) async {
        switch state {
        case .awaitingProtectedMainKey(let encryptedLegacyData):
            state = .inProgress(
                .init(
                    encryptedLegacyData: encryptedLegacyData,
                    mainKey: protectedMainKey,
                    protectionPreference: protectionPreference
                )
            )
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
        guard let encryptedLegacyData = loadEncryptedLegacyData() else {
            return .notNeeded
        }

        do {
            if let unprotectedMainKey = try legacyKeychain.data(forKey: .unprotectedMainKey) {
                return .inProgress(
                    .init(
                        encryptedLegacyData: encryptedLegacyData,
                        mainKey: unprotectedMainKey,
                        protectionPreference: nil
                    )
                )
            } else {
                return .awaitingProtectedMainKey(encryptedLegacyData)
            }
        } catch {
            AppLogger.log(error: error, category: .legacyMigration)
            return .failed
        }
    }

    private func performMigration(inputs: MigrationInputs) async -> MigrationState {
        Address.registerNamespacedClassName()
        AuthCredential.registerNamespacedClassName()

        do {
            let authCredentials: [AuthCredential] = try decryptAndDecode(
                data: inputs.encryptedLegacyData.authCredentials,
                using: inputs.mainKey
            )

            let userInfos: [UserInfo] = try decryptAndDecode(
                data: inputs.encryptedLegacyData.userInfos,
                using: inputs.mainKey
            )

            let decryptedMobileSignatures = try decryptMobileSignatures(
                encryptedMobileSignatures: inputs.encryptedLegacyData.mobileSignatureContentPerUser,
                using: inputs.mainKey
            )

            let migrationPayloads = prepareMigrationPayloads(
                authCredentials: authCredentials,
                userInfos: userInfos,
                addressSignatureStatusPerUser: inputs.encryptedLegacyData.addressSignatureStatusPerUser,
                mobileSignatureContentPerUser: decryptedMobileSignatures,
                mobileSignatureStatusPerUser: inputs.encryptedLegacyData.mobileSignatureStatusPerUser
            )

            try await passMigrationPayloadsToRustSDK(migrationPayloads)

            let mailSession = getMailSession()
            await settingsMigrator.migrateSettings(in: mailSession)

            if let protectionPreference = inputs.protectionPreference {
                await setUpProtection(basedOn: protectionPreference)
            }

            return .notNeeded
        } catch {
            AppLogger.log(error: error, category: .legacyMigration)
            return .failed
        }
    }

    // MARK: other methods

    private func loadEncryptedLegacyData() -> EncryptedLegacyData? {
        guard
            let authCredentialData = legacyDataProvider.data(forKey: .authCredentials),
            let userInfoData = legacyDataProvider.data(forKey: .userInfos)
        else {
            return nil
        }

        return .init(
            authCredentials: authCredentialData,
            userInfos: userInfoData,
            addressSignatureStatusPerUser: legacyDataProvider.dictionary(forKey: .addressSignatureStatusPerUser),
            mobileSignatureContentPerUser: legacyDataProvider.dictionary(forKey: .mobileSignatureContentPerUser),
            mobileSignatureStatusPerUser: legacyDataProvider.dictionary(forKey: .mobileSignatureStatusPerUser)
        )
    }

    private func decryptAndDecode<T: NSSecureCoding>(data encryptedData: Data, using key: Data) throws -> [T] {
        let decodedArchive: Data = try LockedDataExtractor.decryptAndDecode(data: encryptedData, using: key)[0]

        let relevantClasses: [AnyClass] = [
            NSArray.self,
            NSString.self,
            Address.self,
            AuthCredential.self,
            UserInfo.self,
        ]

        guard
            let unarchived = try NSKeyedUnarchiver.unarchivedObject(
                ofClasses: relevantClasses,
                from: decodedArchive
            ) as? [T]
        else {
            throw MigrationError.failedToUnarchive(T.self)
        }

        return unarchived
    }

    private func decryptMobileSignatures(encryptedMobileSignatures: [String: Data], using key: Data) throws -> [String: String] {
        try encryptedMobileSignatures.mapValues { encryptedMobileSignature in
            try LockedDataExtractor.decryptAndDecode(data: encryptedMobileSignature, using: key)[0]
        }
    }

    private func prepareMigrationPayloads(
        authCredentials: [AuthCredential],
        userInfos: [UserInfo],
        addressSignatureStatusPerUser: [String: Bool],
        mobileSignatureContentPerUser: [String: String],
        mobileSignatureStatusPerUser: [String: Bool]
    ) -> [MigrationData] {
        authCredentials.compactMap { authCredential in
            let userID = authCredential.userID

            guard let userInfo = userInfos.first(where: { $0.userId == userID }) else {
                fatalError()
            }

            let primaryAddress = userInfo.userAddresses.first { $0.receive == 1 && $0.status == 1 }?.email

            return MigrationData(
                username: authCredential.userName,
                displayName: userInfo.displayName,
                primaryAddr: primaryAddress ?? "",
                addressSignatureEnabled: addressSignatureStatusPerUser[userID],
                mobileSignature: mobileSignatureContentPerUser[userID],
                mobileSignatureEnabled: mobileSignatureStatusPerUser[userID],
                keySecret: authCredential.mailboxPassword,
                userId: userID,
                sessionId: authCredential.sessionID,
                passwordMode: userInfo.passwordMode == 2 ? .two : .one,
                refreshToken: authCredential.refreshToken
            )
        }
    }

    private func setUpProtection(basedOn protectionPreference: ProtectionPreference) async {
        let mailSession = getMailSession()

        do {
            switch protectionPreference {
            case .biometrics:
                try await mailSession.setBiometricsAppProtection().get()
            case .pin(let pin):
                try await mailSession.setPinCode(pin: pin.digits).get()
            }
        } catch {
            AppLogger.log(error: error, category: .legacyMigration)
        }
    }

    private func cleanUpLegacyData() {
        legacyKeychain.removeEverything()
        legacyDataProvider.removeAll()
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
