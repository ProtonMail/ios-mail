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

struct LayoutData: Equatable {
    let frameInCoordinateSpace: CGRect
}

extension View {
    func readLayoutData(coordinateSpace: CoordinateSpace, onChange: @escaping (LayoutData) -> Void) -> some View {
        self
            .background(
                GeometryReader(content: { (geometryProxy) in
                    Color.clear
                        .preference(
                            key: SizePreferenceKey.self,
                            value: LayoutData(
                                frameInCoordinateSpace: geometryProxy.frame(in: coordinateSpace),
                            )
                        )
                })
            )
            .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static let defaultValue = LayoutData(frameInCoordinateSpace: CGRect.zero)
    static func reduce(value: inout LayoutData, nextValue: () -> LayoutData) {}
}
