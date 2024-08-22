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

extension OnboardingUpsellPage {
    struct Tile: View {
        @State var model: OnboardingUpsellPageModel.TileModel
        let selectedCycle: OnboardingUpsellPageModel.Cycle
        let isSelected: Bool

        private var highlightGradient: LinearGradient {
            .init(
                colors: [.onboardingUpsellPageHighlightGradientStart, .onboardingUpsellPageHighlightGradientEnd],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        private var nonSelectionGradient: LinearGradient {
            .init(
                colors: [.onboardingUpsellPageNonSelectionGradientStart, .onboardingUpsellPageNonSelectionGradientEnd],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        var body: some View {
            VStack(spacing: 0) {
                if model.isBestValue {
                    ZStack {
                        Rectangle()
                            .foregroundStyle(highlightGradient)

                        Text(L10n.Upsell.bestValue)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(8)
                    }
                }

                VStack(alignment: .leading) {
                    Group {
                        isSelected ? IconProvider.checkmarkCircleFilled : IconProvider.emptyCircle
                    }
                    .foregroundStyle(ColorProvider.IconAccent)

                    HStack {
                        Spacer()

                        // we're not using `if let` intentionally to make sure the space is always reserved
                        Text(model.monthlyPriceBeforeDiscount(cycle: selectedCycle) ?? " ")
                            .strikethrough()
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(ColorProvider.TextWeak)
                    }

                    HStack(spacing: 0) {
                        Text(model.planName.hasSuffix("Unlimited") ? "Unlimited" : model.planName)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(ColorProvider.BrandDarken40)

                        Spacer()

                        if let monthlyPriceAfterDiscount = model.monthlyPriceAfterDiscount(cycle: selectedCycle) {
                            Text(monthlyPriceAfterDiscount)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(ColorProvider.TextNorm)

                            Text(" ")

                            Text(L10n.Upsell.perMonth)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(ColorProvider.TextWeak)
                        }
                    }

                    ForEach(model.visiblePerks, id: \.self) { perk in
                        HStack {
                            IconProvider[dynamicMember: perk.icon]
                                .foregroundStyle(ColorProvider.IconNorm)
                                .padding(4)
                                .background(Circle().foregroundStyle(ColorProvider.Shade10))

                            Text(perk.description)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(ColorProvider.TextNorm)
                        }
                    }

                    if model.showExpandButton {
                        Button(
                            action: {
                                model.isExpanded.toggle()
                            },
                            label: {
                                HStack(spacing: 4) {
                                    Text(model.nMoreFeaturesLabel)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(ColorProvider.TextAccent)

                                    model.expandButtonIcon
                                        .resizable()
                                        .frame(width: 18, height: 18)
                                        .foregroundStyle(ColorProvider.IconAccent)
                                }
                            }
                        )
                    }
                }
                .padding([.top, .horizontal], 16)
                .padding(.bottom, 24)
            }
            .background(ColorProvider.BackgroundNorm)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? highlightGradient : nonSelectionGradient,
                        lineWidth: isSelected ? 3 : 1.5
                    )
            }
        }
    }
}

#Preview {
    ScrollView {
        OnboardingUpsellPage.Tile(
            model: .init(
                planName: "Proton Unlimited",
                perks: [
                    .init(icon: \.storage, description: "500 GB storage"),
                    .init(icon: \.storage, description: "500 GB storage"),
                    .init(icon: \.storage, description: "500 GB storage"),
                    .init(icon: \.storage, description: "500 GB storage"),
                    .init(icon: \.storage, description: "500 GB storage")
                ],
                monthlyPricesPerCycle: [
                    1: "CHF 4.99"
                ],
                isBestValue: true,
                alwaysVisiblePerks: 3,
                storeKitProductIDsPerCycle: [:],
                billingPricesPerCycle: [:]
            ),
            selectedCycle: .monthly,
            isSelected: true
        )
    }
    .padding(16)
}
