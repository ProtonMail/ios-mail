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
final class LegacyMigrationStateStore: ObservableObject, Sendable {
    enum State {
        case checkingIfMigrationIsNeeded
        case inProgress
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
                    unlockMainKeyAndResumeMigration()
                case .failed:
                    finishMigrationWithGenericError()
                }
            }
        }
    }

    private func unlockMainKeyAndResumeMigration() {
        Task {
            do {
                switch try mainKeyUnlocker.legacyAppProtectionMethod() {
                case .biometrics:
                    let mainKey = try mainKeyUnlocker.biometricsProtectedMainKey()
                    await legacyMigrationService.resume(protectedMainKey: mainKey)
                case .pin:
                    state = .willNotMigrate
                    toastStateStore.present(
                        toast: .migrationError(
                            message: "Migrating a PIN-protected account is not supported yet."
                        )
                    )
                case .none:
                    break
                }
            } catch {
                AppLogger.log(error: error, category: .legacyMigration)
                finishMigrationWithGenericError()
            }
        }
    }

    private func finishMigrationWithGenericError() {
        state = .willNotMigrate
        toastStateStore.present(toast: .migrationError(message: L10n.LegacyMigration.migrationFailed.string))
    }
}

private extension Toast {
    static func migrationError(message: String) -> Toast {
        .error(message: message).duration(.toastMediumDuration)
    }
}
