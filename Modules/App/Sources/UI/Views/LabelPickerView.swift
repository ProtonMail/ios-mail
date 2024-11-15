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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct LabelPickerView: View {
    typealias OnDoneTap = (_ selectedLabelIds: Set<ID>, _ alsoArchive: Bool) -> Void

    @State private var isArchiveSelected: Bool = false
    @State private var labels: [LabelPickerCellUIModel] = []

    private let customLabelModel: CustomLabelModel
    private let labelsOfSelectedItems: () -> [Set<ID>]
    private let onDone: OnDoneTap

    /// - Parameters:
    ///   - customLabelModel: model that provides the list of custom labels
    ///   - labelsOfSelectedItems: array of label id sets, representing the labels the selected mailbox items have.
    ///   This information will be transformed to show which labels are applied to all / some / none.
    ///   e.g. [(1,2),( ),(2,4),(2)]
    ///   - onDoneTap: closure returning the user's label picks
    init(
        customLabelModel: CustomLabelModel,
        labelsOfSelectedItems: @escaping () -> [Set<ID>],
        onDoneTap: @escaping OnDoneTap
    ) {
        self.customLabelModel = customLabelModel
        self.labelsOfSelectedItems = labelsOfSelectedItems
        self.onDone = onDoneTap
    }

    var body: some View {
        ZStack {
            VStack(spacing: DS.Spacing.medium) {
                titleView
                    .padding(.top, DS.Spacing.standard)
                alsoArchiveView
                labelList
                    .clipShape(.rect(cornerRadius: DS.Radius.large))
                buttonDone
                    .padding(.top, DS.Spacing.standard)
                Spacer()
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(LabelPickerViewIdentifiers.rootItem)
        }
        .padding(.horizontal, DS.Spacing.large)
        .background(DS.Color.Background.secondary)
        .task {
            await initialiseState()
        }
        .accessibilityElement(children: .contain)
    }
}

extension LabelPickerView {

    private var titleView: some View {
        Text(L10n.Labels.title)
            .font(.subheadline)
            .fontWeight(.bold)
            .accessibilityIdentifier(LabelPickerViewIdentifiers.titleText)
    }

    private var alsoArchiveView: some View {
        HStack(spacing: 0) {
            Image(DS.Icon.icArchiveBox)
                .foregroundStyle(DS.Color.Text.weak)
                .accessibilityIdentifier(LabelPickerViewIdentifiers.alsoArchiveIcon)
            Toggle(isOn: $isArchiveSelected, label: {
                Text(L10n.Labels.alsoArchive)
                    .font(.subheadline)
            })
            .frame(height: 24)
            .foregroundStyle(DS.Color.Text.weak)
            .tint(DS.Color.Text.accent)
            .padding(.leading, DS.Spacing.large)
            .padding(.trailing, DS.Spacing.large)
            .accessibilityIdentifier(LabelPickerViewIdentifiers.alsoArchiveToggle)
        }
        .padding(.vertical, DS.Spacing.large)
        .padding(.horizontal, DS.Spacing.large)
        .background(DS.Color.Background.norm)
        .clipShape(.rect(cornerRadius: DS.Radius.extraLarge))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(LabelPickerViewIdentifiers.alsoArchiveRootElement)
    }

    @MainActor
    private var labelList: some View {
        List {
            ForEachEnumerated(labels, id: \.element.id) { uiModel, index in
                VStack {
                    LabelPickerCell(uiModel: uiModel)
                        .onTapGesture {
                            Task {
                                await onCellTap(for: uiModel)
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("\(LabelPickerViewIdentifiers.labelCell)\(index)")
                }
                .accessibilityElement(children: .contain)
            }
            .listRowBackground(DS.Color.Background.norm)

            AddNewLabel()
                .listRowBackground(DS.Color.Background.norm)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(
                    "\(LabelPickerViewIdentifiers.createNewLabelCell)\(labels.count)"
                )
        }
        .background(DS.Color.Background.norm)
        .listStyle(.inset)
        .scrollBounceBehavior(.basedOnSize)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(LabelPickerViewIdentifiers.labelsList)
    }

    private var buttonDone: some View {
        HStack {
            Button(action: {
                onDoneTapped()
            }, label: {
                Text(L10n.Common.done)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(DS.Color.Global.white)
            })
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(DS.Color.InteractionBrand.norm)
            .accessibilityIdentifier(LabelPickerViewIdentifiers.doneButton)
        }
    }
}

// MARK: logic

extension LabelPickerView {

    private func initialiseState() async {
        let labelsOfSelectedItems = labelsOfSelectedItems()
        let selectedLabelIds: [ID: Quantifier] = labelsOfSelectedItems
            .reduce([ID: Int](), { partialResult, currentItem in
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
        var selectedIds: [ID: Quantifier] = labels
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

// MARK: cell

struct LabelPickerCellUIModel: Identifiable {
    let id: ID
    let name: String
    let color: Color
    let itemsWithLabel: Quantifier
}

private struct LabelPickerCell: View {
    let uiModel: LabelPickerCellUIModel

    private var selectionImage: ImageResource {
        if uiModel.itemsWithLabel.some {
            return DS.Icon.icMinus
        }
        return DS.Icon.icCheckmark
    }

    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .frame(width: 12)
                .foregroundStyle(uiModel.color)
                .padding(.horizontal, DS.Spacing.small)
                .accessibilityIdentifier(LabelPickerViewIdentifiers.cellIcon)

            Text(uiModel.name)
                .font(.subheadline)
                .foregroundStyle(DS.Color.Text.weak)
                .lineLimit(1)
                .accessibilityIdentifier(LabelPickerViewIdentifiers.cellText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, DS.Spacing.large)

            Spacer()
                .frame(width: DS.Spacing.large)

            Image(selectionImage)
                .opacity(uiModel.itemsWithLabel.atLeastOne ? 1 : 0)
                .foregroundStyle(DS.Color.Brand.norm)
                .accessibilityIdentifier(
                    LabelPickerViewIdentifiers.cellSelection(uiModel.itemsWithLabel.atLeastOne)
                )
        }
        .contentShape(Rectangle())
        .padding(.vertical, DS.Spacing.standard)
        .customListLeadingSeparator()
    }
}

private struct AddNewLabel: View {

    var body: some View {
        HStack() {
            Image(DS.Icon.icPlus)
                .foregroundStyle(DS.Color.Text.weak)
                .accessibilityIdentifier(LabelPickerViewIdentifiers.cellIcon)
            Text(L10n.Labels.newLabel)
                .font(.subheadline)
                .foregroundStyle(DS.Color.Text.weak)
                .padding(.leading, DS.Spacing.moderatelyLarge)
                .accessibilityIdentifier(LabelPickerViewIdentifiers.cellText)
            
        }
        .listRowBackground(DS.Color.Background.norm)
        .padding(.vertical, 10)
        .customListLeadingSeparator()
    }
}

#Preview {
    ZStack {
        List {
            LabelPickerCell(
                uiModel: .init(
                    id: .init(value: 1),
                    name: "Holidays and a very long name to check how it behaves",
                    color: .pink,
                    itemsWithLabel: .all
                )
            )
            LabelPickerCell(uiModel: .init(id: .init(value: 1), name: "Work", color: .blue, itemsWithLabel: .some))
            LabelPickerCell(uiModel: .init(id: .init(value: 1), name: "Sports", color: .green, itemsWithLabel: .none))
        }
        .listStyle(.inset)
        .padding(20)
    }
    .background(DS.Color.Background.secondary)
}

// MARK: Accessibility

private struct LabelPickerViewIdentifiers {
    static let rootItem = "bottomSheet.labelAs.rootItem"
    static let titleText = "bottomSheet.labelAs.titleText"
    static let alsoArchiveRootElement = "bottomSheet.labelAs.alsoArchive"
    static let alsoArchiveIcon = "bottomSheet.labelAs.alsoArchive.icon"
    static let alsoArchiveToggle = "bottomSheet.labelAs.alsoArchive.toggle"
    static let labelsList = "bottomSheet.labelAs.labelsList"
    static let labelCell = "bottomSheet.labelAs.labelCell"
    static let createNewLabelCell = "bottomSheet.labelAs.createNewLabelCell"
    static let cellText = "bottomSheet.cell.text"
    static let cellIcon = "bottomSheet.cell.icon"
    static let doneButton = "bottomSheet.labelAs.doneButton"
    
    static func cellSelection(_ value: Bool) -> String {
        value ? "bottomSheet.cell.selectionIcon" : ""
    }
}
