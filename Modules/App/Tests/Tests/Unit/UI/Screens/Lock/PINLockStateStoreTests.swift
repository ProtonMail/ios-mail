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
import InboxCore
import InboxCoreUI
import Testing

@MainActor
class PINLockStateStoreTests {
    lazy var sut: PINLockStateStore = PINLockStateStore(
        state: .init(hideLogoutButton: false, pin: []),
        output: { [unowned self] in output.append($0) }
    )
    var output: [PINLockScreenOutput] = []

    @Test
    func usersSignsOut() async throws {
        await sut.handle(action: .signOutTapped)

        #expect(sut.state.alert == .logOutConfirmation(action: { _ in }))

        let signOutAction = try sut.state.alertAction(for: L10n.PINLock.signOutConfirmationButton)
        await signOutAction.action()

        #expect(output == [.logOut])
    }

    @Test
    func userResignSignOut() async throws {
        await sut.handle(action: .signOutTapped)

        #expect(sut.state.alert == .logOutConfirmation(action: { _ in }))

        let cancelAction = try sut.state.alertAction(for: CommonL10n.cancel)
        await cancelAction.action()

        #expect(output == [])
    }

    @Test
    func userSubmitsEmptyPin() async {
        await sut.handle(action: .confirmTapped)
        #expect(output == [])
    }

}

private extension PINLockState {

    func alertAction(for string: LocalizedStringResource) throws -> AlertAction {
        try #require(alert?.actions.findFirst(for: string, by: \.title))
    }

}
