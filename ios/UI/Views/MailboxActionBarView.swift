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

protocol MailboxActionable {
    
    @MainActor
    func labelsOfSelectedItems() -> [Set<PMLocalLabelId>]

    @MainActor 
    func onActionTap(_ action: Action)

    @MainActor
    func onLabelsSelected(labelIds: Set<PMLocalLabelId>, alsoArchive: Bool)
}

struct EmptyMailboxActionable: MailboxActionable {
    func labelsOfSelectedItems() -> [Set<PMLocalLabelId>] { [] }
    func onActionTap(_ action: Action) {}
    func onLabelsSelected(labelIds: Set<PMLocalLabelId>, alsoArchive: Bool) {}
}


struct MailboxActionBarView: View {
    @EnvironmentObject var userSettings: UserSettings
    @ObservedObject var selectionMode: SelectionModeState

    private let mailbox: SelectedMailbox
    private var mailboxActions: MailboxActionSettings {
        userSettings.mailboxActions
    }
    private let customLabelModel: CustomLabelModel
    private let mailboxActionable: MailboxActionable

    @State private var showLabelPicker: Bool = false

    init(
        selectionMode: SelectionModeState,
        mailbox: SelectedMailbox,
        mailboxActionable: MailboxActionable,
        customLabelModel: CustomLabelModel
    ) {
        self.selectionMode = selectionMode
        self.mailbox = mailbox
        self.mailboxActionable = mailboxActionable
        self.customLabelModel = customLabelModel
    }

    var body: some View {
        HStack(spacing: 48) {
            button(for: mailboxActions.action1)
            button(for: mailboxActions.action2)
            button(for: mailboxActions.action3)
            button(for: mailboxActions.action4)
            Button(action: {}, label: {
                Image(uiImage: DS.Icon.icThreeDotsHorizontal)
            })
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .compositingGroup()
        .shadow(radius: 2)
        .tint(DS.Color.Text.norm)
        .sheet(isPresented: $showLabelPicker, content: { labelPicker })
    }

    @ViewBuilder
    private func button(for mailboxAction: MailboxAction?) -> some View {
        if let action = mailboxAction?
            .toAction(
                selectionReadStatus: selectionMode.selectionStatus.readStatus,
                selectionStarStatus: selectionMode.selectionStatus.starStatus,
                systemFolder: mailbox.systemFolder ?? .inbox
            ) {
            Button(action: {
                if case .labelAs = action {
                    showLabelPicker.toggle()
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

    private var labelPicker: some View {
        let model = LabelPickerModel(
            model: customLabelModel,
            labelIdsByItem: mailboxActionable.labelsOfSelectedItems(),
            onDoneTap: { selectedLabelIds, alsoArchive in
                showLabelPicker.toggle()
                mailboxActionable.onLabelsSelected(labelIds: selectedLabelIds, alsoArchive: alsoArchive)
            }
        )
        return LabelPickerView(model: model)
            .safeAreaPadding(.top, DS.Spacing.extraLarge)
            .presentationContentInteraction(.scrolls)
            .presentationCornerRadius(24)
            .presentationDetents([.medium, .large])
    }
}

#Preview {
    let userSettings = UserSettings(
        mailboxViewMode: .conversation,
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
            mailbox: .init(localId: 0, name: "", systemFolder: .archive),
            mailboxActionable: EmptyMailboxActionable(),
            customLabelModel: .init()
        )

        MailboxActionBarView(
            selectionMode: .init(selectedItems: Set([.init(id: 1, isRead: true, isStarred: false)])),
            mailbox: .init(localId: 0, name: "", systemFolder: .trash),
            mailboxActionable: EmptyMailboxActionable(),
            customLabelModel: .init()
        )
    }
    .environmentObject(userSettings)

}
