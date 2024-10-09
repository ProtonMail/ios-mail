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
import proton_app_uniffi
import DesignSystem

struct MailboxItemActionsSheet: View {
    @StateObject var model: MailboxItemActionsSheetModel

    init(model: MailboxItemActionsSheetModel) {
        _model = .init(wrappedValue: model)
    }

    var body: some View {
        ClosableScreen {
            ScrollView {
                VStack(spacing: DS.Spacing.standard) {
                    HStack(spacing: DS.Spacing.standard) {
                        ForEach(model.state.availableActions.replyActions, id: \.self) { action in
                            replyButton(action: action)
                        }
                    }
                    section(displayData: model.state.availableActions.mailboxItemActions.map(\.displayData))
                    section(displayData: model.state.availableActions.moveActions.map(\.displayData))
                    section(displayData: model.state.availableActions.generalActions.map(\.displayData))
                }.padding(.all, DS.Spacing.large)
            }
            .background(DS.Color.Background.secondary)
            .navigationTitle(model.state.title)
            .navigationBarTitleDisplayMode(.inline)
            .task { await model.loadActions() }
        }
    }

    private func section(displayData: [ActionDisplayData]) -> some View {
        section {
            ForEachLast(data: displayData) { displayData, isLast in
                listButton(displayData: displayData, displayBottomSeparator: !isLast)
            }
        }
    }

    private func section<Content: View>(content: () -> Content) -> some View {
        VStack(spacing: .zero) {
            content()
        }
        .background(DS.Color.BackgroundInverted.secondary)
        .clipShape(.rect(cornerRadius: DS.Radius.extraLarge))
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

    private func listButton(displayData: ActionDisplayData, displayBottomSeparator: Bool) -> some View {
        VStack(spacing: .zero) {
            Button(action: { print("Action") }) {
                HStack(spacing: DS.Spacing.large) {
                    Image(displayData.image)
                        .resizable()
                        .square(size: 20)
                        .foregroundStyle(DS.Color.Icon.norm)
                    Text(displayData.title)
                        .foregroundStyle(DS.Color.Text.weak)
                    Spacer()
                }
                .frame(height: 52)
                .padding(.leading, DS.Spacing.large)
            }
            .buttonStyle(RegularButtonStyle())

            if displayBottomSeparator {
                Divider()
                    .frame(height: 1)
            }
        }
    }

}

#Preview {
    MailboxItemActionsSheet(model: MailboxItemActionsSheetPreviewProvider.testData())
}
