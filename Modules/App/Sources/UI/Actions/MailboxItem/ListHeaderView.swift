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

struct ListHeaderView<HeaderContent: View>: View {
    @Binding var isHeaderVisible: Bool
    private let header: () -> HeaderContent
    private let parentGeometry: GeometryProxy

    init(isHeaderVisible: Binding<Bool>, parentGeometry: GeometryProxy, header: @escaping () -> HeaderContent) {
        self._isHeaderVisible = isHeaderVisible
        self.parentGeometry = parentGeometry
        self.header = header
    }

    var body: some View {
        header()
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.frame(in: .global)) { oldValue, newValue in
                            withAnimation {
                                isHeaderVisible = newValue.maxY <= parentGeometry.safeAreaInsets.top
                            }
                        }
                }
            )
    }
}
