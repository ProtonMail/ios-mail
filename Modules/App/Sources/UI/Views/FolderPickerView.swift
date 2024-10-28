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

struct FolderPickerView: View {
    typealias OnSelectionDone = (_ selectedLabelId: ID) -> Void

    @State private var customFolders: [FolderPickerCellUIModel] = []
    @State private var moveToSystemFolders: [FolderPickerCellUIModel] = []
    private let moveToFolderModel: MoveToFolderModel = .init()
    private let onSelectionDone: OnSelectionDone

    init(onSelectionDone: @escaping OnSelectionDone) {
        self.onSelectionDone = onSelectionDone
    }

    var body: some View {
        ZStack {
            VStack(spacing: DS.Spacing.large) {
                titleView
                folderList
            }
        }
        .task {
            customFolders = await moveToFolderModel
                .customFoldersHierarchy()
                .flatMap { $0.preorderTreeTraversal() }
                .map(\.cellModel)

            moveToSystemFolders = await moveToFolderModel
                .moveToSystemFolders()
                .map(\.cellModel)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(FolderPickerViewIdentifiers.rootItem)
    }
}

extension FolderPickerView {

    private var titleView: some View {
        Text(L10n.Folders.title)
            .font(.subheadline)
            .fontWeight(.bold)
            .accessibilityIdentifier(FolderPickerViewIdentifiers.titleText)
    }

    @MainActor
    private var folderList: some View {
        List {
            Section {
                forEachFor(folders: customFolders) { uiModel in
                    onSelectionDone(uiModel.id)
                }
                AddNewFolder()
                    .listRowBackground(DS.Color.Background.norm)
            }
            .accessibilityIdentifier(FolderPickerViewIdentifiers.foldersList)

            Section {
                forEachFor(folders: moveToSystemFolders) { uiModel in
                    onSelectionDone(uiModel.id)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(FolderPickerViewIdentifiers.systemFoldersList)
        }
        .padding(.horizontal, -DS.Spacing.small)
        .customListRemoveTopInset()
        .background(DS.Color.Background.secondary)
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .accessibilityElement(children: .contain)
    }

    private func forEachFor(folders: [FolderPickerCellUIModel], onSelection: @escaping (_ uiModel: FolderPickerCellUIModel) -> Void) -> some View {
        ForEachEnumerated(folders, id: \.element.id) { uiModel, index in
            FolderPickerCell(uiModel: uiModel)
                .onTapGesture {
                    onSelection(uiModel)
                }
                .accessibilityIdentifier("\(FolderPickerViewIdentifiers.folderCell)\(index)")
        }
        .listRowBackground(DS.Color.Background.norm)
        .accessibilityElement(children: .contain)
    }
}

private struct AddNewFolder: View {

    var body: some View {
        HStack() {
            Image(DS.Icon.icPlus)
                .foregroundStyle(DS.Color.Text.weak)
            Text(L10n.Folders.newFolder)
                .font(.subheadline)
                .foregroundStyle(DS.Color.Text.weak)
                .padding(.leading, DS.Spacing.moderatelyLarge)
        }
        .listRowBackground(DS.Color.Background.norm)
        .padding(.vertical, 10)
        .accessibilityIdentifier(FolderPickerViewIdentifiers.createNewFolderCell)
    }
}

// MARK: cell

struct FolderPickerCellUIModel: Identifiable {
    let id: ID
    let name: String
    let icon: ImageResource
    let level: UInt
}

private struct FolderPickerCell: View {
    let uiModel: FolderPickerCellUIModel

    var body: some View {
        HStack() {
            Image(uiModel.icon)
                .foregroundStyle(DS.Color.Icon.weak)
                .padding(.leading, CGFloat(20 * uiModel.level))
                .accessibilityIdentifier(FolderPickerViewIdentifiers.cellIcon)
            Text(uiModel.name)
                .font(.subheadline)
                .foregroundStyle(DS.Color.Text.weak)
                .lineLimit(1)
                .padding(.leading, DS.Spacing.moderatelyLarge)
                .padding(.leading, DS.Spacing.small)
                .accessibilityIdentifier(FolderPickerViewIdentifiers.cellText)
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.vertical, DS.Spacing.standard)
        .customListLeadingSeparator()
        .accessibilityElement(children: .contain)
    }
}

// MARK: Accessibility

private struct FolderPickerViewIdentifiers {
    static let rootItem = "bottomSheet.moveTo.rootItem"
    static let titleText = "bottomSheet.moveTo.titleText"
    static let foldersList = "bottomSheet.moveTo.foldersList"
    static let systemFoldersList = "bottomSheet.moveTo.systemFoldersList"
    static let folderCell = "bottomSheet.moveTo.folderCell"
    static let createNewFolderCell = "bottomSheet.moveTo.createNewFolderCell"
    static let cellText = "bottomSheet.cell.text"
    static let cellIcon = "bottomSheet.cell.icon"
}
