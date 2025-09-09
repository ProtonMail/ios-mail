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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct CapsuleCloudView: View {
    @State private var totalHeight: CGFloat = .zero

    private let subviews: [CapsuleView]

    init(subviews: [CapsuleView]) {
        self.subviews = subviews
    }

    var body: some View {
        GeometryReader { geometry in
            var xPos: CGFloat = .zero
            var yPos: CGFloat = .zero

            ZStack(alignment: .topLeading) {
                ForEach(subviews.indices, id: \.self) { index in
                    subviews[index]
                        .padding([.horizontal, .vertical], DS.Spacing.tiny)
                        .alignmentGuide(.leading) { viewDimensions in
                            if (abs(xPos - viewDimensions.width) > geometry.size.width) {
                                xPos = 0
                                yPos -= viewDimensions.height
                            }
                            let result = xPos
                            if isLast(index) {
                                xPos = 0
                            } else {
                                xPos -= viewDimensions.width
                            }
                            return result
                        }
                        .alignmentGuide(.top) { viewDimensions in
                            let result = yPos
                            if isLast(index) {
                                yPos = 0
                            }
                            return result
                        }
                }
            }
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: HeightPreferenceKey.self, value: geometry.size.height)
                        .onPreferenceChange(HeightPreferenceKey.self) { value in
                            totalHeight = value
                        }
                }
            }
        }
        .frame(height: totalHeight)
    }

    private func isLast(_ index: Int) -> Bool {
        index == subviews.count - 1
    }
}

#Preview {
    VStack {
        Text("Labels".notLocalized).font(.largeTitle)
        CapsuleCloudView(
            subviews: [
                CapsuleView(text: "Work".notLocalized.stringResource, color: .green, style: .label),
                CapsuleView(text: "Friends & Family and Fools Around the World!".notLocalized.stringResource, color: .cyan, style: .label),
                CapsuleView(text: "Holidays ".notLocalized.stringResource, color: .pink, style: .label),
                CapsuleView(text: "Greece meetup".notLocalized.stringResource, color: .blue, style: .label),
                CapsuleView(text: "Reminders".notLocalized.stringResource, color: .red, style: .label),
                CapsuleView(text: "Shopping".notLocalized.stringResource, color: .indigo, style: .label),
                CapsuleView(text: "Shopping".notLocalized.stringResource, color: .purple, style: .label),
            ]
        )
        .padding(10)
        .border(.red)
    }
}
