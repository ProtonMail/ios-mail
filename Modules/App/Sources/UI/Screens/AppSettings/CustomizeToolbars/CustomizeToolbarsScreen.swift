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
import InboxCoreUI
import InboxDesignSystem

struct CustomizeToolbarsScreen: View {
    @StateObject private var store: CustomizeToolbarsStore

    init(state: CustomizeToolbarState = .initial, toolbarService: ToolbarServiceProtocol) {
        self._store = .init(wrappedValue: .init(state: state, toolbarService: toolbarService))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.extraLarge) {
                FormSection(
                    header: L10n.Settings.CustomizeToolbars.listToolbarSectionTitle,
                    footer: L10n.Settings.CustomizeToolbars.listToolbarSectionFooter
                ) {
                    list(for: store.state.list) {
                        store.handle(action: .editListToolbar)
                    }
                }

                FormSection(
                    header: L10n.Settings.CustomizeToolbars.conversationToolbarSectionTitle,
                    footer: L10n.Settings.CustomizeToolbars.conversationToolbarSectionFooter
                ) {
                    list(for: store.state.conversation) {
                        store.handle(action: .editConversationToolbar)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.large)
            .padding(.bottom, DS.Spacing.extraLarge)
        }.onLoad {
            store.handle(action: .onLoad)
        }
        .background(DS.Color.BackgroundInverted.norm)
        .navigationTitle(L10n.Settings.App.customizeToolbars.string)
    }

    private func list(for items: [CustomizeToolbarsItem], editToolbarAction: @escaping () -> Void) -> some View {
        FormList(collection: items, separator: .normLeftPadding) { item in
            listItem(item, editToolbarAction: editToolbarAction)
        }
        .roundedRectangleStyle()
    }

    @ViewBuilder
    private func listItem(_ item: CustomizeToolbarsItem, editToolbarAction: @escaping () -> Void) -> some View {
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

#Preview {
    CustomizeToolbarsScreen(toolbarService: ToolbarService())
}

struct ToolbarActionDisplayData {
    let image: Image
    let title: LocalizedStringResource
}

private extension ToolbarActionDisplayData {
    init(imageResource: ImageResource, title: LocalizedStringResource) {
        self.image = imageResource.image
        self.title = title
    }
}

extension ToolbarActionType {

    var displayData: ToolbarActionDisplayData {
        switch self {
        case .markAsUnread:
            .init(imageResource: DS.Icon.icEnvelopeDot, title: L10n.Action.markAsUnread)
        case .moveToTrash:
            .init(imageResource: DS.Icon.icTrash, title: L10n.Action.moveToTrash)
        case .moveTo:
            .init(imageResource: DS.Icon.icFolderArrowIn, title: L10n.Action.moveTo)
        case .labelAs:
            .init(imageResource: DS.Icon.icTag, title: L10n.Action.labelAs)
        case .snooze:
            .init(imageResource: DS.Icon.icClock, title: L10n.Action.snooze)
        case .star:
            .init(image: Image(symbol: .star), title: L10n.Action.star)
        case .archive:
            .init(imageResource: DS.Icon.icArchiveBox, title: L10n.Action.moveToArchive)
        case .moveToSpam:
            .init(imageResource: DS.Icon.icSpam, title: L10n.Action.moveToSpam)
        }
    }

}
