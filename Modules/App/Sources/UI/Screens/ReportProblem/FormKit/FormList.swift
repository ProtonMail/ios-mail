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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct FormList<Collection: RandomAccessCollection, ElementContent: View>: View {
    public let collection: Collection
    public let elementContent: (Collection.Element) -> ElementContent

    // MARK: - View

    var body: some View {
        LazyVStack(spacing: .zero) {
            ForEachLast(collection: collection) { element, isLast in
                VStack(spacing: .zero) {
                    elementContent(element)

                    if !isLast {
                        DS.Color.Border.norm
                            .frame(height: 1)
                            .padding(.leading, 56)
                    }
                }
            }
        }.applyRoundedRectangleStyle()
    }
}
