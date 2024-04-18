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
        : .init(
            top: DS.Spacing.small,
            leading: DS.Spacing.standard,
            bottom: DS.Spacing.small,
            trailing: DS.Spacing.standard
        )
    }

    var body: some View {
        HStack(spacing: DS.Spacing.small) {
            Text(uiModel.text)
                .font(.caption2)
                .fontWeight(.semibold)
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
        .frame(maxWidth: maxWidth, maxHeight: 21, alignment: .leading)
        .fixedSize()
    }
}

struct MailboxLabelUIModel: Identifiable {
    let id: String
    let color: Color
    let text: String
    var numExtraLabels: Int {
        allLabelIds.count - 1
    }
    let allLabelIds: Set<PMLocalLabelId>
    var isEmpty: Bool {
        text.isEmpty
    }

    init() {
        self.id = UUID().uuidString
        self.color = .clear
        self.text = ""
        self.allLabelIds = .init()
    }

    init(id: String, color: Color, text: String, allLabelIds: Set<PMLocalLabelId>) {
        self.id = id
        self.color = color
        self.text = text
        self.allLabelIds = allLabelIds
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
                    allLabelIds: .init()
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    color: .red,
                    text: "Work",
                    allLabelIds: Set(arrayLiteral: 0, 1, 2)
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    color: .purple,
                    text: "Holidays",
                    allLabelIds: Set(Array(0...25))
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    color: .green,
                    text: "surprise birthday party",
                    allLabelIds: Set(Array(0...240))
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    color: .gray,
                    text: "amazing pictures",
                    allLabelIds: .init()
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    id: UUID().uuidString,
                    color: .gray,
                    text: "surprise birthday party",
                    allLabelIds: .init()
                )
            ).border(.red)
        }
    }
}
