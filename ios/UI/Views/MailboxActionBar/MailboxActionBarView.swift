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

struct MailboxActionBarView: View {
    @EnvironmentObject var userSettings: UserSettings
    @ObservedObject var selectionMode: SelectionModeState

    @State private var showLabelPicker: Bool = false
    @State private var showFolderPicker: Bool = false

    private let selectedMailbox: SelectedMailbox
    private var mailboxActions: MailboxActionSettings {
        userSettings.mailboxActions
    }
    private let customLabelModel: CustomLabelModel
    private let mailboxActionable: MailboxActionable

    init(
        selectionMode: SelectionModeState,
        selectedMailbox: SelectedMailbox,
        mailboxActionable: MailboxActionable,
        customLabelModel: CustomLabelModel
    ) {
        self.selectionMode = selectionMode
        self.selectedMailbox = selectedMailbox
        self.mailboxActionable = mailboxActionable
        self.customLabelModel = customLabelModel
    }

    var body: some View {
        HStack(spacing: 48) {
            button(for: mailboxActions.action1)
                .accessibilityIdentifier(MailboxActionBarViewIdentifiers.button1)
            button(for: mailboxActions.action2)
                .accessibilityIdentifier(MailboxActionBarViewIdentifiers.button2)
            button(for: mailboxActions.action3)
                .accessibilityIdentifier(MailboxActionBarViewIdentifiers.button3)
            button(for: mailboxActions.action4)
                .accessibilityIdentifier(MailboxActionBarViewIdentifiers.button4)
            Button(action: {}, label: {
                Image(uiImage: DS.Icon.icThreeDotsHorizontal)
            })
            .accessibilityIdentifier(MailboxActionBarViewIdentifiers.button5)
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .compositingGroup()
        .shadow(radius: 2)
        .tint(DS.Color.Text.norm)
        .sheet(isPresented: $showLabelPicker, content: { labelPickerView })
        .sheet(isPresented: $showFolderPicker, content: { folderPickerView })
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(MailboxActionBarViewIdentifiers.rootItem)
    }

    @ViewBuilder
    private func button(for mailboxAction: MailboxAction?) -> some View {
        if let action = mailboxAction?
            .toAction(
                selectionReadStatus: selectionMode.selectionStatus.readStatus,
                selectionStarStatus: selectionMode.selectionStatus.starStatus,
                systemFolder: selectedMailbox.systemFolder ?? .inbox
            ) {
            Button(action: {
                if case .labelAs = action {
                    showLabelPicker.toggle()
                } else if case .moveTo = action {
                    showFolderPicker.toggle()
                } else {
                    mailboxActionable.onActionTap(action)
                }
            }, label: {
                Image(uiImage: action.icon)
            })
        } else {
            EmptyView()
        }
    }

    private var labelPickerView: some View {
        LabelPickerView(
            customLabelModel: customLabelModel,
            labelsOfSelectedItems: mailboxActionable.labelsOfSelectedItems,
            onDoneTap: { selectedLabelIds, alsoArchive in
                showLabelPicker.toggle()
                mailboxActionable.onLabelsSelected(labelIds: selectedLabelIds, alsoArchive: alsoArchive)
            }
        )
        .pickerViewStyle()
    }

    private var folderPickerView: some View {
        FolderPickerView(onSelectionDone: { selectedFolderId in
            showFolderPicker.toggle()
            mailboxActionable.onFolderSelected(labelId: selectedFolderId)
        })
        .pickerViewStyle()
    }
}

private extension View {

    func pickerViewStyle() -> some View {
        self
            .background(DS.Color.Background.secondary)
            .safeAreaPadding(.top, DS.Spacing.extraLarge)
            .presentationContentInteraction(.scrolls)
            .presentationCornerRadius(24)
            .presentationDetents([.medium, .large])
    }
}

#Preview {
    let userSettings = UserSettings(
        mailboxActions: .init(
            action1: .toggleReadStatus,
            action2: .toggleStarStatus,
            action3: .moveToTrash,
            action4: .moveToArchive
        )
    )

    return VStack {
        MailboxActionBarView(
            selectionMode:.init(selectedItems: Set([.init(id: 1, isRead: false, isStarred: true)])),
            selectedMailbox: .label(localLabelId: 0, name: "", systemFolder: .archive),
            mailboxActionable: EmptyMailboxActionable(),
            customLabelModel: .init()
        )

        MailboxActionBarView(
            selectionMode: .init(selectedItems: Set([.init(id: 1, isRead: true, isStarred: false)])),
            selectedMailbox: .label(localLabelId: 0, name: "", systemFolder: .trash),
            mailboxActionable: EmptyMailboxActionable(),
            customLabelModel: .init()
        )
    }
    .environmentObject(userSettings)

}

// MARK: Accessibility

private struct MailboxActionBarViewIdentifiers {
    static let rootItem = "mailbox.actionBar.rootItem"
    static let button1 = "mailbox.actionBar.button1"
    static let button2 = "mailbox.actionBar.button2"
    static let button3 = "mailbox.actionBar.button3"
    static let button4 = "mailbox.actionBar.button4"
    static let button5 = "mailbox.actionBar.button5"
}
