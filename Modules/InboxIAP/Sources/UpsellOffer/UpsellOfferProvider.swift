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

import InboxCore
@preconcurrency import PaymentsNG
import proton_app_uniffi

public final class UpsellOfferProvider {
    private let onlineExecutor: OnlineExecutor
    private let plansComposer: PlansComposerProviding

    init(onlineExecutor: OnlineExecutor, plansComposer: PlansComposerProviding) {
        self.onlineExecutor = onlineExecutor
        self.plansComposer = plansComposer
    }

    public func findOffer(for planName: String) async -> UpsellOffer? {
        await executeWhenOnline { [plansComposer] in
            do {
                let availableComposedPlans = try await plansComposer.fetchAvailablePlans()
                let composedPlanToUpsell = availableComposedPlans.filter { $0.plan.name == planName }

                guard !composedPlanToUpsell.isEmpty else {
                    return nil
                }

                return .init(composedPlans: composedPlanToUpsell)
            } catch {
                AppLogger.log(error: error, category: .payments)
                return nil
            }
        }
    }

    private func executeWhenOnline<Output>(block: @escaping @Sendable () async -> Output) async -> Output {
        await withCheckedContinuation { continuation in
            let callback = LiveQueryCallbackWrapper {
                Task {
                    let output = await block()
                    continuation.resume(returning: output)
                }
            }

            onlineExecutor.executeWhenOnline(callback: callback)
        }
    }
}
