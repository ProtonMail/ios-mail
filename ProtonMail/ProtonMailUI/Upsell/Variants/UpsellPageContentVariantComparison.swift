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

struct UpsellPageContentVariantComparison: View {
    struct Perk {
        let title: String
        let type: PerkType
    }

    enum PerkType {
        case boolean
        case string(free: String, plus: String)
        case integer(free: Int, plus: Int)
    }

    @State private var firstColumnWidth: CGFloat = 0
    @State private var secondColumnWidth: CGFloat = 0

    private let perks: [Perk] = [
        .init(
            title: L10n.AccountSettings.storage,
            type: .string(
                free: Measurement<UnitInformationStorage>(value: 1, unit: .gigabytes).formatted(),
                plus: Measurement<UnitInformationStorage>(value: 15, unit: .gigabytes).formatted()
            )
        ),
        .init(title: LocalString._contacts_email_addresses_title, type: .integer(free: 1, plus: 10)),
        .init(title: L10n.PremiumPerks.desktopApp, type: .boolean),
        .init(title: L10n.PremiumPerks.customEmailDomain, type: .boolean),
        .init(title: L10n.AutoDeleteUpsellSheet.upsellLineThree, type: .boolean),
        .init(title: L10n.PremiumPerks.priorityCustomerSupport, type: .boolean)
    ]

    private let plusColumnHeaderGradient = LinearGradient(
        colors: [.comparisonTablePlusHeaderGradientStart, ColorProvider.InteractionNorm],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        ScrollView(showsIndicators: false) {
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: secondColumnWidth)

                LazyVStack(spacing: 0) {
                    Section {
                        ForEach(perks.indices, id: \.self) { idx in
                            VStack {
                                HStack {
                                    Text(perks[idx].title)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.vertical, 16)
                                        .font(Font(UIFont.adjustedFont(forTextStyle: .footnote)))

                                    Spacer()

                                    Group {
                                        switch perks[idx].type {
                                        case .boolean:
                                            Text("-")
                                        case .string(let free, _):
                                            Text(free)
                                        case .integer(let free, _):
                                            Text("\(free)")
                                        }
                                    }
                                    .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline)))
                                    .padding(.horizontal, 4)
                                    .coordinatedMinWidth(using: _firstColumnWidth)

                                    Group {
                                        switch perks[idx].type {
                                        case .boolean:
                                            IconProvider.checkmarkCircleFilled
                                                .resizable()
                                                .frame(width: 20, height: 20)
                                                .padding(13)
                                        case .string(_, let plus):
                                            Text(plus)
                                        case .integer(_, let plus):
                                            Text("\(plus)")
                                        }
                                    }
                                    .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline)))
                                    .padding(.horizontal, 4)
                                    .coordinatedMinWidth(using: _secondColumnWidth)
                                }
                            }

                            if idx != perks.indices.last {
                                Divider()
                                    .overlay(.white.opacity(0.08))
                            }
                        }
                    } header: {
                        HStack {
                            Spacer()

                            Text(L10n.Upsell.freePlan)
                                .coordinatedMinWidth(using: _firstColumnWidth)

                            Text("Plus")
                                .foregroundColor(ColorProvider.SidebarTextNorm)
                                .padding(6)
                                .background(plusColumnHeaderGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(4)
                                .coordinatedMinWidth(using: _secondColumnWidth)
                        }
                        .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline, weight: .semibold)))
                    }
                }
            }
            .foregroundColor(ColorProvider.SidebarTextWeak)
            .padding(.bottom, 8)
        }
        .disableBounceIfNotNeeded()
    }
}

private enum HighestIntrinsicWidthPreferenceKey: PreferenceKey {
    static let defaultValue = CGFloat()

    public static func reduce(value: inout Value, nextValue: () -> Value) {
        value = max(value, nextValue())
    }
}

private extension View {
    func coordinatedMinWidth(using minWidth: State<CGFloat>) -> some View {
        background(GeometryReader { geometry in
            Color.clear.preference(
                key: HighestIntrinsicWidthPreferenceKey.self,
                value: geometry.size.width
            )
        })
        .onPreferenceChange(HighestIntrinsicWidthPreferenceKey.self) {
            minWidth.wrappedValue = max(minWidth.wrappedValue, $0)
        }
        .frame(minWidth: minWidth.wrappedValue)
    }

    func disableBounceIfNotNeeded() -> some View {
        if #available(iOS 16.4, *) {
            return scrollBounceBehavior(.basedOnSize)
        } else {
            return self
        }
    }
}

#Preview {
    VStack {
        UpsellPageContentVariantComparison()
    }
    .background(ColorProvider.SidebarBackground)
}
