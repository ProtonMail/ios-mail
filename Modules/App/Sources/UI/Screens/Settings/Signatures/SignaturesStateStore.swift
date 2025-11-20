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

import InboxCore
import InboxCoreUI
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

final class SignaturesStateStore: StateStore {
    @Published var state: SignaturesState

    private let customSettings: CustomSettingsProtocol
    private let router: Router<SettingsRoute>
    private let toastStateStore: ToastStateStore
    private let upsellPresenter: UpsellScreenPresenter

    init(
        state: SignaturesState,
        customSettings: CustomSettingsProtocol,
        router: Router<SettingsRoute>,
        toastStateStore: ToastStateStore,
        upsellPresenter: UpsellScreenPresenter
    ) {
        self.state = state
        self.customSettings = customSettings
        self.router = router
        self.toastStateStore = toastStateStore
        self.upsellPresenter = upsellPresenter
    }

    func handle(action: SignaturesAction) async {
        switch action {
        case .onAppear:
            await refreshCustomSettings()
        case .mobileSignatureTapped:
            await mobileSignatureTapped()
        }
    }

    private func refreshCustomSettings() async {
        do {
            let mobileSignature = try await customSettings.mobileSignature().get()
            state = state.copy(\.mobileSignatureStatus, to: mobileSignature.status)
        } catch {
            onError(error)
        }
    }

    private func mobileSignatureTapped() async {
        let needsPaidVersion = state.mobileSignatureStatus == .needsPaidVersion

        if needsPaidVersion {
            do {
                let upsellScreenModel = try await upsellPresenter.presentUpsellScreen(entryPoint: .mobileSignatureEdit)
                state = state.copy(\.presentedUpsell, to: upsellScreenModel)
            } catch {
                onError(error)
            }
        } else {
            router.go(to: .mobileSignature)
        }
    }

    private func onError(_ error: Error) {
        AppLogger.log(error: error, category: .appSettings)
        toastStateStore.present(toast: .error(message: error.localizedDescription))
    }
}
