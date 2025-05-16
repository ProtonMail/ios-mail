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

public struct FormListSeparator {
    public let leadingPadding: CGFloat
    public let color: Color
}

public struct FormList<Collection: RandomAccessCollection, ElementContent: View>: View {
    public let collection: Collection
    public let separator: FormListSeparator
    public let elementContent: (Collection.Element) -> ElementContent

    public init(
        collection: Collection,
        separator: FormListSeparator,
        elementContent: @escaping (Collection.Element) -> ElementContent
    ) {
        self.collection = collection
        self.separator = separator
        self.elementContent = elementContent
    }

    // MARK: - View

    public var body: some View {
        LazyVStack(spacing: .zero) {
            ForEachLast(collection: collection) { element, isLast in
                VStack(spacing: .zero) {
                    elementContent(element)

                    if !isLast {
                        separator.color
                            .frame(height: 1)
                            .padding(.leading, separator.leadingPadding)
                    }
                }
            }
        }
        .background(DS.Color.BackgroundInverted.secondary)
        .roundedRectangleStyle()
    }
}

extension FormListSeparator {

    public static var invertedNoPadding: Self {
        .init(leadingPadding: .zero, color: DS.Color.BackgroundInverted.border)
    }

    public static var normLeftPadding: Self {
        .init(leadingPadding: 56, color: DS.Color.Border.norm)
    }

}
