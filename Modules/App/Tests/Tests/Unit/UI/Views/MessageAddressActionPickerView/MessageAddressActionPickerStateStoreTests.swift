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
import XCTest

final class MessageAddressActionPickerStateStoreTests: BaseTestCase {
    private var sut: MessageAddressActionPickerStateStore!
    private var toastStateStore: ToastStateStore!
    private var blockSpy: BlockAddressSpy!
    private let email = "camila.hall@gmail.com"

    override func setUp() {
        super.setUp()
        toastStateStore = .init(initialState: .initial)
        blockSpy = .init()
        sut = makeSUT()
    }

    override func tearDown() {
        sut = nil
        toastStateStore = nil
        blockSpy = nil
        super.tearDown()
    }

    @MainActor
    func testInitialState() {
        XCTAssertEqual(sut.state, .init(emailToBlock: nil))
    }

    @MainActor
    func testOnTapBlockContact_ItPresentsAlert() async {
        await sut.handle(action: .onTap(.blockContact))

        XCTAssertEqual(sut.state, .init(emailToBlock: email))
        XCTAssertEqual(blockSpy.calls, [])
        XCTAssertEqual(toastStateStore.state.toasts, [])
    }

    @MainActor
    func testOnBlockAlertAction_CancelActionTapped_itDismissesAlertAndDoesNotCallBlock() async {
        await sut.handle(action: .onTap(.blockContact))
        await sut.handle(action: .onBlockAlertAction(.cancel))

        XCTAssertEqual(sut.state, .init(emailToBlock: .none))
        XCTAssertEqual(blockSpy.calls, [])
        XCTAssertEqual(toastStateStore.state.toasts, [])
    }

    @MainActor
    func testOnBlockAlertAction_ConfirmActionTappedAndSucceeds_ItShowsInformationToast() async {
        blockSpy.stubbed[email] = .ok

        await sut.handle(action: .onTap(.blockContact))
        await sut.handle(action: .onBlockAlertAction(.confirm))

        XCTAssertEqual(sut.state, .init(emailToBlock: .none))
        XCTAssertEqual(blockSpy.calls, [email])
        XCTAssertEqual(toastStateStore.state.toasts, [.information(message: "Sender blocked")])
    }

    @MainActor
    func testOnBlockAlertAction_ConfirmActionTappedAndFailed_ItShowsErrorToast() async {
        blockSpy.stubbed[email] = .error(.other(.network))

        await sut.handle(action: .onTap(.blockContact))
        await sut.handle(action: .onBlockAlertAction(.confirm))

        XCTAssertNil(sut.state.emailToBlock)
        XCTAssertEqual(blockSpy.calls, [email])
        XCTAssertEqual(toastStateStore.state.toasts, [.error(message: "Could not block sender")])
    }

    @MainActor
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

            XCTAssertEqual(toastStateStore.state.toasts.last, .comingSoon)
            XCTAssertEqual(blockSpy.calls, [])
            XCTAssertNil(sut.state.emailToBlock)
        }
    }

    // MARK: - Private

    private func makeSUT() -> MessageAddressActionPickerStateStore {
        .init(
            session: .dummy,
            email: email,
            toastStateStore: toastStateStore,
            blockAddress: { [unowned self] session, address in
                return await self.blockSpy.result(for: address)
            }
        )
    }
}

private final class BlockAddressSpy {
    private(set) var calls: [String] = []
    var stubbed: [String: VoidActionResult] = [:]

    func result(for email: String) async -> VoidActionResult {
        calls.append(email)
        return stubbed[email] ?? .ok
    }
}
