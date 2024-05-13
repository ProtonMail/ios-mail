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

public struct UpsellPage: View {
    @ObservedObject private var model: UpsellPageModel
    private let onPurchaseTapped: (String) -> Void

    @Environment(\.verticalSizeClass)
    private var verticalSizeClass

    @MainActor private var windowSafeAreaInsets: UIEdgeInsets {
        UIApplication
            .shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .safeAreaInsets ?? .zero
    }

    public init(model: UpsellPageModel, onPurchaseTapped: @escaping (String) -> Void) {
        self.model = model
        self.onPurchaseTapped = onPurchaseTapped
    }

    public var body: some View {
        PartialOverlayActionSheet { _ in
            if verticalSizeClass == .compact {
                HStack {
                    infoSection

                    VStack {
                        tiles
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
                .padding(.bottom, windowSafeAreaInsets.bottom)
            } else {
                VStack {
                    infoSection

                    HStack(alignment: .bottom) {
                        tiles
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
                .padding(.bottom, windowSafeAreaInsets.bottom)
            }
        }
    }

    private var infoSection: some View {
        VStack(spacing: 4) {
            if verticalSizeClass != .compact {
                Image(.mailUpsell)
                    .padding(-20)
            }

            VStack(spacing: 8) {
                Text(String(format: L10n.Upsell.upgradeToPlan, model.plan.name))
                    .font(Font(UIFont.adjustedFont(forTextStyle: .title1, weight: .bold)))
                    .foregroundColor(ColorProvider.SidebarTextNorm)

                Text(L10n.Upsell.mailPlusDescription)
                    .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline)))
                    .foregroundColor(ColorProvider.SidebarTextWeak)
            }
            .padding(.horizontal, 16)

            VStack(alignment: .leading) {
                ForEach(model.plan.perks, id: \.description) { perk in
                    VStack(alignment: .leading) {
                        HStack(spacing: 12) {
                            IconProvider[dynamicMember: perk.icon]
                                .frame(maxHeight: 20)
                                .foregroundColor(ColorProvider.IconWeak)
                                .preferredColorScheme(.dark)

                            Text(perk.description)
                                .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline)))
                                .foregroundColor(ColorProvider.SidebarTextWeak)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.white.opacity(0.08))
                    }
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var tiles: some View {
        ZStack {
            ForEach(model.plan.purchasingOptions, id: \.identifier) { option in
                UpsellCTATile(planName: model.plan.name, purchasingOption: option) {
                    onPurchaseTapped(option.identifier)
                }
                .fixedSize()
            }
            .visible(!model.isBusy)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .visible(model.isBusy)
        }
    }
}
