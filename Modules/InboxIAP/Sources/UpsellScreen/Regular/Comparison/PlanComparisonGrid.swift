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

import InboxDesignSystem
import SwiftUI

struct PlanComparisonGrid: View {
    private let items: [ComparisonItem] = [
        .init(title: \.storage, type: .string(free: gigabytesString(1), plus: gigabytesString(15))),
        .init(title: \.emailAddresses, type: .integer(free: 1, plus: 10)),
        .init(title: \.customEmailDomain, type: .boolean),
        .init(title: \.accessToDesktopApp, type: .boolean),
        .init(title: \.unlimitedFoldersAndLabels, type: .boolean),
        .init(title: \.priorityCustomerSupport, type: .boolean),
    ]

    private let highlightBorderWidth: CGFloat = 2
    private let highlightStroke: any ShapeStyle

    @State private var highlightedColumnWidth: CGFloat = 0

    init(highlightStroke: (any ShapeStyle)? = nil) {
        self.highlightStroke = highlightStroke ?? LinearGradient.highlight
    }

    var body: some View {
        Grid(horizontalSpacing: 26, verticalSpacing: DS.Spacing.large) {
            GridRow {
                Color.clear

                Text(L10n.PlanName.free)

                Text(L10n.PlanName.plus)
                    .padding(.vertical, DS.Spacing.compact)
                    .padding(.horizontal, DS.Spacing.standard)
                    .overlay {
                        RoundedRectangle(cornerRadius: DS.Radius.medium)
                            .stroke(AnyShapeStyle(highlightStroke), lineWidth: highlightBorderWidth)
                            .padding(highlightBorderWidth / 2)
                    }
                    .padding(.horizontal, DS.Spacing.small)
                    .coordinatedMinWidth(using: _highlightedColumnWidth)
            }
            .font(.callout)
            .fontWeight(.semibold)

            ForEach(items.indices, id: \.self) { itemIndex in
                gridRow(for: items[itemIndex])

                if itemIndex != items.indices.last {
                    Divider()
                        .overlay(.white.opacity(0.12))
                }
            }
            .font(.subheadline)
        }
        .padding([.top], DS.Spacing.small)
        .padding(.bottom, DS.Spacing.large)
        .background {
            HStack {
                Spacer()

                RoundedRectangle(cornerRadius: DS.Radius.medium)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: highlightedColumnWidth)
            }
        }
    }

    private func gridRow(for item: ComparisonItem) -> some View {
        GridRow {
            Text(L10n.Perk.self[keyPath: item.title])
                .gridColumnAlignment(.leading)

            Group {
                switch item.type {
                case .boolean:
                    Spacer()

                    Image(symbol: .checkmarkCircleFill)
                        .font(.system(size: 24))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.2))
                        .coordinatedMinWidth(using: _highlightedColumnWidth)
                case .integer(let valueForFreePlan, let valueForPlus):
                    Text("\(valueForFreePlan)")

                    Text("\(valueForPlus)")
                        .coordinatedMinWidth(using: _highlightedColumnWidth)
                case .string(let valueForFreePlan, let valueForPlus):
                    Text(valueForFreePlan)

                    Text(valueForPlus)
                        .coordinatedMinWidth(using: _highlightedColumnWidth)
                }
            }
            .fontWeight(.semibold)
        }
    }

    private static func gigabytesString(_ value: Double) -> String {
        Measurement<UnitInformationStorage>(value: value, unit: .gigabytes).formatted()
    }
}

private extension View {
    func coordinatedMinWidth(using minWidth: State<CGFloat>) -> some View {
        onGeometryChange(for: CGFloat.self, of: \.size.width) {
            minWidth.wrappedValue = max(minWidth.wrappedValue, $0)
        }
    }
}

#Preview {
    ScrollView {
        PlanComparisonGrid()
    }
    .background(LinearGradient.screenBackground)
    .preferredColorScheme(.dark)
}
