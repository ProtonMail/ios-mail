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
                .foregroundColor(uiModel.textColor)
                .padding(textPadding)
                .lineLimit(1)
                .frame(minWidth: minWidth)
                .background(
                    Capsule()
                        .foregroundColor(uiModel.labelColor)
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
    let labelColor: Color
    let text: String
    let textColor: Color
    /// total number of labels - 1
    let numExtraLabels: Int
    var isEmpty: Bool {
        text.isEmpty
    }

    init() {
        self.id = UUID().uuidString
        self.labelColor = .clear
        self.text = ""
        self.textColor = .clear
        self.numExtraLabels = 0
    }

    init(id: String, labelColor: Color, text: String, textColor: Color, numExtraLabels: Int) {
        self.id = id
        self.labelColor = labelColor
        self.text = text
        self.textColor = textColor
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
                    labelColor: .blue,
                    text: "a",
                    textColor: .white,
                    numExtraLabels: 0
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    labelColor: .red,
                    text: "Work",
                    textColor: .white,
                    numExtraLabels: 2
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    labelColor: .purple,
                    text: "Holidays",
                    textColor: .white,
                    numExtraLabels: 25
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    labelColor: .green,
                    text: "surprise birthday party",
                    textColor: .white,
                    numExtraLabels: 239
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    labelColor: .gray,
                    text: "amazing pictures",
                    textColor: .white,
                    numExtraLabels: 0
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    labelColor: .gray,
                    text: "surprise birthday party",
                    textColor: .white,
                    numExtraLabels: 0
                )
            ).border(.red)
        }
    }
}
