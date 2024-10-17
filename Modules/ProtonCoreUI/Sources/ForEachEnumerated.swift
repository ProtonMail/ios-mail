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

public struct ForEachEnumerated<
    Collection: RandomAccessCollection, ID: Hashable, Content: View
>: View {
    public let collection: Collection
    public let id: KeyPath<EnumeratedSequence<Collection>.Element, ID>
    public let content: (_ element: Collection.Element, _ index: Int) -> Content

    public init(
        _ collection: Collection,
        id: KeyPath<EnumeratedSequence<Collection>.Element, ID>,
        @ViewBuilder content: @escaping (_ element: Collection.Element, _ index: Int) -> Content
    ) {
        self.collection = collection
        self.id = id
        self.content = content
    }

    public var body: some View {
        ForEach(Array(collection.enumerated()), id: id) { index, element in
            content(element, index)
        }
    }
}
