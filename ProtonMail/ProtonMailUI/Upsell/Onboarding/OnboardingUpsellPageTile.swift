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

import ProtonCoreDataModel
import ProtonCoreUIFoundations
import SwiftUI

extension OnboardingUpsellPage {
    struct Tile: View {
        @State var model: OnboardingUpsellPageModel.TileModel
        let selectedCycle: OnboardingUpsellPageModel.Cycle
        let isSelected: Bool

        var body: some View {
            VStack(spacing: 0) {
                if model.isBestValue {
                    ZStack {
                        Rectangle()
                            .foregroundStyle(ColorProvider.BrandNorm)

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
                    .animation(.spring, value: isSelected)

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
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(ColorProvider.IconNorm)
                                .padding(7)
                                .background(Circle().foregroundStyle(ColorProvider.Shade10))

                            Text(perk.description)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(ColorProvider.TextNorm)
                        }
                    }

                    if let includedProducts = model.includedProducts, model.isExpanded {
                        Spacer()
                            .frame(height: 24)

                        Text(L10n.Upsell.premiumValueIncluded)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(ColorProvider.BrandDarken40)

                        Spacer()
                            .frame(height: 12)

                        HStack {
                            ForEach(includedProducts, id: \.name) { includedProduct in
                                includedProduct
                                    .icon
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            }
                        }

                        Spacer()
                            .frame(height: 16)
                    }

                    if model.showExpandButton {
                        Button(
                            action: {
                                withAnimation(.spring) {
                                    model.isExpanded.toggle()
                                }
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
            .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
            .padding(2)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? ColorProvider.BrandNorm : .clear,
                        lineWidth: 3
                    )
                    .animation(.spring, value: isSelected)
            }
        }
    }
}

private extension ClientApp {
    var icon: Image {
        let imageName: String

        switch self {
        case .mail:
            imageName = "LaunchScreenMailLogo"
        case .vpn:
            imageName = "LaunchScreenVPNLogo"
        case .drive:
            imageName = "LaunchScreenDriveLogo"
        case .calendar:
            imageName = "LaunchScreenCalendarLogo"
        case .pass:
            imageName = "LaunchScreenPassLogo"
        case .wallet, .other:
            fatalError("not reachable")
        }

        return Image(imageName, bundle: PMUIFoundations.bundle)
    }
}

#Preview {
    ScrollView {
        OnboardingUpsellPage.Tile(
            model: .init(
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
                monthlyPricesPerCycle: [
                    1: "CHF 4.99"
                ],
                isBestValue: true,
                maxDiscount: 24,
                alwaysVisiblePerks: 4,
                storeKitProductIDsPerCycle: [:],
                billingPricesPerCycle: [:],
                includedProducts: [.mail, .calendar, .drive, .vpn, .pass]
            ),
            selectedCycle: .monthly,
            isSelected: true
        )
    }
    .padding(16)
}
