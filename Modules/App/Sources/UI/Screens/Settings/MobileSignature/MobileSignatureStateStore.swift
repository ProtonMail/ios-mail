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
import InboxCore
import InboxCoreUI
import proton_app_uniffi

@MainActor
final class MobileSignatureStateStore: StateStore {
    @Published var state: MobileSignatureState = .initial

    private let customSettings: CustomSettingsProtocol
    private let clock: any Clock<Duration>

    private var debouncedTask: Task<Void, Error>? {
        didSet {
            oldValue?.cancel()
        }
    }

    init(customSettings: CustomSettingsProtocol, clock: any Clock<Duration> = ContinuousClock()) {
        self.customSettings = customSettings
        self.clock = clock
    }

    func handle(action: MobileSignatureStateStoreAction) async {
        do {
            switch action {
            case .onLoad:
                let mobileSignature = try await customSettings.mobileSignature().get()
                state = state.copy(\.mobileSignature, to: mobileSignature)
            case .setIsEnabled(let isEnabled):
                state = state.copy(\.mobileSignature.status.isEnabled, to: isEnabled)
                try await customSettings.setMobileSignatureEnabled(enabled: isEnabled).get()
            case .saveContent:
                let newContent = state.mobileSignature.body

                try await debounce(for: .seconds(3)) { [customSettings] in
                    try await customSettings.setMobileSignature(signature: newContent).get()
                }
            }
        } catch {
            AppLogger.log(error: error, category: .appSettings)
            state.toast = .error(message: error.localizedDescription)
        }
    }

    private func debounce(for duration: Duration, block: @escaping () async throws -> Void) async throws {
        try await withCheckedThrowingContinuation { continuation in
            debouncedTask = Task {
                let result: Result<Void, Error>

                do {
                    try await clock.sleep(for: duration)
                    try await block()
                    result = .success(())
                } catch is CancellationError {
                    result = .success(())
                } catch {
                    result = .failure(error)
                }

                continuation.resume(with: result)
            }
        }
    }
}
