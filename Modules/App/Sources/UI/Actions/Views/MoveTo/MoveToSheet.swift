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
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

struct MoveToSheet: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    private let initialState: MoveToState
    private let input: ActionSheetInput
    private let mailbox: Mailbox
    private let availableMoveToActions: AvailableMoveToActions
    private let moveToActions: MoveToActions
    private let navigation: (MoveToSheetNavigation) -> Void
    private let mailUserSession: MailUserSession

    init(
        initialState: MoveToState = .initial,
        input: ActionSheetInput,
        mailbox: Mailbox,
        availableMoveToActions: AvailableMoveToActions,
        moveToActions: MoveToActions,
        navigation: @escaping (MoveToSheetNavigation) -> Void,
        mailUserSession: MailUserSession
    ) {
        self.initialState = initialState
        self.input = input
        self.mailbox = mailbox
        self.availableMoveToActions = availableMoveToActions
        self.moveToActions = moveToActions
        self.navigation = navigation
        self.mailUserSession = mailUserSession
    }

    var body: some View {
        StoreView(
            store: MoveToSheetStateStore(
                state: initialState,
                input: input,
                mailbox: mailbox,
                availableMoveToActions: availableMoveToActions,
                toastStateStore: toastStateStore,
                moveToActions: moveToActions,
                navigation: navigation,
                mailUserSession: mailUserSession
            )
        ) { state, store in
            ClosableScreen {
                ScrollView {
                    VStack(spacing: DS.Spacing.large) {
                        moveToCustomFolderSection(state: state, store: store)
                        moveToSystemFolderSection(state: state, store: store)
                    }
                    .padding(.all, DS.Spacing.large)
                }
                .background(DS.Color.BackgroundInverted.norm)
                .navigationTitle(L10n.Action.moveTo.string)
                .navigationBarTitleDisplayMode(.inline)
                .onAppear { store.handle(action: .viewAppear) }
                .sheet(isPresented: store.binding(\.createFolderLabelPresented)) {
                    CreateFolderOrLabelScreen()
                }
            }
        }
    }

    // MARK: - Private

    private func moveToSystemFolderSection(state: MoveToState, store: MoveToSheetStateStore) -> some View {
        ActionSheetSection {
            ForEachLast(collection: state.moveToSystemFolderActions) { moveToSystemFolder, isLast in
                ActionSheetSelectableButton(
                    displayData: moveToSystemFolder.displayData,
                    displayBottomSeparator: !isLast,
                    action: { store.handle(action: .systemFolderTapped(moveToSystemFolder)) }
                )
            }
        }
    }

    private func moveToCustomFolderSection(state: MoveToState, store: MoveToSheetStateStore) -> some View {
        ActionSheetSection {
            VStack(spacing: .zero) {
                ForEach(
                    state.moveToCustomFolderActions.displayData(spacing: .zero)
                ) { displayModel in
                    ActionSheetSelectableButton(
                        displayData: displayModel,
                        displayBottomSeparator: true,
                        action: {
                            store.handle(
                                action: .customFolderTapped(.init(id: displayModel.id, name: displayModel.title))
                            )
                        }
                    )
                }
                ActionSheetButton(
                    displayBottomSeparator: false,
                    action: { store.handle(action: .createFolderTapped) }
                ) {
                    HStack {
                        Image(DS.Icon.icPlus)
                            .resizable()
                            .square(size: 20)
                            .foregroundStyle(DS.Color.Icon.norm)
                            .padding(.trailing, DS.Spacing.standard)
                        Text(L10n.Sidebar.createFolder)
                            .foregroundStyle(DS.Color.Text.norm)
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
            visualAsset: .image(label.displayData.image, color: DS.Color.Icon.norm),
            title: label.displayData.title.string,
            isSelected: .unselected,
            leadingSpacing: .zero
        )
    }

}

private extension Array where Element == MoveToCustomFolder {

    func displayData(spacing: CGFloat) -> [ActionSelectableButtonDisplayData] {
        flatMap { item in
            let displayData = ActionSelectableButtonDisplayData(
                id: item.id,
                visualAsset: .image(
                    item.children.isEmpty ? DS.Icon.icFolderFilled.image : DS.Icon.icFoldersFilled.image,
                    color: item.color
                ),
                title: item.name,
                isSelected: .unselected,
                leadingSpacing: spacing
            )
            return [displayData] + item.children.displayData(spacing: spacing + DS.Spacing.large)
        }
    }

}

#Preview {
    MoveToSheet(
        input: .init(sheetType: .moveTo, ids: [], mailboxItem: .message(isLastMessageInCurrentLocation: false)),
        mailbox: .dummy,
        availableMoveToActions: MoveToSheetPreviewProvider.availableMoveToActions,
        moveToActions: .dummy,
        navigation: { _ in },
        mailUserSession: .dummy
    )
}
