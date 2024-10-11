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

import SwiftUI
import DesignSystem
import proton_app_uniffi

struct LabelAsSheet: View {
    @StateObject var model: LabelAsSheetModel

    init(model: LabelAsSheetModel) {
        self._model = StateObject(wrappedValue: model)
    }

    var body: some View {
        ClosableScreen {
            ScrollView {
                VStack(spacing: DS.Spacing.large) {
                    ActionSheetSection {
                        Toggle(isOn: shouldArchiveBinding) {
                            HStack(spacing: DS.Spacing.large) {
                                Image(DS.Icon.icArchiveBox)
                                    .resizable()
                                    .square(size: 20)
                                    .padding(.leading, DS.Spacing.large)
                                Text("Also archive?".notLocalized)
                                    .font(.body)
                                    .foregroundStyle(DS.Color.Text.weak)
                                Spacer()
                            }
                        }
                        .frame(height: 52)
                        .tint(DS.Color.Brand.norm)
                        .padding(.trailing, DS.Spacing.large)
                    }
                    ActionSheetSection {
                        ForEachLast(collection: model.state.labels) { label, isLast in
                            ActionSheetSelectableColorButton(
                                displayData: label.displayData,
                                displayBottomSeparator: !isLast,
                                action: { model.handle(action: .selected(label)) }
                            )
                        }
                    }
                }
                .padding(.all, DS.Spacing.large)
            }
            .background(DS.Color.Background.secondary)
            .navigationTitle("Label as...".notLocalized)
            .navigationBarTitleDisplayMode(.inline)
            .task { await model.loadLabels() }
        }
    }

    private var shouldArchiveBinding: Binding<Bool> {
        .init(
            get: { model.state.shouldArchive },
            set: { _ in model.handle(action: .toggleSwitch) }
        )
    }
}

#Preview {
    LabelAsSheet(model: LabelAsSheetPreviewProvider.testData())
}

private extension LabelDisplayModel {

    var displayData: ActionColorButtonDisplayData {
        .init(color: Color(hex: hexColor), title: title, isSelected: isSelected)
    }

}
