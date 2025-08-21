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

import Foundation
import InboxDesignSystem
import SwiftUI

struct SubscriptionPeriodRadioButton: View {
    let planInstance: DisplayablePlanInstance
    let isSelected: Bool
    let onTap: () -> Void

    private var backgroundColor: Color {
        .black.opacity(isSelected ? 0.4 : 0.2)
    }

    private var borderColor: some ShapeStyle {
        isSelected ? AnyShapeStyle(LinearGradient.highlight) : AnyShapeStyle(Color.clear)
    }

    private let borderWidth: CGFloat = 2
    private let cornerRadius = DS.Radius.extraLarge

    private let preferredMonthStyles: [DateComponentsFormatter.UnitsStyle] = [
        .full,
        .short,
        .brief,
        .abbreviated,
    ]

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(alignment: .center) {
                duration

                if let discount = planInstance.discount {
                    discountBadge(value: discount)
                }

                Spacer()

                monthlyPrice
            }
            .padding(.horizontal, DS.Spacing.large)
            .padding(.vertical, 22)
            .background(background)
            .alignmentGuide(VerticalAlignment.center) { $0[.top] }

            selectionIndicator
                .visible(isSelected)
        }
        .onTapGesture(perform: onTap)
    }

    private var duration: some View {
        ViewThatFits {
            ForEach(preferredMonthStyles.indices, id: \.self) { idx in
                Text(DateComponents(month: planInstance.cycleInMonths), formatter: planDurationFormatter(monthStyle: preferredMonthStyles[idx]))
                    .font(.body)
                    .foregroundColor(.white)
            }
        }
    }

    private func planDurationFormatter(monthStyle: DateComponentsFormatter.UnitsStyle) -> DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.month]
        formatter.unitsStyle = monthStyle
        return formatter
    }

    private func discountBadge(value: Int) -> some View {
        Text((-value).formatted(.percent))
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(Color.white)
            .padding(.horizontal, DS.Spacing.standard)
            .padding(.vertical, DS.Spacing.small)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
    }

    private var monthlyPrice: some View {
        Text(planInstance.monthlyPrice)
            .font(.body)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            + Text(" \(L10n.perMonth)")
            .font(.caption)
            .foregroundColor(Color.white.opacity(0.7))
    }

    private var selectionIndicator: some View {
        Image(symbol: .checkmarkCircleFill)
            .font(.system(size: 24))
            .symbolRenderingMode(.palette)
            .foregroundStyle(.black, .white)
            .padding(.trailing, DS.Spacing.extraLarge)
    }

    @ViewBuilder
    private var background: some View {
        let basicShape = RoundedRectangle(cornerRadius: cornerRadius)

        basicShape
            .strokeBorder(borderColor, lineWidth: borderWidth)
            .background(
                basicShape
                    .fill(backgroundColor)
                    .padding(borderWidth / 2)
            )
            .animation(.snappy, value: isSelected)
    }
}

#Preview {
    @Previewable @State var selectedInstanceID = DisplayablePlanInstance.previews[0].storeKitProductId

    SubscriptionPeriodRadioGroup(planInstances: DisplayablePlanInstance.previews, selectedInstanceID: $selectedInstanceID)
        .background(DS.Color.Brand.norm)
}
