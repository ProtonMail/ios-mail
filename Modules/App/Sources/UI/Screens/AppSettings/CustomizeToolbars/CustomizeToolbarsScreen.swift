// Copyright (c) 2025 Proton Technologies AG
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
import InboxCore
import InboxCoreUI
import InboxDesignSystem

struct CustomizeToolbarsScreen: View {
    @StateObject private var store: CustomizeToolbarsStore
    private let customizeToolbarService: CustomizeToolbarServiceProtocol

    init(
        state: CustomizeToolbarState = .initial,
        customizeToolbarService: CustomizeToolbarServiceProtocol,
        viewModeProvider: ViewModeProvider
    ) {
        self.customizeToolbarService = customizeToolbarService
        self._store = .init(
            wrappedValue: .init(
                state: state,
                customizeToolbarService: customizeToolbarService,
                viewModeProvider: viewModeProvider
            ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.extraLarge) {
                ForEachEnumerated(store.state.toolbars, id: \.offset) { toolbar, _ in
                    FormSection(header: toolbar.header, footer: toolbar.footer) {
                        list(for: toolbar.actions.displayItems) {
                            store.handle(action: .editToolbarTapped(toolbar.toolbarType))
                        }
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.large)
            .padding(.bottom, DS.Spacing.extraLarge)
        }.onAppear {
            store.handle(action: .onAppear)
        }
        .onChange(
            of: store.state.editToolbar,
            { oldValue, newValue in
                if oldValue != nil && newValue == nil {
                    store.handle(action: .onAppear)
                }
            }
        )
        .sheet(
            item: $store.state.editToolbar,
            content: { toolbarType in
                NavigationStack {
                    EditToolbarScreen(
                        state: .initial(toolbarType: toolbarType),
                        customizeToolbarService: customizeToolbarService
                    )
                }
            }
        )
        .background(DS.Color.BackgroundInverted.norm)
        .navigationTitle(L10n.Settings.App.customizeToolbars.string)
    }

    private func list(for items: [CustomizeToolbarsDisplayItem], editToolbarAction: @escaping () -> Void) -> some View {
        FormList(collection: items, separator: .normLeftPadding) { item in
            listItem(item, editToolbarAction: editToolbarAction)
        }
        .roundedRectangleStyle()
    }

    @ViewBuilder
    private func listItem(_ item: CustomizeToolbarsDisplayItem, editToolbarAction: @escaping () -> Void) -> some View {
        switch item {
        case .action(let model):
            HStack(spacing: DS.Spacing.medium) {
                model.displayData.image
                Text(model.displayData.title)
                    .foregroundStyle(DS.Color.Text.norm)
                Spacer()
            }
            .padding(.vertical, DS.Spacing.moderatelyLarge)
            .padding(.horizontal, DS.Spacing.large)
        case .editActions:
            Button(action: editToolbarAction) {
                HStack {
                    Text(L10n.Settings.CustomizeToolbars.editActions)
                    Spacer()
                    Image(symbol: DS.SFSymbol.chevronRight)
                }
                .foregroundStyle(DS.Color.Text.accent)
                .padding(.vertical, DS.Spacing.moderatelyLarge)
                .padding(.horizontal, DS.Spacing.large)
            }
        }
    }
}

import proton_app_uniffi

extension MobileAction {

    var displayData: ActionDisplayData {
        if let displayData = action?.displayData {
            return displayData
        }
        return .init(title: "It's not archive", image: DS.Icon.icArchiveBox.image)
    }

    private var action: Action? {
        switch self {
        case .archive:
            Action.moveToArchive
        case .forward:
            Action.forward
        case .label:
            Action.labelAs
        case .move:
            Action.moveTo
        case .print:
            Action.print
        case .reply:
            Action.reply
        case .reportPhishing:
            Action.reportPhishing
        case .savePdf:
            Action.saveAsPDF
        case .snooze:
            Action.snooze
        case .spam:
            Action.moveToSpam
        case .toggleLight:
            Action.renderInLightMode
        case .toggleRead:
            Action.markAsRead
        case .toggleStar:
            Action.star
        case .trash:
            Action.moveToTrash
        case .viewHeaders:
            Action.viewHeaders
        case .viewHtml:
            Action.viewHTML
        case .other, .senderEmails, .saveAttachments, .remind:
            nil
        }
    }

}

private extension ToolbarWithActions {

    var header: LocalizedStringResource {
        switch self {
        case .list:
            L10n.Settings.CustomizeToolbars.listToolbarSectionTitle
        case .message, .conversation:
            L10n.Settings.CustomizeToolbars.conversationToolbarSectionTitle
        }
    }

    var footer: LocalizedStringResource {
        switch self {
        case .list:
            L10n.Settings.CustomizeToolbars.listToolbarSectionFooter
        case .message, .conversation:
            L10n.Settings.CustomizeToolbars.conversationToolbarSectionFooter
        }
    }

}

private extension CustomizeToolbarActions {

    var displayItems: [CustomizeToolbarsDisplayItem] {
        selected.map(CustomizeToolbarsDisplayItem.action) + [.editActions]
    }

}

private extension ToolbarWithActions {

    var toolbarType: ToolbarType {
        switch self {
        case .list:
            .list
        case .message:
            .message
        case .conversation:
            .conversation
        }
    }

}

extension ToolbarType: Identifiable {

    var id: String {
        switch self {
        case .list:
            "list"
        case .message:
            "message"
        case .conversation:
            "conversation"
        }
    }

}
