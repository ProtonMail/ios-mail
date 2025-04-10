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

@preconcurrency import Combine
import Foundation
import InboxCore
import InboxCoreUI

@MainActor
final class LegacyMigrationStateStore: ObservableObject {
    enum State {
        case checkingIfMigrationIsNeeded
        case inProgress
        case biometricUnlockRequired
        case pinRequired(errorFromLatestAttempt: String?)
        case willNotMigrate
    }

    @Published private(set) var state: State = .checkingIfMigrationIsNeeded

    private let legacyMigrationService = LegacyMigrationService.shared
    private let mainKeyUnlocker = MainKeyUnlocker()
    private let toastStateStore: ToastStateStore

    init(toastStateStore: ToastStateStore) {
        self.toastStateStore = toastStateStore

        Task { [weak self] in
            guard let self else { return }

            for await nextServiceState in await legacyMigrationService.statePublisher.values {
                switch nextServiceState {
                case .notChecked:
                    break
                case .notNeeded:
                    state = .willNotMigrate
                case .inProgress:
                    state = .inProgress
                case .awaitingProtectedMainKey:
                    state = .inProgress
                    promptUserToUnlockMainKey()
                case .failed:
                    toastStateStore.present(toast: .migrationError)
                }
            }
        }
    }

    func resumeMigration(using pin: String) {
        Task {
            do {
                let mainKey = try await mainKeyUnlocker.pinProtectedMainKey(pin: pin)
                await legacyMigrationService.resume(protectedMainKey: mainKey, protectionPreference: .pin(pin))
            } catch {
                AppLogger.log(error: error, category: .legacyMigration)
                state = .pinRequired(errorFromLatestAttempt: L10n.PINLock.invalidPIN.string)
            }
        }
    }

    func resumeByRequestABiometryCheck() async throws {
        let mainKey = try await mainKeyUnlocker.biometricsProtectedMainKey()

        Task {
            await legacyMigrationService.resume(protectedMainKey: mainKey, protectionPreference: .biometrics)
        }
    }

    func abortMigration() {
        Task {
            await legacyMigrationService.abortWithoutProvidingProtectedMainKey()
        }
    }

    private func promptUserToUnlockMainKey() {
        Task {
            do {
                switch try await mainKeyUnlocker.legacyAppProtectionMethod() {
                case .biometrics:
                    state = .biometricUnlockRequired
                case .pin:
                    state = .pinRequired(errorFromLatestAttempt: nil)
                case .none:
                    finishMigrationWithGenericError()
                }
            } catch {
                AppLogger.log(error: error, category: .legacyMigration)
                finishMigrationWithGenericError()
            }
        }
    }

    private func finishMigrationWithGenericError() {
        abortMigration()
        toastStateStore.present(toast: .migrationError)
    }
}

private extension Toast {
    static var migrationError: Toast {
        .error(message: L10n.LegacyMigration.migrationFailed.string).duration(.toastMediumDuration)
    }
}
