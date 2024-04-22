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
import SwiftUIIntrospect

struct FolderPickerView: View {
    typealias OnSelectionDone = (_ selectedLabelId: PMLocalLabelId) -> Void

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
                .map { $0.toFolderPickerCellUIModel() }

            moveToSystemFolders = await moveToFolderModel
                .moveToSystemFolders()
                .map { $0.toFolderPickerCellUIModel(parentIds: .init()) }
        }
    }
}

extension FolderPickerView {

    private var titleView: some View {
        Text(LocalizationTemp.FolderPicker.title)
            .font(DS.Font.body3)
            .fontWeight(.bold)
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

            Section {
                forEachFor(folders: moveToSystemFolders) { uiModel in
                    onSelectionDone(uiModel.id)
                }
            }
        }
        .introspect(.list, on: .iOS(.v17)) { collectionView in
            // fixing the default top content inset
            collectionView.contentInset.top = -34
        }
        .background(DS.Color.Background.secondary)
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    private func forEachFor(folders: [FolderPickerCellUIModel], onSelection: @escaping (_ uiModel: FolderPickerCellUIModel) -> Void) -> some View {
        ForEach(folders) { uiModel in
            FolderPickerCell(uiModel: uiModel)
                .onTapGesture {
                    onSelection(uiModel)
                }
        }
        .listRowBackground(DS.Color.Background.norm)
    }
}

private struct AddNewFolder: View {

    var body: some View {
        HStack() {
            Image(uiImage: DS.Icon.icPlus)
                .foregroundStyle(DS.Color.Text.weak)
            Text(LocalizationTemp.FolderPicker.newFolder)
                .font(DS.Font.body3)
                .foregroundStyle(DS.Color.Text.weak)
                .padding(.leading, DS.Spacing.moderatelyLarge)
        }
        .listRowBackground(DS.Color.Background.norm)
        .padding(.vertical, 10)
    }
}

// MARK: cell

struct FolderPickerCellUIModel: Identifiable {
    let id: PMLocalLabelId
    let name: String
    let icon: UIImage
    let level: UInt
}

private struct FolderPickerCell: View {
    let uiModel: FolderPickerCellUIModel

    var body: some View {
        HStack() {
            Image(uiImage: uiModel.icon)
                .foregroundStyle(DS.Color.Icon.weak)
                .padding(.leading, CGFloat(20 * uiModel.level))
            Text(uiModel.name)
                .font(DS.Font.body3)
                .foregroundStyle(DS.Color.Text.weak)
                .lineLimit(1)
                .padding(.leading, DS.Spacing.moderatelyLarge)
                .padding(.leading, DS.Spacing.small)
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.vertical, DS.Spacing.standard)
        .customListLeadingSeparator()
    }
}
