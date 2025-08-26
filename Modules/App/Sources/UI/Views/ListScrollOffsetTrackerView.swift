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

/// When added at the top of a List content, it tracks the position of this view to return events
/// related to the scroll offset.
struct ListScrollOffsetTrackerView: View {

    enum ScrollEvent {
        case onChangeOffset(value: CGFloat)
    }

    /// List's y position regarding the global coordinate space
    let listTopOffset: CGFloat
    let onScrollEvent: ((_ event: ScrollEvent) -> Void)

    var body: some View {
        Color.clear
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .frame(maxHeight: 1)
            .readLayoutData(
                coordinateSpace: .global,
                onChange: { data in
                    let realScrollOffset = data.frameInCoordinateSpace.minY - listTopOffset
                    onScrollEvent(.onChangeOffset(value: realScrollOffset))
                })
    }
}
