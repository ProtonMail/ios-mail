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
    typealias OnDoneTap = (_ selectedLabelIds: Set<PMLocalLabelId>, _ alsoArchive: Bool) -> Void

    @State private var isArchiveSelected: Bool = false
    @State private var labels: [LabelPickerCellUIModel] = []

    private let customLabelModel: CustomLabelModel
    private let labelsOfSelectedItems: () -> [Set<PMLocalLabelId>]
    private let onDone: OnDoneTap

    /// - Parameters:
    ///   - customLabelModel: model that provides the list of custom labels
    ///   - labelsOfSelectedItems: array of label id sets, representing the labels the selected mailbox items have.
    ///   This information will be transformed to show which labels are applied to all / some / none.
    ///   e.g. [(1,2),( ),(2,4),(2)]
    ///   - onDoneTap: closure returning the user's label picks
    init(
        customLabelModel: CustomLabelModel,
        labelsOfSelectedItems: @escaping () -> [Set<PMLocalLabelId>],
        onDoneTap: @escaping OnDoneTap
    ) {
        self.customLabelModel = customLabelModel
        self.labelsOfSelectedItems = labelsOfSelectedItems
        self.onDone = onDoneTap
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
            await initialiseState()
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
            ForEach(labels) { uiModel in
                VStack {
                    LabelPickerCell(uiModel: uiModel)
                        .onTapGesture {
                            Task {
                                await onCellTap(for: uiModel)
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
                onDoneTapped()
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

// MARK: logic

extension LabelPickerView {

    private func initialiseState() async {
        let labelsOfSelectedItems = labelsOfSelectedItems()
        let selectedLabelIds: [PMLocalLabelId: Quantifier] = labelsOfSelectedItems
            .reduce([PMLocalLabelId: Int](), { partialResult, currentItem in
                var newPartialResult = partialResult
                currentItem.forEach { labelId in
                    if let count = newPartialResult[labelId] {
                        newPartialResult[labelId] = count + 1
                    } else {
                        newPartialResult[labelId] = 1
                    }
                }
                return newPartialResult
            })
            .mapValues {
                $0 == labelsOfSelectedItems.count ? .all : .some
            }
        labels = await customLabelModel.fetchLabels().map { $0.toLabelPickerCellUIModel(selectedIds: selectedLabelIds) }
    }

    private func onCellTap(for tappedModel: LabelPickerCellUIModel) async {
        var selectedIds: [PMLocalLabelId: Quantifier] = labels
            .reduce([:]) { partialResult, uiModel in
                var result = partialResult
                result[uiModel.id] = uiModel.itemsWithLabel
                return result
            }
        selectedIds[tappedModel.id] = tappedModel.itemsWithLabel.atLeastOne ? Optional.none : .all
        labels = await customLabelModel.fetchLabels().map { $0.toLabelPickerCellUIModel(selectedIds: selectedIds) }
    }

    private func onDoneTapped() {
        let selectedLabelIds = Set(labels.filter { $0.itemsWithLabel.atLeastOne }.map(\.id))
        onDone(selectedLabelIds, isArchiveSelected)
    }
}

struct LabelPickerCellUIModel: Identifiable {
    let id: PMLocalLabelId
    let name: String
    let color: Color
    let itemsWithLabel: Quantifier
}

private struct LabelPickerCell: View {
    let uiModel: LabelPickerCellUIModel

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
//        LabelPickerCellUIModel(id: UInt64.random(in: 1...UInt64.max), name: str, color: colors.randomElement()!, itemsWithLabel: .all)
//    })
////    return LabelPickerView(customLabelModel: <#T##CustomLabelModel#>, labelsOfSelectedItems: <#T##() -> [Set<PMLocalLabelId>]#>, onDoneTap: <#T##LabelPickerView.OnDoneTap##LabelPickerView.OnDoneTap##(_ selectedLabelIds: Set<PMLocalLabelId>, _ alsoArchive: Bool) -> Void#>
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
