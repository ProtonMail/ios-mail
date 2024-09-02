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

import DesignSystem
import SwiftUI

struct ClosableScreen<ContentView: View>: View {
    @Environment(\.dismiss) var dismiss
    let content: () -> ContentView

    var body: some View {
        NavigationStack {
            content()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { dismiss.callAsFunction() }) {
                            HStack {
                                Image(DS.Icon.icCross)
                                    .square(size: 20)
                                    .tint(DS.Color.Text.weak)
                                Spacer()
                            }
                        }
                        .padding(DS.Spacing.mediumLight)
                        .background(DS.Color.Background.norm, in: Circle())
                        .overlay {
                            Circle()
                                .stroke(DS.Color.Border.norm, lineWidth: 1)
                        }
                    }
                }
        }
    }
}
