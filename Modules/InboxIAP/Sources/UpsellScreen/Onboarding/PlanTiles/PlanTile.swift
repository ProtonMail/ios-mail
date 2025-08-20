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

import InboxCoreUI
import InboxDesignSystem
import PaymentsNG
import SwiftUI
import UIFoundations

struct PlanTile: View {
    let model: PlanTileModel
    let onGetPlanTapped: (String?) async -> Void

    var body: some View {
        VStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: DS.Spacing.small) {
                HStack(spacing: DS.Spacing.compact) {
                    planName

                    if model.isBestValue {
                        bestValue
                    }
                }

                monthlyPrice

                if let discount = model.discount {
                    discountLabel(discount: discount)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer.exactly(DS.Spacing.huge)

            entitlements
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer.exactly(DS.Spacing.huge)

            getPlanButton

            Spacer.exactly(DS.Spacing.mediumLight)

            if let billingNotice = model.billingNotice {
                billingNoticeLabel(billingNotice: billingNotice)
            }
        }
        .padding(DS.Spacing.extraLarge)
        .background {
            RoundedRectangle(cornerRadius: DS.Radius.massive)
                .fill(DS.Color.BackgroundInverted.secondary)
                .shadow(DS.Shadows.softFull, isVisible: true)
        }
    }

    private var planName: some View {
        Text(model.planName)
            .font(.callout)
            .fontWeight(.bold)
            .foregroundStyle(DS.Color.Brand.plus30)
    }

    private var bestValue: some View {
        Text(L10n.bestValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Color.Brand.plus30)
            .padding(.vertical, DS.Spacing.small)
            .padding(.horizontal, DS.Spacing.standard)
            .background {
                RoundedRectangle(cornerRadius: DS.Radius.medium)
                    .fill(DS.Color.Brand.minus30)
            }
    }

    private var monthlyPrice: some View {
        HStack {
            Text(model.monthlyPrice)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(DS.Color.Text.norm)

            Text(L10n.perMonth)
                .font(.footnote)
                .foregroundStyle(DS.Color.Text.weak)
        }
    }

    private func discountLabel(discount: PlanTileData.Discount) -> some View {
        Text(L10n.payAnnuallyAndSave(amount: discount.savedAmount))
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Color.Brand.norm)
    }

    private var entitlements: some View {
        Grid(alignment: .leading, horizontalSpacing: DS.Spacing.medium, verticalSpacing: DS.Spacing.medium) {
            ForEach(model.entitlements, id: \.self) { entitlement in
                gridRow(icon: entitlement.icon, text: entitlement.text)
            }
            .animation(.easeInOut, value: model.areEntitlementsExpanded)

            if model.isExpandingButtonVisible {
                Button {
                    withAnimation {
                        model.areEntitlementsExpanded.toggle()
                    }
                } label: {
                    entitlementListExpansionToggle
                }
            }
        }
    }

    private func gridRow(icon: ImageResource, text: String) -> some View {
        GridRow {
            Image(icon)
                .tint(DS.Color.Icon.norm)
                .padding(DS.Spacing.small)
                .background {
                    RoundedRectangle(cornerRadius: DS.Radius.medium)
                        .fill(DS.Color.Background.deep)
                }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(DS.Color.Text.norm)
                .multilineTextAlignment(.leading)
        }
    }

    private var entitlementListExpansionToggle: some View {
        if model.areEntitlementsExpanded {
            gridRow(icon: DS.Icon.icChevronTinyUp, text: L10n.showLess.string)
        } else {
            gridRow(icon: DS.Icon.icChevronTinyDown, text: L10n.showMore.string)
        }
    }

    private var getPlanButton: some View {
        ZStack {
            Button(model.getPlanButtonTitle.string) {
                Task {
                    await model.performWhileDisabled {
                        await onGetPlanTapped(model.storeKitProductID)
                    }
                }
            }
            .buttonStyle(BigButtonStyle(flavor: model.getPlanButtonFlavor))
            .visible(!model.isGetButtonDisabled)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DS.Color.Brand.norm))
                .visible(model.isGetButtonDisabled)
        }
    }

    private func billingNoticeLabel(billingNotice: LocalizedStringResource) -> some View {
        Text(billingNotice)
            .font(.caption)
            .foregroundStyle(DS.Color.Brand.plus10)
    }
}

private extension DescriptionEntitlement {
    var icon: ImageResource {
        .init(name: "ic-\(iconName)", bundle: .designSystem)
    }
}

#Preview {
    ZStack {
        DS.Color.BackgroundInverted.norm

        ScrollView {
            ForEach(PlanTileData.previews, id: \.self) { planTileData in
                let model = PlanTileModel(planTileData: planTileData)

                PlanTile(model: model) { _ in
                    try! await Task.sleep(for: .seconds(2))
                }
            }
        }
    }
}
