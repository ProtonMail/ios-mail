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

struct UpsellPageContentVariantCarousel: View {
    struct Perk: Identifiable {
        let image: ImageResource
        let title: String
        let subtitle: String

        var id: String {
            title
        }
    }

    private let perks: [Perk] = [
        .init(
            image: .upsellCarouselStorage,
            title: String(format: L10n.PremiumPerks.nTimesMoreStorage, 15),
            subtitle: String(format: L10n.PremiumPerks.nTimesMoreStorageDesc, 15)
        ),
        .init(
            image: .upsellCarouselAddresses,
            title: String(format: L10n.PremiumPerks.nTimesMoreAddresses, 10),
            subtitle: String(format: L10n.PremiumPerks.nTimesMoreAddressesDesc, 10)
        ),
        .init(
            image: .upsellCarouselDomain,
            title: L10n.PremiumPerks.customEmailDomain,
            subtitle: L10n.PremiumPerks.customEmailDomainDesc
        ),
        .init(
            image: .upsellCarouselDesktop,
            title: L10n.PremiumPerks.desktopApp,
            subtitle: L10n.PremiumPerks.desktopAppDesc
        ),
        .init(
            image: .upsellCarouselLabels,
            title: L10n.AutoDeleteUpsellSheet.upsellLineThree,
            subtitle: L10n.PremiumPerks.labelsDesc
        ),
        .init(
            image: .upsellCarouselSupport,
            title: L10n.PremiumPerks.priorityCustomerSupport,
            subtitle: L10n.PremiumPerks.customerSupportDesc
        )
    ]

    var body: some View {
        TabView {
            ForEach(perks) { perk in
                VStack(spacing: 8) {
                    Image(perk.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)

                    Text(perk.title)
                        .font(Font(UIFont.adjustedFont(forTextStyle: .body, weight: .semibold)))
                        .foregroundStyle(ColorProvider.TextInverted)

                    Text(perk.subtitle)
                        .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline, weight: .regular)))
                        .foregroundStyle(ColorProvider.TextDisabled)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 44)
            }
        }
        .tabViewStyle(.page)
    }
}

#Preview {
    VStack {
        UpsellPageContentVariantCarousel()
    }
    .background(ColorProvider.SidebarBackground)
}
