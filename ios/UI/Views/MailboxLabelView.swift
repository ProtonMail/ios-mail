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

struct MailboxLabelView: View {
    let uiModel: MailboxLabelUIModel

    private var showExtraLabels: Bool {
        !uiModel.isEmpty && uiModel.numExtraLabels > 0
    }
    private var normalisedNumExtraLabels: Int {
        min(uiModel.numExtraLabels, 99)
    }
    private var minWidth: CGFloat? {
        uiModel.isEmpty ? nil : 30
    }
    private var maxWidth: CGFloat? {
        uiModel.isEmpty ? nil : 100
    }
    private var textPadding: EdgeInsets {
        uiModel.isEmpty
        ? .init(.zero)
        : .init(top: 4.0, leading: 8.0, bottom: 4.0, trailing: 8.0)
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(uiModel.text)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(textPadding)
                .lineLimit(1)
                .frame(minWidth: minWidth)
                .background(
                    Capsule()
                        .foregroundColor(uiModel.color)
                )
            Text("+\(normalisedNumExtraLabels)")
                .font(.caption2)
                .fontWeight(.regular)
                .frame(width: showExtraLabels ? nil : 0)
        }
        .frame(maxWidth: maxWidth, alignment: .leading)
        .fixedSize()
    }
}

struct MailboxLabelUIModel: Identifiable {
    let id: String
    let color: Color
    let text: String
    let numExtraLabels: Int
    var isEmpty: Bool {
        text.isEmpty
    }

    init() {
        self.id = UUID().uuidString
        self.color = .clear
        self.text = ""
        self.numExtraLabels = 0
    }

    init(id: String, color: Color, text: String, numExtraLabels: Int) {
        self.id = id
        self.color = color
        self.text = text
        self.numExtraLabels = numExtraLabels
    }
}

#Preview {
    HStack {
        VStack {
            MailboxLabelView(uiModel: .init())
                .border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    color: .blue,
                    text: "a",
                    numExtraLabels: 0
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    color: .red,
                    text: "Work",
                    numExtraLabels: 2
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    color: .purple,
                    text: "Holidays",
                    numExtraLabels: 25
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    color: .green,
                    text: "surprise birthday party",
                    numExtraLabels: 239
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    color: .gray,
                    text: "amazing pictures",
                    numExtraLabels: 0
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    color: .gray,
                    text: "surprise birthday party",
                    numExtraLabels: 0
                )
            ).border(.red)
        }
    }
}
