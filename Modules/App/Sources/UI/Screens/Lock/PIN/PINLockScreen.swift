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
import InboxCore

enum PINLockScreenAction {
    case confirm(pin: String)
    case logout
}

struct PINLockScreen: View {
    enum KeyboardButton: Hashable {
        case digit(_ value: Int)
        case delete

        var isDigit: Bool {
            switch self {
            case .digit:
                true
            case .delete:
                false
            }
        }
    }

    @State var pin: String
    @Binding var errorText: String?
    private let handleInParent: (PINLockScreenAction) -> Void

    init(
        pin: String = .empty,
        errorText: Binding<String?>,
        handleInParent: @escaping (PINLockScreenAction) -> Void
    ) {
        _pin = .init(initialValue: pin)
        self._errorText = errorText
        self.handleInParent = handleInParent
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.Background.norm
                    .ignoresSafeArea(.all)

                VStack {
                    Image(systemName: DS.SFSymbols.lock)
                        .font(.title)
                        .padding(.vertical, DS.Spacing.large)
                    pinIndicator()
                        .frame(height: 20, alignment: .center)
                        .frame(maxWidth: 300)
                    if let error = errorText {
                        Text(error)
                            .foregroundStyle(DS.Color.Notification.error)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: DS.Spacing.medium) {
                        ForEach(keyboard, id: \.self) { rowButtons in
                            HStack(spacing: DS.Spacing.large) {
                                ForEach(rowButtons, id: \.self) { button in
                                    Button(action: { handle(button: button) }) {
                                        visualElement(for: button)
                                            .font(.title)
                                            .foregroundStyle(DS.Color.Text.norm)
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
                        action: { handle(action: .confirm(pin: pin)) },
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
                    Button(action: { handle(action: .logout) }) {
                        Image(systemName: DS.SFSymbols.rectanglePortraitAndArrowRight)
                            .foregroundStyle(DS.Color.Icon.norm)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func visualElement(for button: KeyboardButton) -> some View {
        switch button {
        case .digit(let value):
            Text("\(value)")
        case .delete:
            Image(systemName: DS.SFSymbols.deleteLeft)
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

    private func handle(action: PINLockScreenAction) {
        switch action {
        case .confirm(let pin):
            self.pin = .empty
            if pin.isEmpty == false {
                handleInParent(action)
            }
        case .logout:
            handleInParent(action)
        }
    }

    private func handle(button: KeyboardButton) {
        errorText = nil
        switch button {
        case .digit(let value):
            pin = pin.appending("\(value)")
        case .delete:
            pin = String(pin.dropLast())
        }
    }

    private var keyboard: [[KeyboardButton]] {
        [
            [.digit(1), .digit(2), .digit(3)],
            [.digit(4), .digit(5), .digit(6)],
            [.digit(7), .digit(8), .digit(9)],
            [.digit(0), .delete]
        ]
    }

}
