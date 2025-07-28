//
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
import PaymentsNG
import proton_app_uniffi

/// The purpose of the container is to ensure that all IAP-related classes use the same instance of PlansComposerRust, because it is stateful.
public final class IAPContainer: ObservableObject {
    public let upsellOfferProvider: UpsellOfferProvider
    public let upsellScreenFactory: UpsellScreenFactory

    public init(mailUserSession: MailUserSession, arePaymentsEnabled: Bool) {
        let plansComposer = PlansComposerRust(rustSession: mailUserSession)
        let plansManager = ProtonPlansManager(plansComposer: plansComposer, rustSession: mailUserSession)

        upsellOfferProvider = .init(onlineExecutor: mailUserSession, plansComposer: plansComposer)
        upsellScreenFactory = .init(planPurchasing: arePaymentsEnabled ? plansManager : DummyPlanPurchasing())
    }
}
