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

struct MailboxItemActionSheet: View {
    @StateObject var model: MailboxItemActionSheetModel

    init(model: MailboxItemActionSheetModel) {
        _model = .init(wrappedValue: model)
    }

    var body: some View {
        ClosableScreen {
            ScrollView {
                VStack(spacing: DS.Spacing.standard) {
                    if let replyActions = model.state.availableActions.replyActions {
                        replyButtonsSection(replyActions)
                    }

                    mailboxItemActionsSection()
                    moveToActionsSection()
                    section(displayData: model.state.availableActions.generalActions.map(\.displayData))
                }.padding(.all, DS.Spacing.large)
            }
            .background(DS.Color.Background.secondary)
            .navigationTitle(model.state.title)
            .navigationBarTitleDisplayMode(.inline)
            .alert(model: $model.state.deleteConfirmationAlert) { action in
                model.handle(action: .alertActionTapped(action))
            }
        }.onLoad { model.handle(action: .viewAppear) }
    }

    private var isDeleteConfirmationAlertPresented: Binding<Bool> {
        .init(
            get: { model.state.deleteConfirmationAlert != nil },
            set: { _ in }
        )
    }

    // MARK: - Private

    private func replyButtonsSection(_ actions: [ReplyAction]) -> some View {
        HStack(spacing: DS.Spacing.standard) {
            ForEach(actions, id: \.self) { action in
                replyButton(action: action)
            }
        }
    }

    private func mailboxItemActionsSection() -> some View {
        ActionSheetSection {
            ForEachLast(collection: model.state.availableActions.mailboxItemActions) { action, isLast in
                ActionSheetImageButton(
                    displayData: action.displayData,
                    displayBottomSeparator: !isLast,
                    action: { model.handle(action: .mailboxItemActionSelected(action)) }
                )
            }
        }
    }

    private func moveToActionsSection() -> some View {
        ActionSheetSection {
            ForEachLast(collection: model.state.availableActions.moveActions) { action, isLast in
                ActionSheetImageButton(
                    displayData: action.displayData,
                    displayBottomSeparator: !isLast,
                    action: { model.handle(action: .moveTo(action)) }
                )
            }
        }
    }

    private func section(displayData: [ActionDisplayData]) -> some View {
        ActionSheetSection {
            ForEachLast(collection: displayData) { displayData, isLast in
                ActionSheetImageButton(
                    displayData: displayData,
                    displayBottomSeparator: !isLast,
                    action: { print("Action: \(displayData.title.string)") }
                )
            }
        }
    }

    private func replyButton(action: ReplyAction) -> some View {
        Button(action: { print("Action: \(action.displayData.title) tapped") }) {
            VStack(spacing: DS.Spacing.standard) {
                Image(action.displayData.image)
                    .resizable()
                    .square(size: 24)
                    .foregroundStyle(DS.Color.Icon.norm)
                Text(action.displayData.title)
                    .font(.body)
                    .foregroundStyle(DS.Color.Text.weak)
            }
            .frame(height: 84)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(RegularButtonStyle())
        .background(DS.Color.BackgroundInverted.secondary)
        .clipShape(.rect(cornerRadius: DS.Radius.extraLarge))
    }
}

#Preview {
    MailboxItemActionSheet(model: MailboxItemActionSheetPreviewProvider.testData())
}

extension View {
    func alert<AlertAction: AlertActionViewModel>(
        model: Binding<AlertViewModel<AlertAction>?>,
        handleAction: @escaping (AlertAction) -> Void
    ) -> some View {
        modifier(AlertViewModifier(model: model, handleAction: handleAction))
    }
}

struct AlertViewModifier<AlertAction: AlertActionViewModel>: ViewModifier {
    @Binding private var model: AlertViewModel<AlertAction>?
    private let handleAction: (AlertAction) -> Void

    init(model: Binding<AlertViewModel<AlertAction>?>, handleAction: @escaping (AlertAction) -> Void) {
        self._model = model
        self.handleAction = handleAction
    }

    func body(content: Content) -> some View {
        if let model {
            content.alert(
                model.title,
                isPresented: isPresented,
                presenting: model,
                actions: { model in
                    ForEach(model.actions, id: \.self) { action in
                        Button(action.title, role: action.buttonRole) {
                            handleAction(action)
                        }
                    }
                },
                message: { model in
                    if let message = model.message {
                        Text(message)
                    }
                }
            )
        } else {
            content
        }
    }

    // MARK: - Private

    private var isPresented: Binding<Bool> {
        .init(
            get: { model != nil },
            set: { _ in }
        )
    }
}
