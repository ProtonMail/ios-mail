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

import ProtonCoreUIFoundations
import SwiftUI

public struct OnboardingUpsellPage: View {
    @ObservedObject private var model: OnboardingUpsellPageModel

    @Environment(\.presentationMode)
    private var presentationMode

    @Environment(\.verticalSizeClass)
    private var verticalSizeClass

    private let onPurchaseTapped: (String) -> Void

    public var body: some View {
        if verticalSizeClass == .compact {
            HStack {
                planList

                VStack {
                    choosePlanLabel

                    cyclePicker

                    Spacer()

                    ctaButton
                }
            }
            .background(Color(white: 250 / 255))
        } else {
            VStack(spacing: 0) {
                choosePlanLabel

                planList

                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(ColorProvider.Shade20)

                Spacer()
                    .frame(height: 8)

                ctaButton
            }
            .background(Color(white: 250 / 255))
        }
    }

    private var choosePlanLabel: some View {
        Text(L10n.Upsell.chooseAPlan)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(ColorProvider.TextNorm)
            .padding(.vertical, 16)
    }

    private var cyclePicker: some View {
        ZStack(alignment: .topTrailing) {
            SegmentedControl(
                options: [
                    .init(title: L10n.Recurrence.monthly, value: OnboardingUpsellPageModel.Cycle.monthly),
                    .init(title: L10n.Upsell.annual, value: OnboardingUpsellPageModel.Cycle.annual)
                ],
                selectedValue: $model.selectedCycle
            )

            Text(String(format: L10n.Upsell.save, model.maxDiscountForSelectedPlan ?? 0))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ColorProvider.TextInverted)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background {
                    Capsule()
                        .foregroundStyle(ColorProvider.IconAccent)
                }
                .alignmentGuide(VerticalAlignment.top) { dimension in
                    dimension[VerticalAlignment.bottom] - 2
                }
                .visible(model.maxDiscountForSelectedPlan != nil)
        }
    }

    private var planList: some View {
        ScrollView(showsIndicators: false) {
            if verticalSizeClass != .compact {
                cyclePicker

                Spacer()
                    .frame(height: 8)
            }

            Spacer()
                .frame(height: 16)

            ForEach(Array(zip(model.tiles.indices, model.tiles)), id: \.0) { index, tileModel in
                Tile(
                    model: tileModel,
                    selectedCycle: model.selectedCycle,
                    isSelected: index == model.selectedPlanIndex
                )
                .onTapGesture {
                    model.selectedPlanIndex = index
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var ctaButton: some View {
        VStack {
            if let actualChargeDisclaimer = model.actualChargeDisclaimer {
                Text(actualChargeDisclaimer)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(ColorProvider.BrandDarken20)
            }

            Button(
                action: {
                    if let selectedPlanIdentifier = model.selectedPlanIdentifier {
                        onPurchaseTapped(selectedPlanIdentifier)
                    } else {
                        onFreePlanSelected()
                    }
                },
                label: {
                    ZStack {
                        Text(model.ctaButtonTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundColor(.white)
                            .visible(!model.isBusy)

                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .visible(model.isBusy)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 36)
                    .background(ColorProvider.InteractionNorm)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            )

            if model.showGetProtonFreeButton {
                Spacer()
                    .frame(height: 16)

                Button(model.getFreePlanButtonTitle) {
                    onFreePlanSelected()
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(ColorProvider.BrandDarken20)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }

    public init(model: OnboardingUpsellPageModel, onPurchaseTapped: @escaping (String) -> Void) {
        self.model = model
        self.onPurchaseTapped = onPurchaseTapped
    }

    private func onFreePlanSelected() {
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    OnboardingUpsellPage(
        model: .init(
            tiles: [
                OnboardingUpsellPageModel.TileModel(
                    planName: "Proton Unlimited",
                    perks: [
                        .init(icon: \.storage, description: "500 GB storage"),
                        .init(icon: \.lock, description: "End-to-end encryption"),
                        .init(icon: \.envelope, description: "15 email addresses"),
                        .init(icon: \.globe, description: "Support for 3 custom email domains"),
                        .init(icon: \.tag, description: "Unlimited folders, labels, and filters"),
                        .init(icon: \.calendarCheckmark, description: "25 personal calendars"),
                        .init(icon: \.shield, description: "High-speed VPN on 10 devices")
                    ],
                    monthlyPricesPerCycle: [:],
                    isBestValue: true,
                    maxDiscount: 24,
                    alwaysVisiblePerks: 4,
                    storeKitProductIDsPerCycle: [:],
                    billingPricesPerCycle: [:],
                    includedProducts: [.mail, .calendar, .drive, .vpn, .pass]
                ),
                .init(
                    planName: "Mail Plus",
                    perks: [
                        .init(icon: \.storage, description: "15 GB storage"),
                        .init(icon: \.lock, description: "End-to-end encryption"),
                        .init(icon: \.envelope, description: "10 email addresses"),
                        .init(icon: \.globe, description: "Support for 1 custom email domain"),
                        .init(icon: \.tag, description: "Unlimited folders, labels, and filters"),
                        .init(icon: \.calendarCheckmark, description: "25 personal calendars")
                    ],
                    monthlyPricesPerCycle: [:],
                    isBestValue: false,
                    maxDiscount: 20,
                    alwaysVisiblePerks: 3,
                    storeKitProductIDsPerCycle: [:],
                    billingPricesPerCycle: [:],
                    includedProducts: [.mail, .calendar]
                ),
                .init(
                    planName: "Proton Free",
                    perks: [
                        .init(icon: \.storage, description: "1 GB Storage and 1 email"),
                        .init(icon: \.lock, description: "End-to-end encryption"),
                    ],
                    monthlyPricesPerCycle: [:],
                    isBestValue: false,
                    maxDiscount: nil,
                    alwaysVisiblePerks: 2,
                    storeKitProductIDsPerCycle: [:],
                    billingPricesPerCycle: [:],
                    includedProducts: nil
                )
            ]
        ),
        onPurchaseTapped: { _ in }
    )
}
