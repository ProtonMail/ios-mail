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
import InboxCoreUI
import proton_app_uniffi
import ProtonUIFoundations
import SwiftUI

@MainActor
final class WebCheckout {
    private let sessionForking: SessionForking
    private let upsellConfiguration: UpsellConfiguration

    init(sessionForking: SessionForking, upsellConfiguration: UpsellConfiguration) {
        self.sessionForking = sessionForking
        self.upsellConfiguration = upsellConfiguration
    }

    func initiate(
        for wave: BlackFridayWave,
        isBusy: Binding<Bool>,
        toastStateStore: ToastStateStore,
        openURL: (URL) -> Void,
        dismiss: () -> Void
    ) async {
        AppLogger.log(message: "Will fork the session to enable web checkout", category: .payments)

        isBusy.wrappedValue = true

        defer {
            isBusy.wrappedValue = false
        }

        do {
            let url = try await checkoutURL(wave: wave)

            AppLogger.log(message: "Forking successful", category: .payments)

            dismiss()

            openURL(url)
        } catch {
            AppLogger.log(error: error, category: .payments)
            toastStateStore.present(toast: .error(message: error.localizedDescription))
        }
    }

    private func checkoutURL(wave: BlackFridayWave) async throws -> URL {
        let checkoutPlatform = "web"
        let checkoutApp = "account-lite"
        let checkoutAppVersion = "5.0.304.0"

        let selector = try await sessionForking.fork(platform: checkoutPlatform, product: checkoutApp).get()

        let queryItems: [URLQueryItem] = [
            .init(name: "action", value: "subscribe-account"),
            .init(name: "app-version", value: "\(checkoutPlatform)-\(checkoutApp)@\(checkoutAppVersion)"),
            .init(name: "coupon", value: wave.discountCoupon),
            .init(name: "currency", value: "USD"),
            .init(name: "cycle", value: "\(wave.cycle)"),
            .init(name: "disableCycleSelector", value: "1"),
            .init(name: "disablePlanSelection", value: "1"),
            .init(name: "fullscreen", value: "auto"),
            .init(name: "hideClose", value: "true"),
            .init(name: "plan", value: upsellConfiguration.regularPlan),
            .init(name: "redirect", value: "\(Bundle.URLScheme.protonmail.rawValue)://"),
            .init(name: "start", value: "checkout"),
        ]

        var urlComponents = URLComponents(string: "https://account.\(upsellConfiguration.apiEnvId.domain)/lite")!
        urlComponents.queryItems = queryItems
        urlComponents.fragment = "selector=\(selector)"
        return urlComponents.url!
    }
}

private extension BlackFridayWave {
    var cycle: Int {
        switch self {
        case .wave1:
            12
        case .wave2:
            1
        }
    }

    var discountCoupon: String {
        switch self {
        case .wave1:
            "BF25PROMO"
        case .wave2:
            "BF25PROMO1M"
        }
    }
}

extension WebCheckout {
    static let dummy = WebCheckout(
        sessionForking: DummySessionForking(),
        upsellConfiguration: .dummy
    )
}
