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

struct LabelPickerView: View {
    @State private var isArchiveSelected: Bool = false
    @ObservedObject private var model: LabelPickerModel

    init(model: LabelPickerModel) {
        self.model = model
    }

    var body: some View {
        ZStack {
            VStack(spacing: DS.Spacing.large) {
                titleView
                alsoArchiveView
                labelList
                    .clipShape(.rect(cornerRadius: DS.Radius.large))
                buttonDone
                Spacer()
            }
        }
        .padding(.horizontal, DS.Spacing.extraLarge)
        .background(DS.Color.Background.secondary)
        .task {
            await model.fetchLabels()
        }
    }
}

extension LabelPickerView {

    private var titleView: some View {
        Text(LocalizationTemp.LabelPicker.title)
            .font(DS.Font.body3)
            .fontWeight(.bold)
    }

    private var alsoArchiveView: some View {
        HStack(spacing: 0) {
            Image(uiImage: DS.Icon.icArchiveBox)
                .foregroundStyle(DS.Color.Text.weak)
            Toggle(isOn: $isArchiveSelected, label: {
                Text(LocalizationTemp.LabelPicker.alsoArchive)
                    .font(DS.Font.body3)
            })
            .frame(height: 24)
            .foregroundStyle(DS.Color.Text.weak)
            .tint(DS.Color.Text.accent)
            .padding(.leading, DS.Spacing.large)
            .padding(.trailing, DS.Spacing.large)
        }
        .padding(.vertical, DS.Spacing.large)
        .padding(.horizontal, DS.Spacing.large)
        .background(DS.Color.Background.norm)
        .clipShape(.rect(cornerRadius: DS.Radius.extraLarge))
    }

    @MainActor
    private var labelList: some View {
        List {
            ForEach(model.labels) { uiModel in
                VStack {
                    LabelPickerCell(uiModel: uiModel)
                        .onTapGesture {
                            Task {
                                await model.onLabelTap(labelId: uiModel.id)
                            }
                        }
                }
            }
            .listRowBackground(DS.Color.Background.norm)

            AddNewLabel()
                .listRowBackground(DS.Color.Background.norm)
        }
        .background(DS.Color.Background.norm)
        .listStyle(.inset)
        .scrollBounceBehavior(.basedOnSize)
    }

    private var buttonDone: some View {
        HStack {
            Button(action: {
                Task {
                    await model.onDoneTap(alsoArchive: isArchiveSelected)
                }
            }, label: {
                Text(LocalizationTemp.Common.done)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(DS.Color.Global.white)
            })
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(DS.Color.Brand.darken20)
        }
    }
}

struct CustomLabelUIModel: Identifiable {
    let id: PMLocalLabelId
    let name: String
    let color: Color
    let itemsWithLabel: Quantifier
}

private struct LabelPickerCell: View {
    let uiModel: CustomLabelUIModel

    private var selectionImage: UIImage {
        if uiModel.itemsWithLabel.some {
            return DS.Icon.icMinus
        }
        return DS.Icon.icCheckmark
    }

    var body: some View {
        HStack() {
            Circle()
                .frame(width: 12)
                .foregroundStyle(uiModel.color)
                .padding(.leading, DS.Spacing.tiny)
            Text(uiModel.name)
                .font(DS.Font.body3)
                .foregroundStyle(DS.Color.Text.weak)
                .lineLimit(1)
                .padding(.leading, DS.Spacing.moderatelyLarge)
                .padding(.leading, DS.Spacing.small)
            Spacer()
            Image(uiImage: selectionImage)
                .opacity(uiModel.itemsWithLabel.atLeastOne ? 1 : 0)
                .foregroundStyle(DS.Color.Brand.norm)
        }
        .contentShape(Rectangle())
        .padding(.vertical, DS.Spacing.standard)
        .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
            return -2000
        }
    }
}

private struct AddNewLabel: View {

    var body: some View {
        HStack() {
            Image(uiImage: DS.Icon.icPlus)
                .foregroundStyle(DS.Color.Text.weak)
            Text(LocalizationTemp.LabelPicker.newLabel)
                .font(DS.Font.body3)
                .foregroundStyle(DS.Color.Text.weak)
                .padding(.leading, DS.Spacing.moderatelyLarge)
        }
        .listRowBackground(DS.Color.Background.norm)
        .padding(.vertical, 10)
        .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
            return -2000
        }
    }
}

//#Preview {
//    let colors: [Color] = [.red, .orange, .cyan, .purple, .yellow, .brown, .pink]
//    let labels = ["Work", "Holiday 🏝️", "Newsletters"].map({ str in
//        CustomLabelUIModel(id: UInt64.random(in: 1...UInt64.max), name: str, color: colors.randomElement()!, isSelected: true)
//    })
//    return LabelPickerView(model: .init(labels: labels))
//}

#Preview {
    ZStack {
        List {
            LabelPickerCell(uiModel: .init(id: 1, name: "Holidays and a very long name to check how it behaves", color: .pink, itemsWithLabel: .all))
            LabelPickerCell(uiModel: .init(id: 1, name: "Work", color: .blue, itemsWithLabel: .some))
            LabelPickerCell(uiModel: .init(id: 1, name: "Sports", color: .green, itemsWithLabel: .none))
        }
        .listStyle(.inset)
        .padding(20)
    }
    .background(DS.Color.Background.secondary)
}
