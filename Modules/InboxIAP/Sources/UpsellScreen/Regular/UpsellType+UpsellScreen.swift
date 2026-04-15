//
// Copyright (c) 2026 Proton Technologies AG
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

import InboxDesignSystem
import SwiftUI
import proton_app_uniffi

extension UpsellType {
    var planVariant: String {
        switch self {
        case .mailPlus:
            SubscriptionPlanVariant.plus
        case .unlimited:
            SubscriptionPlanVariant.unlimited
        }
    }

    var logo: ImageResource {
        switch self {
        case .mailPlus:
            DS.Images.Upsell.logoDefault
        case .unlimited:
            DS.Images.Upsell.logoUnlimited
        }
    }

    var comparisonConfiguration: PlanComparisonGrid.Configuration {
        switch self {
        case .mailPlus:
            .init(
                planColumnHeader: .text(L10n.PlanName.plus),
                headerStroke: LinearGradient.highlight,
                items: Self.mailPlusComparisonItems
            )
        case .unlimited:
            .init(
                planColumnHeader: .icon(Image(DS.Icon.icInfinityUpsellHeader)),
                headerStroke: nil,
                items: Self.unlimitedComparisonItems
            )
        }
    }

    private static let mailPlusComparisonItems: [ComparisonItem] = [
        .init(title: \.storage, type: .string(free: gigabytesString(1), plan: gigabytesString(15))),
        .init(title: \.emailAddresses, type: .string(free: "1", plan: "10")),
        .init(title: \.customEmailDomain, type: .boolean),
        .init(title: \.accessToDesktopApp, type: .boolean),
        .init(title: \.unlimitedFoldersAndLabels, type: .boolean),
        .init(title: \.priorityCustomerSupport, type: .boolean),
    ]

    private static let unlimitedComparisonItems: [ComparisonItem] = [
        .init(title: \.storage, type: .string(free: gigabytesString(1), plan: gigabytesString(500))),
        .init(title: \.hideMyEmailAliases, type: .stringAndIcon(free: "10", plan: Image(DS.Icon.icInfinityUpsellRow))),
        .init(title: \.foldersAndLabels, type: .stringAndIcon(free: "3", plan: Image(DS.Icon.icInfinityUpsellRow))),
        .init(title: \.premiumVpnPasswordManagerCloudStorage, type: .boolean),
        .init(title: \.darkWebMonitoring, type: .boolean),
        .init(title: \.customEmailDomain, type: .boolean),
        .init(title: \.accessToDesktopApp, type: .boolean),
        .init(title: \.priorityCustomerSupport, type: .boolean),
    ]

    private static func gigabytesString(_ value: Double) -> String {
        Measurement<UnitInformationStorage>(value: value, unit: .gigabytes).formatted()
    }
}
