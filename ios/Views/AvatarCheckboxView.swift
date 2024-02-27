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

struct AvatarCheckboxView: View {
    let isSelected: Bool
    var onDidChangeSelection: ((_ newValue: Bool) -> Void)

    var body: some View {
        Checkbox(isOn: isSelected, onDidChangeSelection: onDidChangeSelection)
    }
}

private struct Checkbox: View {
    let isOn: Bool
    var onDidChangeSelection: ((_ newValue: Bool) -> Void)

    var body: some View {

        Button(action: {
            onDidChangeSelection(!isOn)
        }, label: {
            Image(systemName: isOn ? "checkmark.square" : "square")
                .resizable()
                .scaledToFit()
        })
        .buttonStyle(.borderless) // hack to avoid a tap anywhere on the cell to trigger the button action
    }
}
