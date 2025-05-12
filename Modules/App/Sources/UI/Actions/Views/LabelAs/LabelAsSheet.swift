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

import InboxCore
import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct LabelAsSheet: View {
    @StateObject var model: LabelAsSheetModel

    init(model: LabelAsSheetModel) {
        self._model = StateObject(wrappedValue: model)
    }

    var body: some View {
        ClosableScreen {
            ScrollView {
                VStack(spacing: DS.Spacing.large) {
                    archiveSection()
                    labelsSection()
                    doneButton()
                }
                .padding(.all, DS.Spacing.large)
            }
            .background(DS.Color.BackgroundInverted.norm)
            .navigationTitle(L10n.Action.labelAs.string)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { model.handle(action: .viewAppear) }
            .sheet(isPresented: $model.state.createFolderLabelPresented) {
                CreateFolderOrLabelScreen()
            }
        }
    }

    // MARK: - Private

    private var shouldArchiveBinding: Binding<Bool> {
        .init(
            get: { model.state.shouldArchive },
            set: { _ in model.handle(action: .toggleSwitch) }
        )
    }

    private func archiveSection() -> some View {
        ActionSheetSection {
            Toggle(isOn: shouldArchiveBinding) {
                HStack(spacing: DS.Spacing.large) {
                    Image(DS.Icon.icArchiveBox)
                        .resizable()
                        .square(size: 20)
                        .padding(.leading, DS.Spacing.large)
                    Text(L10n.Action.alsoArchive)
                        .font(.body)
                        .foregroundStyle(DS.Color.Text.norm)
                    Spacer()
                }
            }
            .frame(height: 52)
            .tint(DS.Color.Brand.norm)
            .padding(.trailing, DS.Spacing.large)
        }
    }

    private func labelsSection() -> some View {
        ActionSheetSection {
            VStack(spacing: .zero) {
                ForEach(model.state.labels) { label in
                    ActionSheetSelectableButton(
                        displayData: label.displayData,
                        displayBottomSeparator: true,
                        action: { model.handle(action: .selected(label)) }
                    )
                }
                ActionSheetButton(
                    displayBottomSeparator: false,
                    action: { model.handle(action: .createLabelButtonTapped) }
                ) {
                    HStack {
                        Image(DS.Icon.icPlus)
                            .resizable()
                            .square(size: 20)
                            .foregroundStyle(DS.Color.Icon.norm)
                            .padding(.trailing, DS.Spacing.standard)
                        Text(L10n.Sidebar.createLabel)
                            .foregroundStyle(DS.Color.Text.norm)
                        Spacer()
                    }
                }
            }
        }
    }

    private func doneButton() -> some View {
        Button(
            action: { model.handle(action: .doneButtonTapped) },
            label: { Text(CommonL10n.done) }
        )
        .buttonStyle(BigButtonStyle())
    }
}

#Preview {
    LabelAsSheet(model: LabelAsSheetPreviewProvider.testData())
}

private extension LabelDisplayModel {

    var displayData: ActionSelectableButtonDisplayData {
        .init(id: id, visualAsset: .color(color), title: title, isSelected: isSelected, leadingSpacing: .zero)
    }

}
