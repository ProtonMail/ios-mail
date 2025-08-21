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

@testable import ProtonMail
import proton_app_uniffi
import Testing

@MainActor
class MessageActionsSheetStoreTests {
    var sut: MessageActionsSheetStore!
    var serviceInvoked: [(mailbox: Mailbox, theme: ThemeOpts, messageID: ID)] = []
    let stubbedMessageActions = MessageActionSheet(
        replyActions: [.reply],
        messageActions: [.markRead],
        moveActions: [.labelAs],
        generalActions: [.print]
    )
    var actionSelectedInvoked: [MessageAction] = []

    init() {
        sut = MessageActionsSheetStore(
            state: .initial(messageID: .init(value: 7), title: "Hello"),
            mailbox: .dummy,
            messageAppearanceOverrideStore: MessageAppearanceOverrideStore(),
            service: { mailbox, theme, messageID in
                self.serviceInvoked.append((mailbox, theme, messageID))

                return .ok(self.stubbedMessageActions)
            },
            actionSelected: { action in self.actionSelectedInvoked.append(action) }
        )
    }

    @Test
    func onLoad_ItFetchesActions() async throws {
        await sut.handle(action: .colorSchemeChanged(.dark))
        await sut.handle(action: .onLoad)

        #expect(serviceInvoked.count == 1)

        let serviceCall = try #require(serviceInvoked.first)
        #expect(serviceCall.theme == .init(colorScheme: .dark, isForcingLightMode: false))
        #expect(serviceCall.messageID == .init(value: 7))

        #expect(
            sut.state
                == .init(
                    messageID: .init(value: 7),
                    title: "Hello",
                    actions: stubbedMessageActions,
                    colorScheme: .dark
                ))
    }

    @Test
    func actionIsSlected_ItEmitsCorrectAction() async {
        await sut.handle(action: .actionSelected(.reply))

        #expect(actionSelectedInvoked == [.reply])
    }
}
