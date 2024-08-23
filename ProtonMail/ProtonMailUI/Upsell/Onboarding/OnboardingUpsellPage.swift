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

    private let onPurchaseTapped: (String) -> Void

    private var backgroundGradient: LinearGradient {
        .init(
            colors: [.onboardingUpsellPageBackgroundGradientStart, .onboardingUpsellPageBackgroundGradientEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    public var body: some View {
        VStack {
            VStack {
                Text(L10n.Upsell.chooseAPlan)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ColorProvider.TextNorm)
                    .padding(.vertical, 16)

                ScrollView(showsIndicators: false) {
                    SegmentedControl(
                        options: [
                            .init(title: L10n.Recurrence.monthly, value: OnboardingUpsellPageModel.Cycle.monthly),
                            .init(title: L10n.Upsell.annual, value: OnboardingUpsellPageModel.Cycle.annual)
                        ],
                        selectedValue: $model.selectedCycle
                    )

                    Spacer()
                        .frame(height: 24)

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
            }
            .padding(.horizontal, 16)

            Rectangle()
                .frame(height: 1)
                .foregroundColor(ColorProvider.Shade20)

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
            .padding([.horizontal, .bottom], 32)
        }
        .background(backgroundGradient)
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
                        .init(icon: \.storage, description: "500 GB storage"),
                        .init(icon: \.storage, description: "500 GB storage"),
                        .init(icon: \.storage, description: "500 GB storage"),
                        .init(icon: \.storage, description: "500 GB storage")
                    ],
                    monthlyPricesPerCycle: [:],
                    isBestValue: true,
                    alwaysVisiblePerks: 3,
                    storeKitProductIDsPerCycle: [:],
                    billingPricesPerCycle: [:]
                ),
                .init(
                    planName: "Mail Plus",
                    perks: [
                        .init(icon: \.storage, description: "500 GB storage"),
                        .init(icon: \.storage, description: "500 GB storage"),
                        .init(icon: \.storage, description: "500 GB storage"),
                        .init(icon: \.storage, description: "500 GB storage"),
                        .init(icon: \.storage, description: "500 GB storage")
                    ],
                    monthlyPricesPerCycle: [:],
                    isBestValue: false,
                    alwaysVisiblePerks: 2,
                    storeKitProductIDsPerCycle: [:],
                    billingPricesPerCycle: [:]
                ),
                .init(
                    planName: "Proton Free",
                    perks: [
                        .init(icon: \.storage, description: "500 GB storage")
                    ],
                    monthlyPricesPerCycle: [:],
                    isBestValue: false,
                    alwaysVisiblePerks: 1,
                    storeKitProductIDsPerCycle: [:],
                    billingPricesPerCycle: [:]
                )
            ],
            maxDiscount: 20
        ),
        onPurchaseTapped: { _ in }
    )
}
