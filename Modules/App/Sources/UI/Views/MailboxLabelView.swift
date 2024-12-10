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

import InboxDesignSystem
import SwiftUI

// FIXME: - To remove
struct MailboxLabelView: View {
    let uiModel: MailboxLabelUIModel
    let extraLabelsTextColor: Color

    init(uiModel: MailboxLabelUIModel, extraLabelsTextColor: Color = DS.Color.Text.norm) {
        self.uiModel = uiModel
        self.extraLabelsTextColor = extraLabelsTextColor
    }

    private var showExtraLabels: Bool {
        !uiModel.isEmpty && uiModel.numExtraLabels > 0
    }
    private var normalisedNumExtraLabels: Int {
        min(uiModel.numExtraLabels, 99)
    }
    private var padding: EdgeInsets {
        uiModel.text.isEmpty
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
                .padding(padding)
                .lineLimit(1)
                .background(
                    Capsule()
                        .foregroundStyle(uiModel.color)
                )
            Text("+\(normalisedNumExtraLabels)".notLocalized)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(extraLabelsTextColor)
                .frame(width: showExtraLabels ? nil : 0)
        }
        .frame(maxHeight: 21, alignment: .leading)
    }
}

struct MailboxLabelUIModel: Identifiable {
    let labelModels: [LabelUIModel]

    var id: ID {
        labelModels.first?.labelId ?? .random()
    }

    var color: Color {
        labelModels.first?.color ?? .clear
    }

    var text: String {
        labelModels.first?.text ?? ""
    }

    var numExtraLabels: Int {
        labelModels.count - 1
    }

    var isEmpty: Bool {
        labelModels.isEmpty
    }

    init(labelModels: [LabelUIModel] = []) {
        self.labelModels = labelModels
    }
}

struct LabelUIModel: Hashable {
    let labelId: ID
    let text: String
    let color: Color
}

#Preview {
    HStack {
        VStack {
            MailboxLabelView(uiModel: .init())
                .border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(labelModels: [
                    LabelUIModel(labelId: .init(value: 0), text: "a", color: .blue)
                ])
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(labelModels: [
                    .init(
                        labelId: .random(),
                        text: "Work",
                        color: .red
                    )
                ])
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(labelModels: [
                    .init(
                        labelId: .random(),
                        text: "Work",
                        color: .red
                    )
                ] + LabelUIModel.random(num: 25)
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    labelModels: [.init(labelId: .init(value: 0), text: "Holidays", color: Color.purple)]
                    + LabelUIModel.random(num: 25)
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(
                    labelModels: [LabelUIModel(labelId: .init(value: 0), text: "surprise birthday party", color: .green)]
                    + LabelUIModel.random(num: 240)
                )
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(labelModels: [.init(labelId: .init(value: 0), text: "amazing pictures", color: .gray)])
            ).border(.red)
            MailboxLabelView(
                uiModel: MailboxLabelUIModel(labelModels: [.init(labelId: .init(value: 0), text: "surprise birthday party", color: .gray)])
            ).border(.red)
        }
    }
}
