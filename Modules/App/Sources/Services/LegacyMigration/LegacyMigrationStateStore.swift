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

    init(toastStateStore: ToastStateStore) {
        Task { [weak self] in
            guard let self else { return }

            for await nextServiceState in await legacyMigrationService.statePublisher.values {
                let (nextState, toast) = mapped(serviceState: nextServiceState)

                state = nextState

                if let toast {
                    toastStateStore.present(toast: toast)
                }
            }
        }
    }

    private func mapped(serviceState: LegacyMigrationService.MigrationState) -> (State, Toast?) {
        switch serviceState {
        case .notChecked:
            (.checkingIfMigrationIsNeeded, nil)
        case .notNeeded:
            (.willNotMigrate, nil)
        case .inProgress:
            (.inProgress, nil)
        case .awaitingProtectedMainKey:
            (
                .willNotMigrate,
                .migrationError(message: "Migrating a PIN- or Face ID-protected account is not supported yet.")
            )
        case .failed:
            (.willNotMigrate, .migrationError(message: L10n.LegacyMigration.migrationFailed.string))
        }
    }
}

private extension Toast {
    static func migrationError(message: String) -> Toast {
        .error(message: message).duration(.toastMediumDuration)
    }
}
