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
    struct Configuration {
        enum ColumnHeader {
            case text(LocalizedStringResource)
            case icon(Image)
        }

        let planColumnHeader: ColumnHeader
        let headerStroke: LinearGradient?
        let items: [ComparisonItem]
    }

    private let configuration: Configuration
    private let highlightBorderWidth: CGFloat = 2

    @State private var highlightedColumnWidth: CGFloat = 0

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    var body: some View {
        Grid(horizontalSpacing: 26, verticalSpacing: DS.Spacing.large) {
            GridRow {
                Color.clear

                Text(L10n.PlanName.free)

                planColumnHeaderView
                    .padding(.vertical, DS.Spacing.compact)
                    .padding(.horizontal, DS.Spacing.standard)
                    .overlay {
                        if let headerStroke = configuration.headerStroke {
                            RoundedRectangle(cornerRadius: DS.Radius.medium)
                                .stroke(AnyShapeStyle(headerStroke), lineWidth: highlightBorderWidth)
                                .padding(highlightBorderWidth / 2)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.small)
                    .coordinatedMinWidth(using: _highlightedColumnWidth)
            }
            .font(.callout)
            .fontWeight(.semibold)

            ForEach(configuration.items.indices, id: \.self) { itemIndex in
                gridRow(for: configuration.items[itemIndex])

                if itemIndex != configuration.items.indices.last {
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

    @ViewBuilder
    private var planColumnHeaderView: some View {
        switch configuration.planColumnHeader {
        case .text(let resource):
            Text(resource)
        case .icon(let image):
            image
                .resizable()
                .scaledToFit()
                .frame(height: 32)
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
                case .string(let valueForFreePlan, let valueForPlan):
                    Text(valueForFreePlan)

                    Text(valueForPlan)
                        .padding(.horizontal, DS.Spacing.small)
                        .coordinatedMinWidth(using: _highlightedColumnWidth)
                case .stringAndIcon(let valueForFreePlan, let iconForPlan):
                    Text(valueForFreePlan)

                    iconForPlan
                        .font(.system(size: 20))
                        .padding(.horizontal, DS.Spacing.small)
                        .coordinatedMinWidth(using: _highlightedColumnWidth)
                }
            }
            .fontWeight(.semibold)
        }
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
        PlanComparisonGrid(
            configuration: .init(
                planColumnHeader: .text(L10n.PlanName.plus),
                headerStroke: LinearGradient.highlight,
                items: [
                    .init(title: \.storage, type: .string(free: "1 GB", plan: "15 GB")),
                    .init(title: \.customEmailDomain, type: .boolean),
                ]
            )
        )
    }
    .background(LinearGradient.screenBackground)
    .preferredColorScheme(.dark)
}
