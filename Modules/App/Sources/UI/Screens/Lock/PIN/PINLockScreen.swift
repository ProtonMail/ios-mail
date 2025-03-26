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

import SwiftUI
import InboxCoreUI
import InboxDesignSystem

struct PINLockScreen: View {
    enum ButtonType: Hashable {
        case digit(_ value: Int)
        case delete
        case empty

        var isDigit: Bool {
            switch self {
            case .digit:
                true
            case .delete, .empty:
                false
            }
        }
    }
    @State private var pin: String = ""

    var buttons: [[ButtonType]] = [
        [.digit(1), .digit(2), .digit(3)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(7), .digit(8), .digit(9)],
        [.empty, .digit(0), .delete]
    ]

    func handle(button: ButtonType) {
        switch button {
        case .digit(let value):
            pin += "\(value)"
        case .delete:
            if !pin.isEmpty {
                pin.removeLast()
            }
        case .empty:
            break
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.Background.norm
                    .ignoresSafeArea(.all)
                VStack {
                    Image(systemName: "lock")
                        .font(.title)
                        .padding(.vertical, DS.Spacing.large)
                    pinIndicator()
                        .frame(height: 20, alignment: .center)
                        .frame(maxWidth: 300)

                    Spacer()

                    VStack(spacing: DS.Spacing.medium) {
                        ForEach(buttons, id: \.self) { rowButtons in
                            HStack(spacing: DS.Spacing.large) {
                                ForEach(rowButtons, id: \.self) { button in
                                    Button(action: { handle(button: button) }) {
                                        content(for: button)
                                            .square(size: 92)
                                            .background(button.isDigit ? DS.Color.InteractionWeak.norm : .clear)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                    }

                    Spacer()

                    Button(
                        action: {  },
                        label: { Text("Confirm") }
                    )
                    .buttonStyle(BigButtonStyle())
                    .padding(DS.Spacing.large)
                }
            }
            .navigationTitle("Enter PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        print("Logout")
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(DS.Color.Icon.norm)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func content(for button: ButtonType) -> some View {
        switch button {
        case .digit(let value):
            Text("\(value)")
                .font(.title)
                .foregroundStyle(DS.Color.Text.norm)
        case .delete:
            Image(systemName: "delete.left")
                .foregroundStyle(DS.Color.Icon.norm)
                .font(.title)
        case .empty:
            Color.clear
        }
    }

    @ViewBuilder
    func pinIndicator() -> some View {
        if pin.isEmpty {
            Text("Enter your PIN to unlock you inbox.")
                .foregroundStyle(DS.Color.Text.weak)
        } else {
            HStack(spacing: DS.Spacing.small) {
                ForEach(0..<pin.count, id: \.self) { _ in
                    Circle()
                        .fill(DS.Color.InteractionBrand.norm)
                        .square(size: 10)
                }
            }
        }
    }

}
