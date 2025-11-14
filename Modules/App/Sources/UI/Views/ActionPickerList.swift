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
import ProtonUIFoundations
import SwiftUI

protocol ActionPickerListElement: Equatable {
    var icon: Image { get }
    var name: LocalizedStringResource { get }
}

struct ActionPickerList<Header: View, Element: ActionPickerListElement>: View {
    @State private var highlightedElement: Element? = nil

    @ViewBuilder private var headerContent: () -> Header
    private var sections: [[Element]]
    private var onElementTap: (Element) -> Void

    init(
        headerContent: @escaping () -> Header,
        sections: [[Element]],
        onElementTap: @escaping (Element) -> Void
    ) {
        self.headerContent = headerContent
        self.sections = sections
        self.onElementTap = onElementTap
    }

    var body: some View {
        List {
            Section {
                headerContent()
                    .listRowInsets(EdgeInsets())
            }
            .listSectionSpacing(DS.Spacing.medium)

            ForEachEnumerated(sections, id: \.offset) { section, index in
                sectionView(elements: section, sectionIndex: index)
            }
        }
        .padding(.vertical, DS.Spacing.standard)
        .padding(.horizontal, -DS.Spacing.small)
        .customListRemoveTopInset()
        .listSectionSpacing(DS.Spacing.medium)
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .presentationDragIndicator(.visible)
        .background(DS.Color.BackgroundInverted.norm)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(ActionPickerListIdentifiers.rootElement)
    }

    private func sectionView(elements: [Element], sectionIndex: Int) -> some View {
        Section {
            ForEachEnumerated(elements, id: \.offset) { element, index in
                cell(for: element)
                    .customListLeadingSeparator()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onElementTap(element)
                    }
                    .onLongPressGesture(
                        perform: {},
                        onPressingChanged: { isPressed in
                            highlightedElement = isPressed ? element : nil
                        }
                    )
                    .listRowBackground(
                        highlightedElement == element ? DS.Color.InteractionWeak.pressed : DS.Color.BackgroundInverted.secondary
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(
                        ActionPickerListIdentifiers.messageActionIdentifier(section: sectionIndex, index: index)
                    )
            }
        }
    }

    private func cell(for element: Element) -> some View {
        HStack(spacing: DS.Spacing.large) {
            element.icon
                .actionSheetSmallIconModifier()
                .accessibilityIdentifier(ActionPickerListIdentifiers.messageActionIcon)

            Text(element.name)
                .lineLimit(1)
                .font(.subheadline)
                .foregroundStyle(DS.Color.Text.weak)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier(ActionPickerListIdentifiers.messageActionText)
        }
    }
}

#Preview {
    struct Item: ActionPickerListElement {
        let icon: Image = Image(PreviewData.senderImage)
        let name: LocalizedStringResource = "Item".notLocalized.stringResource
    }

    return ActionPickerList(
        headerContent: {
            Text("Header".notLocalized)
        }, sections: [[Item()]]
    ) { _ in }
    .border(.purple)
}

struct ActionPickerListIdentifiers {
    static let rootElement = "actionPicker.rootItem"
    static let messageActionIcon = "actionPicker.action.icon"
    static let messageActionText = "actionPicker.action.text"

    static func messageActionIdentifier(section: Int, index: Int) -> String {
        "actionPicker.section\(section).action\(index)"
    }
}
