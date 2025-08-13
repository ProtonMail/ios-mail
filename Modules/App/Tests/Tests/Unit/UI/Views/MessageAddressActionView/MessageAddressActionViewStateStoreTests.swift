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
import InboxCoreUI
import InboxTesting
import proton_app_uniffi
import Testing

@MainActor
final class MessageAddressActionViewStateStoreTests {
    private lazy var sut: MessageAddressActionViewStateStore = makeSUT()
    private var toastStateStore = ToastStateStore(initialState: .initial)
    private var blockSpy = BlockAddressSpy()

    private let displayName = "Camila"
    private let email = "camila.hall@gmail.com"
    private let avatar = AvatarUIModel(
        info: .init(initials: "Aa", color: .purple),
        type: .sender(params: .init())
    )

    @Test
    func testInitialState() {
        #expect(sut.state == .init(avatar: avatar, name: displayName, email: email, emailToBlock: nil))
    }

    @Test
    func testOnTapBlockContact_ItPresentsAlert() async {
        await sut.handle(action: .onTap(.blockContact))

        #expect(sut.state == .init(avatar: avatar, name: displayName, email: email, emailToBlock: email))
        #expect(blockSpy.calls == [])
        #expect(toastStateStore.state.toasts == [])
    }

    @MainActor
    func testOnBlockAlertAction_CancelActionTapped_ItDismissesAlertAndDoesNotCallBlock() async {
        await sut.handle(action: .onTap(.blockContact))
        await sut.handle(action: .onBlockAlertAction(.cancel))

        #expect(sut.state == .init(avatar: avatar, name: displayName, email: email, emailToBlock: .none))
        #expect(blockSpy.calls == [])
        #expect(toastStateStore.state.toasts == [])
    }

    @Test
    func testOnBlockAlertAction_ConfirmActionTappedAndSucceeds_ItShowsInformationToast() async {
        blockSpy.stubbed[email] = .ok

        await sut.handle(action: .onTap(.blockContact))
        await sut.handle(action: .onBlockAlertAction(.confirm))

        #expect(sut.state == .init(avatar: avatar, name: displayName, email: email, emailToBlock: .none))
        #expect(blockSpy.calls == [email])
        #expect(toastStateStore.state.toasts == [.information(message: "Sender blocked")])
    }

    @Test
    func testOnBlockAlertAction_ConfirmActionTappedAndFailed_ItShowsErrorToast() async {
        blockSpy.stubbed[email] = .error(.other(.network))

        await sut.handle(action: .onTap(.blockContact))
        await sut.handle(action: .onBlockAlertAction(.confirm))

        #expect(sut.state == .init(avatar: avatar, name: displayName, email: email, emailToBlock: .none))
        #expect(blockSpy.calls == [email])
        #expect(toastStateStore.state.toasts == [.error(message: "Could not block sender")])
    }

    @Test
    func testOnTapOtherActions_ItShowComingSoon() async {
        let actions: [MessageAddressAction] = [
            .newMessage,
            .call,
            .addToContacts,
            .copyAddress,
            .copyName,
        ]

        for action in actions {
            await sut.handle(action: .onTap(action))

            #expect(toastStateStore.state.toasts == [.comingSoon])
            #expect(blockSpy.calls == [])
            #expect(sut.state.emailToBlock == nil)
        }
    }

    // MARK: - Private

    private func makeSUT() -> MessageAddressActionViewStateStore {
        .init(
            avatar: avatar,
            name: displayName,
            email: email,
            session: .dummy,
            toastStateStore: toastStateStore,
            blockAddress: { [unowned self] session, address in
                await self.blockSpy.result(for: address)
            }
        )
    }
}

private final class BlockAddressSpy: @unchecked Sendable {
    private(set) var calls: [String] = []
    var stubbed: [String: VoidActionResult] = [:]

    func result(for email: String) async -> VoidActionResult {
        calls.append(email)
        return stubbed[email] ?? .ok
    }
}
