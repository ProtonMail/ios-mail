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
import proton_app_uniffi
import SwiftUI

struct MoveToSheet: View {
    @StateObject var model: MoveToSheetModel

    init(model: MoveToSheetModel) {
        self._model = StateObject(wrappedValue: model)
    }

    var body: some View {
        ClosableScreen {
            ScrollView {
                VStack(spacing: DS.Spacing.large) {
                    moveToCustomFolderSection()
                    moveToSystemFolderSection()
                }
                .padding(.all, DS.Spacing.large)
            }
            .background(DS.Color.Background.secondary)
            .navigationTitle(L10n.Action.moveTo.string)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { model.handle(action: .viewAppear) }
            .sheet(isPresented: $model.state.createFolderLabelPresented) {
                CreateFolderOrLabelScreen()
            }
        }
    }

    // MARK: - Private

    private func moveToSystemFolderSection() -> some View {
        ActionSheetSection {
            ForEachLast(collection: model.state.moveToSystemFolderActions) { moveToSystemFolder, isLast in
                ActionSheetSelectableButton(
                    displayData: moveToSystemFolder.displayData,
                    displayBottomSeparator: !isLast,
                    action: { model.handle(action: .folderTapped(id: moveToSystemFolder.id)) }
                )
            }
        }
    }

    private func moveToCustomFolderSection() -> some View {
        ActionSheetSection {
            VStack(spacing: .zero) {
                ForEach(model.state.moveToCustomFolderActions.displayData(spacing: .zero)) { displayModel in
                    ActionSheetSelectableButton(
                        displayData: displayModel,
                        displayBottomSeparator: true,
                        action: { model.handle(action: .folderTapped(id: displayModel.id)) }
                    )
                }
                ActionSheetButton(
                    displayBottomSeparator: false,
                    action: { model.handle(action: .createFolderTapped) }
                ) {
                    HStack {
                        Image(DS.Icon.icPlus)
                            .resizable()
                            .square(size: 20)
                            .foregroundStyle(DS.Color.Icon.norm)
                            .padding(.trailing, DS.Spacing.standard)
                        Text(L10n.Sidebar.createFolder)
                            .foregroundStyle(DS.Color.Text.weak)
                        Spacer()
                    }
                }
            }
        }
    }

}

private extension MoveToSystemFolder {

    var displayData: ActionSelectableButtonDisplayData {
        .init(
            id: id,
            visualAsset: .image(label.icon, color: DS.Color.Icon.norm),
            title: label.humanReadable.string,
            isSelected: isSelected,
            leadingSpacing: .zero
        )
    }

}

private extension Array where Element == MoveToCustomFolder {

    func displayData(spacing: CGFloat) -> [ActionSelectableButtonDisplayData] {
        flatMap { item in
            let displayData = ActionSelectableButtonDisplayData(
                id: item.id,
                visualAsset: .image(item.children.isEmpty ? DS.Icon.icFolder : DS.Icon.icFolders, color: item.color),
                title: item.name,
                isSelected: item.isSelected,
                leadingSpacing: spacing
            )
            return [displayData] + item.children.displayData(spacing: spacing + DS.Spacing.large)
        }
    }

}

#Preview {
    MoveToSheet(model: MoveToSheetPreviewProvider.testModel)
}
