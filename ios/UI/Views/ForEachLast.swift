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

import SwiftUI

struct ForEachLast<Collection: RandomAccessCollection, Content: View>: View {
    let collection: Collection
    let content: (Collection.Element, Bool) -> Content

    var body: some View {
        ForEach(Array(collection.enumerated()), id: \.offset) { index, element in
            content(element, index == (collection.count - 1))
        }
    }
}
