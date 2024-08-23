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

struct UpsellCTATile: View {
    let planName: String
    let purchasingOption: UpsellPageModel.PurchasingOption
    let onTap: () -> Void

    private static let planDurationFormatter: Formatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = .month
        formatter.unitsStyle = .full
        return formatter
    }()

    private var borderColor: Color {
        purchasingOption.isHighlighted ? ColorProvider.BrandLighten40 : Color.white.opacity(0.08)
    }

    private let cornerRadius = 16.0

    private var discountGradient: LinearGradient {
        .init(
            colors: [.discountGradientStart, .discountGradientEnd],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    var body: some View {
        ZStack {
            VStack(spacing: 14) {
                VStack(spacing: 12) {
                    Text(DateComponents(month: purchasingOption.cycleInMonths), formatter: Self.planDurationFormatter)
                        .font(Font(UIFont.adjustedFont(forTextStyle: .caption2)))
                        .foregroundColor(.white)

                    Text(purchasingOption.monthlyPrice)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    +
                    Text(L10n.Upsell.perMonth)
                        .font(Font(UIFont.adjustedFont(forTextStyle: .caption2)))
                        .foregroundColor(ColorProvider.SidebarTextWeak)
                }

                Button(
                    action: {
                        onTap()
                    },
                    label: {
                        Text(String(format: L10n.Upsell.getPlan, planName))
                            .lineLimit(1)
                            .fixedSize()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(purchasingOption.isHighlighted ? ColorProvider.InteractionNorm : Color.white.opacity(0.16))
                            .clipShape(Capsule())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                )
            }
            .padding([.top], 24)
            .padding([.horizontal, .bottom], 16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(borderColor, lineWidth: 1)
                    .background(RoundedRectangle(cornerRadius: cornerRadius).fill(Color.white.opacity(0.04)))
            )
            .alignmentGuide(VerticalAlignment.center) { $0[.top] }

            if let discount = purchasingOption.discount {
                Text(String(format: L10n.Upsell.save, discount).uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundColor(ColorProvider.SidebarBackground)
                    .background(discountGradient.cornerRadius(4))
            }
        }
    }
}
