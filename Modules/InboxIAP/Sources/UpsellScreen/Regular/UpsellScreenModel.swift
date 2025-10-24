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

import InboxCoreUI
import InboxDesignSystem
import PaymentsNG
import proton_app_uniffi
import SwiftUI

@MainActor
@Observable
public final class UpsellScreenModel: Identifiable {
    let planName: String
    let planInstances: [DisplayablePlanInstance]

    var logoScaleFactor: CGFloat = 1
    var logoOpacity: CGFloat = 1
    var isBusy = false
    var selectedInstanceId: String

    private let logoScaleFactorRange: ClosedRange<CGFloat> = 0.8...1
    private let logoOpacityRange: ClosedRange<CGFloat> = 0.2...1
    private let entryPoint: UpsellEntryPoint
    private let upsellType: UpsellType
    private let purchaseActionPerformer: PurchaseActionPerformer

    var logo: ImageResource {
        switch upsellType {
        case .standard:
            entryPoint.logo
        case .blackFriday(.wave1):
            DS.Images.Upsell.BlackFriday.logo50
        case .blackFriday(.wave2):
            DS.Images.Upsell.BlackFriday.logo80
        }
    }

    var logoHeight: CGFloat? {
        isPromo ? nil : 118
    }

    var logoHorizontalPadding: CGFloat? {
        isPromo ? DS.Spacing.standard : nil
    }

    var title: LocalizedStringResource? {
        isPromo ? nil : L10n.screenTitle(planName: planName, entryPoint: entryPoint)
    }

    var subtitle: LocalizedStringResource? {
        isPromo ? nil : L10n.screenSubtitle(planName: planName, entryPoint: entryPoint)
    }

    var highlightStroke: (any ShapeStyle)? {
        isPromo ? DS.Color.Promo.blackFriday : nil
    }

    var ctaBackgroundOverride: Color? {
        isPromo ? DS.Color.Promo.blackFriday : nil
    }

    var autoRenewalNotice: LocalizedStringResource {
        switch planInstances[0].pricing {
        case .regular:
            L10n.autoRenewalNotice
        case .discountedYearlyPlan(_, _, let renewalPrice):
            L10n.discountRenewalNotice(renewalPrice: renewalPrice, period: .year)
        case .discountedMonthlyPlan(_, let renewalPrice):
            L10n.discountRenewalNotice(renewalPrice: renewalPrice, period: .month)
        }
    }

    var isPromo: Bool {
        switch upsellType {
        case .standard:
            false
        case .blackFriday:
            true
        }
    }

    init(
        planName: String,
        planInstances: [DisplayablePlanInstance],
        entryPoint: UpsellEntryPoint,
        upsellType: UpsellType,
        purchaseActionPerformer: PurchaseActionPerformer
    ) {
        self.planName = planName
        self.planInstances = planInstances
        self.entryPoint = entryPoint
        self.upsellType = upsellType
        self.purchaseActionPerformer = purchaseActionPerformer
        selectedInstanceId = planInstances[0].storeKitProductId
    }

    func scrollingOffsetDidChange(newValue verticalOffset: CGFloat) {
        guard verticalOffset > 0 else { return }

        let ratio = 1 - min(verticalOffset / 150, 1)
        let ratioRange: ClosedRange<CGFloat> = 0...1

        logoScaleFactor = ratio.normalize(inputRange: ratioRange, outputRange: logoScaleFactorRange)
        logoOpacity = ratio.normalize(inputRange: ratioRange, outputRange: logoOpacityRange)
    }

    func onPurchaseTapped(toastStateStore: ToastStateStore, dismiss: () -> Void) async {
        if isPromo {
            openWebPage()
        } else {
            await purchaseActionPerformer.purchase(
                storeKitProductID: selectedInstanceId,
                isBusy: .init(get: { self.isBusy }, set: { self.isBusy = $0 }),
                toastStateStore: toastStateStore,
                dismiss: dismiss
            )
        }
    }

    private func openWebPage() {

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
