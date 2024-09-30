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

struct SegmentedControl<T: Equatable>: View {
    struct Option {
        let title: String
        let value: T
    }

    private let options: [Option]
    private let selectedValue: Binding<T>

    @State private var highestSegmentWidth: CGFloat = 0

    private let indicatorPadding: CGFloat = 4

    var body: some View {
        ZStack(alignment: .crossAlignment) {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: highestSegmentWidth)
                .frame(height: 32)
                .foregroundStyle(Color.white)
                .alignmentGuide(.crossAlignment) { $0[HorizontalAlignment.center] }
                .shadow(color: .black.opacity(0.16), radius: 2, y: 1)
                .padding(indicatorPadding)
                .animation(.spring, value: selectedValue.wrappedValue)

            HStack(spacing: 0) {
                ForEach(options, id: \.title) { option in
                    let isSelected = option.value == selectedValue.wrappedValue

                    Text(option.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ColorProvider.TextNorm)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 32)
                        .background(GeometryReader { geometry in
                            Color.clear.preference(
                                key: HighestIntrinsicWidthPreferenceKey.self,
                                value: geometry.size.width
                            )
                        })
                        .onPreferenceChange(HighestIntrinsicWidthPreferenceKey.self) {
                            highestSegmentWidth = max(highestSegmentWidth, $0)
                        }
                        .frame(minWidth: highestSegmentWidth + indicatorPadding * 2)
                        .contentShape(Rectangle())
                        .alignmentGuide(isSelected ? .crossAlignment : HorizontalAlignment.center) {
                            $0[HorizontalAlignment.center]
                        }
                        .onTapGesture {
                            selectedValue.wrappedValue = option.value
                        }
                }
            }
        }
        .background(ColorProvider.Shade15)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    init(options: [Option], selectedValue: Binding<T>) {
        self.options = options
        self.selectedValue = selectedValue
    }
}

private enum HighestIntrinsicWidthPreferenceKey: PreferenceKey {
    static let defaultValue = CGFloat()

    public static func reduce(value: inout Value, nextValue: () -> Value) {
        value = max(value, nextValue())
    }
}

extension HorizontalAlignment {
    private enum CrossAlignment: AlignmentID {
        static func defaultValue(in dimensions: ViewDimensions) -> CGFloat {
            dimensions[HorizontalAlignment.center]
        }
    }

    static let crossAlignment = Self(CrossAlignment.self)
}

extension Alignment {
    private enum CrossAlignment: AlignmentID {
        static func defaultValue(in dimensions: ViewDimensions) -> CGFloat {
            dimensions[HorizontalAlignment.center]
        }
    }

    static let crossAlignment = Self(horizontal: .crossAlignment, vertical: .center)
}

#Preview {
    SegmentedControl(
        options: [.init(title: "123", value: 1), .init(title: "123456789", value: 12)],
        selectedValue: .constant(1)
    )
}
