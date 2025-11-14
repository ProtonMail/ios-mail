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

@testable import ProtonMail

import InboxCore
import InboxCoreUI
import proton_app_uniffi
import ProtonUIFoundations
import Testing

@MainActor
final class SignaturesStateStoreTests {
    private let customSettings = CustomSettingsSpy()
    private let router = Router<SettingsRoute>()
    private let toastStateStore = ToastStateStore(initialState: .initial)
    private let upsellPresenter = UpsellScreenPresenterSpy()

    private lazy var sut = SignaturesStateStore(
        state: .initial,
        customSettings: customSettings,
        router: router,
        toastStateStore: toastStateStore,
        upsellPresenter: upsellPresenter
    )

    @Test(arguments: [MobileSignatureStatus.enabled, .disabled, .needsPaidVersion])
    func onAppear_updatesMobileSignatureStatus(mobileSignatureStatus: MobileSignatureStatus) async {
        customSettings.stubbedMobileSignature.status = mobileSignatureStatus

        await sut.handle(action: .onAppear)

        #expect(sut.state.mobileSignatureStatus == mobileSignatureStatus)
    }

    @Test
    func mobileSignatureTapped_whenUserIsPaid_opensEditScreen() async {
        sut.state.mobileSignatureStatus = .disabled

        await sut.handle(action: .mobileSignatureTapped)

        #expect(router.stack == [.mobileSignature])
        #expect(upsellPresenter.presentUpsellScreenCalled == [])
    }

    @Test
    func mobileSignatureTapped_whenUserIsFree_presentsUpsell() async {
        sut.state.mobileSignatureStatus = .needsPaidVersion

        await sut.handle(action: .mobileSignatureTapped)

        #expect(router.stack == [])
        #expect(upsellPresenter.presentUpsellScreenCalled == [.mobileSignatureEdit])
    }
}
