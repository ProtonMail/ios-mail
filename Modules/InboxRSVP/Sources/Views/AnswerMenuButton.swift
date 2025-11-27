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

import InboxDesignSystem
import SwiftUI
import proton_app_uniffi

struct AnswerMenuButton: View {
    let state: RsvpAnswer
    let isAnswering: Bool
    let onAnswerSelected: (RsvpAnswer) -> Void

    @State private var rotation: Double = 0
    private let rotationRange: ClosedRange<Double> = 0...360

    var body: some View {
        Menu {
            ForEach(RsvpAnswer.allCases.removing { $0 == state }, id: \.self) { answer in
                MenuOptionButton(
                    text: answer.humanReadable.long,
                    action: { onAnswerSelected(answer) },
                    trailingIcon: .none
                )
            }
        } label: {
            HStack(spacing: DS.Spacing.compact) {
                Text(state.humanReadable.long.string)
                if isAnswering {
                    answeringImage()
                } else {
                    nonAnsweringImage()
                }
            }
        }
        .buttonStyle(ActionButtonStyle.answerButtonStyle)
        .animation(.easeInOut, value: isAnswering)
        .disabled(isAnswering)
    }

    // MARK: - Private

    private func answeringImage() -> some View {
        Image(symbol: .arrowCirclePath)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                rotation = rotationRange.lowerBound
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = rotationRange.upperBound
                }
            }
            .onDisappear { rotation = rotationRange.lowerBound }
            .transition(.opacity.combined(with: .scale))
    }

    private func nonAnsweringImage() -> some View {
        Image(symbol: .chevronDown)
            .transition(.opacity.combined(with: .scale))
    }
}

private extension Array {

    func removing(_ shouldBeExcluded: (Self.Element) throws -> Bool) rethrows -> [Self.Element] {
        try filter { item in try !shouldBeExcluded(item) }
    }

}
