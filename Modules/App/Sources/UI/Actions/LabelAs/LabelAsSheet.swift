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
    @State var isOn = false

    init(model: LabelAsSheetModel) {
        self._model = StateObject(wrappedValue: model)
    }

    var body: some View {
        ClosableScreen {
            ScrollView {
                VStack(spacing: DS.Spacing.large) {
                    ActionSheetSection {
                            Toggle(isOn: $isOn) {
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
                        ForEachLast(collection: model.state) { label, isLast in
                            listButton(label: label, displayBottomSeparator: !isLast)
                        }
                    }
                }
                .padding(.all, DS.Spacing.large)
            }
            .background(DS.Color.Background.secondary)
            .navigationTitle("Label as...".notLocalized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func listButton(label: LabelDisplayModel, displayBottomSeparator: Bool) -> some View {
        ActionSheetSelectableColorButton(
            displayData: label.displayData,
            displayBottomSeparator: displayBottomSeparator,
            action: { model.handle(action: .selected(label)) }
        )
    }
}

#Preview {
    var model = LabelAsSheetModel()
    model.state = [
        .init(id: .init(value: 1), hexColor: "#F67900", title: "Private", isSelected: .partial),
        .init(id: .init(value: 2), hexColor: "#E93671", title: "Personal", isSelected: .selected),
        .init(id: .init(value: 3), hexColor: "#9E329A", title: "Summer trip", isSelected: .unselected)
    ]
    return LabelAsSheet(model: model)
}

extension IsSelected {

    var image: ImageResource? {
        switch self {
        case .selected:
            DS.Icon.icCheckmark
        case .partial:
            DS.Icon.icMinus
        case .unselected:
            nil
        }
    }

}

private extension LabelDisplayModel {

    var displayData: ActionColorButtonDisplayData {
        .init(color: Color(hex: hexColor), title: title, isSelected: isSelected)
    }

}
