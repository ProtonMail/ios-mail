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
import Combine
import InboxCore
import InboxCoreUI
import InboxTesting
import proton_app_uniffi
import Testing
import UIKit

@MainActor
final class MessageAddressActionViewStateStoreTests {
    private lazy var sut: MessageAddressActionViewStateStore = makeSUT()
    private let pasteboard = UIPasteboard.testInstance
    private let toastStateStore = ToastStateStore(initialState: .initial)
    private let blockSpy = BlockUnblockAddressSpy()
    private let unblockSpy = BlockUnblockAddressSpy()
    private let messageAddressSpy = RustMessageAddressWrapperSpy()
    private let draftPresenterSpy = RecipientDraftPresenterSpy()
    private let urlOpener = EnvironmentURLOpenerSpy()
    private let dismissSpy = DismissSpy()
    private let messageBannersNotifier = RefreshMessageBannersNotifier()
    private var refreshBannersCount: Int = 0
    private var cancellables: Set<AnyCancellable> = []

    private let avatar = AvatarUIModel(
        info: .init(initials: "Aa", color: .purple),
        type: .sender(SenderInfo(params: .init(), blocked: .notLoaded))
    )
    private let displayName = "Camila"
    private let email = "camila.hall@gmail.com"

    deinit {
        pasteboard.string = nil
    }

    @Test
    func testInitialState() {
        #expect(
            sut.state
                == .init(
                    avatar: avatar,
                    name: displayName,
                    email: email,
                    phoneNumber: .none,
                    emailToBlock: .none
                ))
    }

    // MARK: - `onLoad` action

    @Test
    func testOnLoad_WhenIsSenderBlockedReturnsTrue_ItUpdatesAvatarWithBlockedState() async {
        messageAddressSpy.stubbedIsSenderBlocked = .yes

        let sut = makeSUT()

        await sut.handle(action: .onLoad)

        #expect(messageAddressSpy.isSenderBlockedCalls.count == 1)
        #expect(messageAddressSpy.isSenderBlockedCalls.last?.messageID == .init(value: 1_000))
        #expect(sut.state.avatar.type == .sender(.init(params: .init(), blocked: .yes)))
    }

    @Test
    func testOnLoad_WhenIsSenderBlockedReturnsFalse_ItUpdatesAvatarWithNotBlockedState() async {
        messageAddressSpy.stubbedIsSenderBlocked = .no

        let sut = makeSUT()

        await sut.handle(action: .onLoad)

        #expect(messageAddressSpy.isSenderBlockedCalls.count == 1)
        #expect(sut.state.avatar.type == .sender(.init(params: .init(), blocked: .no)))
    }

    // MARK: - `Block address` action

    @Test
    func testOnTapBlockContact_ItPresentsAlert() async {
        await sut.handle(action: .onTap(.blockAddress))

        #expect(
            sut.state
                == .init(
                    avatar: avatar,
                    name: displayName,
                    email: email,
                    phoneNumber: .none,
                    emailToBlock: email
                ))
        #expect(blockSpy.calls == [])
        #expect(toastStateStore.state.toasts == [])
    }

    @MainActor
    func testOnTapBlockAlertAction_CancelActionTapped_ItDismissesAlertAndDoesNotCallBlock() async {
        await sut.handle(action: .onTap(.blockAddress))
        await sut.handle(action: .onBlockAlertAction(.cancel))

        #expect(
            sut.state
                == .init(
                    avatar: avatar,
                    name: displayName,
                    email: email,
                    phoneNumber: .none,
                    emailToBlock: .none
                ))

        #expect(blockSpy.calls == [])
        #expect(refreshBannersCount == 0)
        #expect(toastStateStore.state.toasts == [])
    }

    @Test
    func testOnTapBlockAlertAction_ConfirmActionTappedAndSucceeds_ItShowsInformationToast() async {
        blockSpy.stubbed[email] = .ok

        await sut.handle(action: .onTap(.blockAddress))
        await sut.handle(action: .onBlockAlertAction(.confirm))

        #expect(
            sut.state
                == .init(
                    avatar: avatar,
                    name: displayName,
                    email: email,
                    phoneNumber: .none,
                    emailToBlock: .none
                ))

        #expect(blockSpy.calls == [email])
        #expect(dismissSpy.callsCount == 1)
        #expect(refreshBannersCount == 1)
        #expect(toastStateStore.state.toasts == [.information(message: "Sender blocked")])
    }

    @Test
    func testOnTapBlockAlertAction_ConfirmActionTappedAndFailed_ItShowsErrorToast() async {
        blockSpy.stubbed[email] = .error(.other(.network))

        await sut.handle(action: .onTap(.blockAddress))
        await sut.handle(action: .onBlockAlertAction(.confirm))

        #expect(
            sut.state
                == .init(
                    avatar: avatar,
                    name: displayName,
                    email: email,
                    phoneNumber: .none,
                    emailToBlock: .none
                ))
        #expect(blockSpy.calls == [email])
        #expect(toastStateStore.state.toasts == [.error(message: "Could not block sender")])
    }

    // MARK: - `Unblock address` action

    @Test
    func testOnTapUnblockAddress_WhenActionSucceeds_ItUnblocksContact() async throws {
        messageAddressSpy.stubbedIsSenderBlocked = .yes

        let sut = makeSUT()

        await sut.handle(action: .onLoad)

        messageAddressSpy.stubbedIsSenderBlocked = .no

        await sut.handle(action: .onTap(.unblockAddress))

        let info: SenderInfo = try #require(avatar.type.senderInfo)

        #expect(
            sut.state
                == .init(
                    avatar: avatar.copy(\.type, to: .sender(info.copy(\.blocked, to: .yes))),
                    name: displayName,
                    email: email,
                    phoneNumber: .none,
                    emailToBlock: .none
                ))

        #expect(unblockSpy.calls == [email])
        #expect(dismissSpy.callsCount == 1)
        #expect(refreshBannersCount == 1)
        #expect(toastStateStore.state.toasts == [])
    }

    @Test
    func testOnTapUnblockAddress_WhenActionFails_ItDoesNotUnblockContact() async throws {
        messageAddressSpy.stubbedIsSenderBlocked = .yes
        unblockSpy.stubbed[email] = .error(.other(.network))

        let sut = makeSUT()

        await sut.handle(action: .onLoad)
        await sut.handle(action: .onTap(.unblockAddress))

        let info: SenderInfo = try #require(avatar.type.senderInfo)

        #expect(
            sut.state
                == .init(
                    avatar: avatar.copy(\.type, to: .sender(info.copy(\.blocked, to: .yes))),
                    name: displayName,
                    email: email,
                    phoneNumber: .none,
                    emailToBlock: .none
                ))

        #expect(unblockSpy.calls == [email])
        #expect(dismissSpy.callsCount == 0)
        #expect(refreshBannersCount == 0)
        #expect(toastStateStore.state.toasts == [.error(message: "Could not unblock sender")])
    }

    // MARK: - `Add to contacts` action

    @Test
    func testOnTapAddToContacts_ItShowsComingSoon() async {
        await sut.handle(action: .onTap(.addToContacts))

        #expect(dismissSpy.callsCount == 0)
        #expect(toastStateStore.state.toasts == [.comingSoon])
        #expect(blockSpy.calls == [])
        #expect(sut.state.emailToBlock == nil)
    }

    // MARK: - `New message` action

    @Test
    func testOnTapNewMessage_WhenSucceeds_ItPresentsDraftWithGivenContact() async {
        await sut.handle(action: .onTap(.newMessage))

        #expect(dismissSpy.callsCount == 1)
        #expect(draftPresenterSpy.openDraftCalls.count == 1)
        #expect(draftPresenterSpy.openDraftCalls == [.init(name: displayName, email: email)])
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func testOnTapNewMessage_WhenFails_ItShowsErrorToast() async {
        let stubbedError: ProtonError = .network

        draftPresenterSpy.stubbedOpenDraftError = stubbedError

        await sut.handle(action: .onTap(.newMessage))

        #expect(dismissSpy.callsCount == 1)
        #expect(draftPresenterSpy.openDraftCalls.count == 0)
        #expect(toastStateStore.state.toasts == [.error(message: stubbedError.localizedDescription)])
    }

    // MARK: - `Call` action

    @Test
    func testOnTapCall_WhenPhoneNumberIsAvailable_ItOpensURLWithTelPrefix() async {
        let phone = "+41771234567"
        let sut = makeSUT(phoneNumber: phone)

        await sut.handle(action: .onTap(.call))

        #expect(dismissSpy.callsCount == 0)
        #expect(urlOpener.callAsFunctionInvokedWithURL.map(\.absoluteString) == ["tel:\(phone)"])
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    // MARK: - `Copy address` action

    @Test
    func testOnTapCopyAddress_ItCopiesEmailAndShowsInformationToast() async {
        await sut.handle(action: .onTap(.copyAddress))

        #expect(pasteboard.string == email)
        #expect(toastStateStore.state.toasts == [.information(message: "Copied email address to clipboard")])
    }

    // MARK: - `Copy name` action

    @Test
    func testOnTapCopyName_ItCopiesNameAndShowsInformationToast() async {
        await sut.handle(action: .onTap(.copyName))

        #expect(pasteboard.string == displayName)
        #expect(toastStateStore.state.toasts == [.information(message: "Copied name to clipboard")])
    }

    // MARK: - Private

    private func makeSUT(phoneNumber: String? = nil) -> MessageAddressActionViewStateStore {
        messageBannersNotifier.refreshBanners
            .sink { [unowned self] in self.refreshBannersCount += 1 }
            .store(in: &cancellables)

        return .init(
            messageID: .init(value: 1_000),
            avatar: avatar,
            name: displayName,
            email: email,
            phoneNumber: phoneNumber,
            mailbox: .dummy,
            session: .dummy,
            toastStateStore: toastStateStore,
            pasteboard: pasteboard,
            openURL: urlOpener,
            wrapper: .init(
                block: { [unowned self] session, address in
                    await self.blockSpy.result(for: address)
                },
                isSenderBlocked: { [unowned self] mailbox, messageID in
                    await self.messageAddressSpy.isSenderBlocked(mailbox: mailbox, messageID: messageID)
                }
            ),
            senderUnblocker: .init(
                mailbox: .dummy,
                wrapper: .init(
                    messageBody: { _, _ in .ok(.init(noPointer: .init())) },
                    markMessageHam: { _, _ in .ok },
                    unblockSender: { _, emailAddress in
                        await self.unblockSpy.result(for: emailAddress)
                    }
                )
            ),
            draftPresenter: draftPresenterSpy,
            dismiss: dismissSpy,
            messageBannersNotifier: messageBannersNotifier
        )
    }
}

private final class BlockUnblockAddressSpy: @unchecked Sendable {
    private(set) var calls: [String] = []
    var stubbed: [String: VoidActionResult] = [:]

    func result(for email: String) async -> VoidActionResult {
        calls.append(email)
        return stubbed[email] ?? .ok
    }
}

private final class RustMessageAddressWrapperSpy: @unchecked Sendable {
    var stubbedIsSenderBlocked: BlockedSender = .no
    private(set) var isSenderBlockedCalls: [(mailbox: Mailbox, messageID: Id)] = []

    func isSenderBlocked(mailbox: Mailbox, messageID: Id) async -> BlockedSender {
        isSenderBlockedCalls.append((mailbox, messageID))
        return stubbedIsSenderBlocked
    }
}
