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
    @State private var isArchiveSelected: Bool = true

    private let labels: [LabelUIModel]

    init(labels: [LabelUIModel] = []) {
        self.labels = labels
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
            ForEach(labels) { item in
                VStack {
                    LabelPickerCell(label: item)
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

struct LabelUIModel: Identifiable {
    let id: PMLocalLabelId
    let name: String
    let color: Color
}

private struct LabelPickerCell: View {
    let label: LabelUIModel

    var body: some View {
        HStack() {
            Circle()
                .frame(width: 12)
                .foregroundStyle(label.color)
                .padding(.leading, DS.Spacing.tiny)
            Text(label.name)
                .font(DS.Font.body3)
                .foregroundStyle(DS.Color.Text.weak)
                .padding(.leading, DS.Spacing.moderatelyLarge)
        }
        .padding(.vertical, 10)
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

#Preview {
    let colors: [Color] = [.red, .orange, .cyan, .purple, .yellow, .brown, .pink]
    let labels = ["Work", "Holiday 🏝️", "Newsletters"].map({ str in
        LabelUIModel(id: UInt64.random(in: 1...UInt64.max), name: str, color: colors.randomElement()!)
    })
    return LabelPickerView(labels: labels)
}
