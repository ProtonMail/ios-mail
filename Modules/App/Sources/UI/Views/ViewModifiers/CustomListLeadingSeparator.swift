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

/// The default list separator aligns with the image trailing position. Us this modifier to remove the
/// leading inset of the list separator to align it with the list leading position.
struct CustomListLeadingSeparator: ViewModifier {
    func body(content: Content) -> some View {
        content
            .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
                -20.0
            }
    }
}

extension View {
    func customListLeadingSeparator() -> some View {
        modifier(CustomListLeadingSeparator())
    }
}
