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

import InboxDesignSystem
import ProtonUIFoundations
import SwiftUI

public struct BadgesView: View {
    @State private var totalHeight: CGFloat = .zero

    private let badges: [Badge]

    public init(badges: [Badge]) {
        self.badges = badges
    }

    public var body: some View {
        GeometryReader { geometry in
            var xPos: CGFloat = .zero
            var yPos: CGFloat = .zero

            ZStack(alignment: .topLeading) {
                ForEachLast(collection: badges) { model, isLast in
                    BadgeView(text: model.text, color: model.color)
                        .padding([.horizontal, .vertical], DS.Spacing.tiny)
                        .alignmentGuide(.leading) { viewDimensions in
                            if (abs(xPos - viewDimensions.width) > geometry.size.width) {
                                xPos = 0
                                yPos -= viewDimensions.height
                            }
                            let result = xPos
                            if isLast {
                                xPos = 0
                            } else {
                                xPos -= viewDimensions.width
                            }
                            return result
                        }
                        .alignmentGuide(.top) { viewDimensions in
                            let result = yPos
                            if isLast {
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
}

#Preview {
    VStack {
        Text("Labels".notLocalized).font(.largeTitle)
        BadgesView(
            badges: [
                Badge(text: "Work".notLocalized, color: .green),
                Badge(text: "Friends & Family and Fools Around the World!".notLocalized, color: .cyan),
                Badge(text: "Holidays ".notLocalized, color: .pink),
                Badge(text: "Greece meetup".notLocalized, color: .blue),
                Badge(text: "Reminders".notLocalized, color: .red),
                Badge(text: "Shopping".notLocalized, color: .indigo),
                Badge(text: "Shopping".notLocalized, color: .purple),
            ]
        )
        .padding(10)
        .border(.red)
    }
}
