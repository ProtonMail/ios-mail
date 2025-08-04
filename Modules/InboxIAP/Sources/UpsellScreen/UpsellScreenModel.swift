// Copyright (c) 2024 Proton Technologies AG
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
import PaymentsNG
import SwiftUI

@MainActor
@Observable
public final class UpsellScreenModel: Identifiable {
    let planName: String
    let planInstances: [DisplayablePlanInstance]
    let logoHeight: CGFloat = 118

    var logoScaleFactor: CGFloat = 1
    var logoOpacity: CGFloat = 1
    var isBusy = false
    var selectedInstanceId: String

    private let logoScaleFactorRange: ClosedRange<CGFloat> = 0.8...1
    private let logoOpacityRange: ClosedRange<CGFloat> = 0.2...1
    private let entryPoint: UpsellScreenEntryPoint
    private let planPurchasing: PlanPurchasing

    var logo: ImageResource {
        entryPoint.logo
    }

    var title: LocalizedStringResource {
        L10n.screenTitle(planName: planName, entryPoint: entryPoint)
    }

    var subtitle: LocalizedStringResource {
        L10n.screenSubtitle(planName: planName, entryPoint: entryPoint)
    }

    init(
        planName: String,
        planInstances: [DisplayablePlanInstance],
        entryPoint: UpsellScreenEntryPoint,
        planPurchasing: PlanPurchasing
    ) {
        self.planName = planName
        self.planInstances = planInstances
        self.entryPoint = entryPoint
        self.planPurchasing = planPurchasing
        selectedInstanceId = planInstances[0].storeKitProductId
    }

    func scrollingOffsetDidChange(newValue verticalOffset: CGFloat) {
        guard verticalOffset > 0 else { return }

        let ratio = 1 - min(verticalOffset / logoHeight, 1)
        let ratioRange: ClosedRange<CGFloat> = 0...1

        logoScaleFactor = ratio.normalize(inputRange: ratioRange, outputRange: logoScaleFactorRange)
        logoOpacity = ratio.normalize(inputRange: ratioRange, outputRange: logoOpacityRange)
    }

    func onPurchaseTapped(toastStateStore: ToastStateStore, dismiss: () -> Void) async {
        AppLogger.log(message: "Attempting to purchase \(selectedInstanceId)", category: .payments)

        isBusy = true

        defer {
            isBusy = false
        }

        do {
            try await planPurchasing.purchase(storeKitProductId: selectedInstanceId)

            AppLogger.log(message: "Purchase successful", category: .payments)

            dismiss()
        } catch {
            AppLogger.log(error: error, category: .payments)

            if let toast = toastToShowTheUser(basedOn: error) {
                toastStateStore.present(toast: toast)
            }
        }
    }

    private func toastToShowTheUser(basedOn error: Error) -> Toast? {
        switch error {
        case ProtonPlansManagerError.transactionCancelledByUser: nil
        case is IAPsNotAvailableInTestFlightError: .information(message: error.localizedDescription)
        default: .error(message: error.localizedDescription)
        }
    }
}

// This implementation of Equatable is only intended to enable testing state structures which UpsellScreenModel is a part of, to verify if the appropriate screen has been presented
extension UpsellScreenModel: Equatable {
    nonisolated public static func == (lhs: UpsellScreenModel, rhs: UpsellScreenModel) -> Bool {
        lhs.planName == rhs.planName
    }
}

private extension BinaryFloatingPoint {
    func normalize(inputRange: ClosedRange<Self>, outputRange: ClosedRange<Self>) -> Self {
        assert(inputRange.contains(self))
        return (outputRange.upperBound - outputRange.lowerBound) * ((self - inputRange.lowerBound) / (inputRange.upperBound - inputRange.lowerBound)) + outputRange.lowerBound
    }
}
