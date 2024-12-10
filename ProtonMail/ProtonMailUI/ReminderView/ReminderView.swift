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

public struct ReminderView: View {
    private var periodEnd: String
    private var perks: [UpsellPageModel.Perk]
    private var markAsSeen: () -> Void
    private var reactivateSubscription: (_ completion: @escaping ((Error?) -> Void)) -> Void
    private var displayReactivationBanner: (Error?) -> Void

    @Environment(\.dismiss)
    private var dismiss

    public init(periodEnd: String, perks: [UpsellPageModel.Perk], markAsSeen: @escaping () -> (), reactivateSubscription: @escaping (_ completion: @escaping ((Error?) -> Void)) -> (), displayReactivationBanner: @escaping (Error?) -> Void) {
        self.periodEnd = periodEnd
        self.perks = perks
        self.markAsSeen = markAsSeen
        self.reactivateSubscription = reactivateSubscription
        self.displayReactivationBanner = displayReactivationBanner
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    Spacer()
                    ColorProvider.BackgroundNorm
                        .ignoresSafeArea(edges: [.bottom])
                        .padding([.horizontal], 0)
                        .frame(
                            idealHeight: geometry.safeAreaInsets.bottom
                        )
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack {
                    Spacer()
                    containerView
                        .background(ColorProvider.BackgroundNorm)
                        .padding([.horizontal], 0)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .transition(
                .asymmetric(
                    insertion: AnyTransition.move(edge: .bottom).combined(with: .opacity),
                    removal: AnyTransition.move(edge: .bottom).combined(with: .opacity)
                )
            )
        }
    }

    private var containerView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, content: {
                Spacer()
                Button(action: {
                    markAsSeen()
                    dismiss()
                }, label: {
                    Image(uiImage: IconProvider.cross)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(ColorProvider.IconNorm)
                })
                .frame(width: 40, height: 40)
            })
            .padding([.top, .trailing], 8)

            VStack(spacing: 16) {
                Image(.subscriptionEnding)
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                VStack(spacing: 4) {
                    Text(L10n.ReminderModal.title)
                        .font(Font(UIFont.adjustedFont(forTextStyle: .body, weight: .semibold)))
                    Text(String(format: L10n.ReminderModal.subtitle, periodEnd))
                        .font(Font(UIFont.adjustedFont(forTextStyle: .caption1)))
                        .foregroundColor(Color(ColorProvider.TextWeak))
                }
                listView
                Button(action: {
                    reactivateSubscription { error in
                        displayReactivationBanner(error)
                        dismiss()
                    }
                    markAsSeen()
                }, label: {
                    Text(L10n.ReminderModal.reactivateSubscriptionButtonTitle)
                        .frame(width: 327, height: 48)
                        .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline)))
                        .background(ColorProvider.InteractionNorm)
                        .foregroundColor(Color.white)
                })
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 24)
        }
    }

    private var listView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading) {
                ForEach(0..<perks.count, id: \.self) { index in
                    HStack(alignment: .center, spacing: 8) {
                        Image(uiImage: IconProvider[dynamicMember: perks[index].icon])
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundColor(ColorProvider.IconAccent)
                        
                        Text(perks[index].description)
                            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 56, alignment: .leading)
                            .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline)))
                            .lineLimit(2)
                            .listRowSeparator(.hidden)
                    }
                    .padding([.leading, .trailing], 8)
                    .background(index % 2 == 0 ? Color(ColorProvider.BackgroundSecondary) : .clear)
                    .cornerRadius(index % 2 == 0 ? 8 : 0)
                }
            }
        }
    }
}
