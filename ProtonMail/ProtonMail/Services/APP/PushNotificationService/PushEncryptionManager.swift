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

import ProtonCoreCrypto

// sourcery: mock
protocol PushEncryptionManagerProtocol {
    /**
     This method will register the received `deviceToken` in the backend to use it for push notifications.

     All existing sessions will register the token if it's different from what is already registered. The
     token will be registered with an encryption key. The key by default will be the one already in use.

     If there is any error in registering the keys to backend, the next time this function is called
     it will try the registration for all sessions again.
     */
    func registerDeviceForNotifications(deviceToken: String)

    /**
     Call this method every time there is a new account sign in.

     This function will register for all authenticated sessions the latest known device token and public key.
     */
    func registerDeviceAfterNewAccountSignIn()

    /**
     This method clears local stored data like device token, encryption keys and other flags
     */
    func deleteAllCachedData()
}

final class PushEncryptionManager: PushEncryptionManagerProtocol {
    static let maxNumberOfKitsInCache = 8

    private let dependencies: Dependencies
    private let serialQueue = DispatchQueue(label: "ch.protonmail.protonmail.DeviceService")

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func registerDeviceForNotifications(deviceToken: String) {
        guard shouldRegisterDevice(token: deviceToken) else {
            return
        }
        Task {
            let rotateKey = dependencies.failedPushDecryptionProvider.hadPushNotificationDecryptionFailed
            guard let kit = kitForRegisteringDevice(rotateKey: rotateKey) else { return }
            await updateTokensAndKitsForAllSessions(tokenToRegister: deviceToken, kit: kit)
        }
    }

    func registerDeviceAfterNewAccountSignIn() {
        SystemLogger.log(message: "register known device token for new sign in", category: .pushNotification)
        guard let lastRegisteredToken = lastRegisteredToken else {
            SystemLogger.log(message: "no device token found", category: .pushNotification, isError: true)
            return
        }
        Task {
            guard let kit = kitForRegisteringDevice(rotateKey: false) else { return }
            await updateTokensAndKitsForAllSessions(tokenToRegister: lastRegisteredToken, kit: kit)
        }
    }

    func deleteAllCachedData() {
        SystemLogger.log(message: "delete PushEncryptionManager local data", category: .encryption)
        serialQueue.sync {
            dependencies.encryptionKitsCache.set(newValue: [])
            dependencies.pushEncryptionProvider.lastRegisteredDeviceToken = nil
            dependencies.pushEncryptionProvider.isDeviceTokenRegistrationRetryPending = false
            dependencies.failedPushDecryptionProvider.clearPushNotificationDecryptionFailure()
        }
    }
}

extension PushEncryptionManager {

    private var retryDeviceTokenRegistration: Bool {
        serialQueue.sync {
            dependencies.pushEncryptionProvider.isDeviceTokenRegistrationRetryPending
        }
    }

    private func setRetryDeviceTokenRegistration(to value: Bool) {
        SystemLogger.log(message: "setRetryDeviceTokenRegistration \(value)", category: .pushNotification)
        serialQueue.sync {
            dependencies.pushEncryptionProvider.isDeviceTokenRegistrationRetryPending = value
        }
    }

    private var lastRegisteredToken: String? {
        serialQueue.sync {
            dependencies.pushEncryptionProvider.lastRegisteredDeviceToken
        }
    }

    private var activeEncryptionKit: EncryptionKit? {
        encryptionKitsFromCache.first
    }

    private var encryptionKitsFromCache: [EncryptionKit] {
        var kits: [EncryptionKit]?
        serialQueue.sync {
            kits = dependencies.encryptionKitsCache.get()
        }
        guard let kits else {
            SystemLogger.log(message: "no encryption kits in cache", category: .encryption)
            return []
        }
        return kits
    }

    private func shouldRegisterDevice(token: String) -> Bool {
        guard !token.isEmpty else { return false }
        if token != lastRegisteredToken {
            let message = "device token different from the last registered \(lastRegisteredToken?.redacted ?? "-")"
            SystemLogger.log(message: message, category: .pushNotification)
            return true
        } else if retryDeviceTokenRegistration {
            SystemLogger.log(message: "retrying device registration", category: .pushNotification)
            return true
        } else if dependencies.failedPushDecryptionProvider.hadPushNotificationDecryptionFailed {
            SystemLogger.log(message: "device registration after decryption failure", category: .pushNotification)
            return true
        }
        return false
    }

    private func updateTokensAndKitsForAllSessions(tokenToRegister: String, kit: EncryptionKit) async {
        setRetryDeviceTokenRegistration(to: false)
        dependencies.failedPushDecryptionProvider.clearPushNotificationDecryptionFailure()

        // we register the same device token and kit for all sessions
        let registrationResult = await registerDeviceInBackendForAllSessions(token: tokenToRegister, kit: kit)
        guard registrationResult.atLeastOneSucceeded else {
            setRetryDeviceTokenRegistration(to: true)
            return
        }
        saveDeviceRegistrationInCache(token: tokenToRegister, kit: kit)

        if registrationResult.someFailed {
            // we will try to register the device token for all sessions again
            setRetryDeviceTokenRegistration(to: true)
        }
    }

    private func registerDeviceInBackendForAllSessions(token: String, kit: EncryptionKit) async -> BulkRequestResult {
        let sessionIDs = dependencies.usersManagers.users.map(\.authCredential.sessionID)
        let results = await dependencies
            .deviceRegistration
            .execute(sessionIDs: sessionIDs, deviceToken: token, publicKey: kit.publicKey)

        let successfulRegistrations = Set(results.filter({ $0.error == nil }).map(\.sessionID))
        let failedRegistrations = Set(results.filter({ $0.error != nil }).map(\.sessionID))
        return BulkRequestResult(successfulSessionIDs: successfulRegistrations, failedSessionIDs: failedRegistrations)
    }

    private func kitForRegisteringDevice(rotateKey: Bool) -> EncryptionKit? {
        let kit: EncryptionKit?
        if rotateKey {
            kit = generateEncryptionKit()
        } else {
            kit = activeEncryptionKit ?? generateEncryptionKit()
        }
        return kit
    }

    private func generateEncryptionKit() -> EncryptionKit? {
        do {
            let keyPair = try MailCrypto.generateRandomKeyPair()
            SystemLogger.log(message: "new encryption kit", category: .encryption)
            return EncryptionKit(
                passphrase: keyPair.passphrase,
                privateKey: keyPair.privateKey,
                publicKey: keyPair.publicKey
            )
        } catch {
            SystemLogger.log(message: "new encryption kit error: \(error)", category: .encryption, isError: true)
            return nil
        }
    }

    private func saveDeviceRegistrationInCache(token: String, kit: EncryptionKit) {
        serialQueue.sync {
            var kits = dependencies.encryptionKitsCache.get() ?? []
            if kits.isEmpty {
                kits.append(kit)
            } else {
                guard !kits.contains(kit) else { return }
                kits.insert(kit, at: 0)
                if kits.count > PushEncryptionManager.maxNumberOfKitsInCache {
                    kits.removeLast()
                }
            }
            dependencies.encryptionKitsCache.set(newValue: kits)
            dependencies.pushEncryptionProvider.lastRegisteredDeviceToken = token
        }
    }
}

extension PushEncryptionManager {

    struct BulkRequestResult {
        let successfulSessionIDs: Set<String>
        let failedSessionIDs: Set<String>

        var someFailed: Bool {
            !failedSessionIDs.isEmpty
        }

        var atLeastOneSucceeded: Bool {
            !successfulSessionIDs.isEmpty
        }
    }

    struct Dependencies {
        let usersManagers: UsersManager
        let deviceRegistration: DeviceRegistrationUseCase
        let encryptionKitsCache: Saver<[EncryptionKit]>
        let pushEncryptionProvider: PushEncryptionProvider
        let failedPushDecryptionProvider: FailedPushDecryptionProvider

        init(
            usersManager: UsersManager,
            deviceRegistration: DeviceRegistrationUseCase,
            encryptionKitsCache: Saver<[EncryptionKit]> = PushEncryptionKitSaver.shared.saver,
            pushEncryptionProvider: PushEncryptionProvider = UserDefaults.standard,
            failedPushDecryptionDefaults: FailedPushDecryptionProvider = SharedUserDefaults.shared
        ) {
            self.usersManagers = usersManager
            self.deviceRegistration = deviceRegistration
            self.encryptionKitsCache = encryptionKitsCache
            self.pushEncryptionProvider = pushEncryptionProvider
            self.failedPushDecryptionProvider = failedPushDecryptionDefaults
        }
    }
}
