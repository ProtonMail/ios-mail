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
import Testing

@MainActor
class PINLockStateStoreTests {
    var sut: PINLockStateStore!
    var output: [PINLockScreenOutput]!

    init() {
        output = []
        sut = PINLockStateStore(
            state: .init(disableLogoutButton: false, pin: .empty),
            output: { self.output.append($0) }
        )
    }

    deinit {
        output = nil
        sut = nil
    }
    
    @Test
    func usersSignsOut() throws {
        sut.handle(action: .signOutTapped)
        
        #expect(sut.state.alert == .logOutConfirmation(action: { _ in }))
        
        let signOutAction = try sut.state.alertAction(for: L10n.PINLock.signOutConfirmationButton)
        signOutAction.action()

        #expect(output == [.logOut])
    }

    @Test
    func userResignSignOut() throws {
        sut.handle(action: .signOutTapped)

        #expect(sut.state.alert ==  .logOutConfirmation(action: { _ in }))
        
        let cancelAction = try sut.state.alertAction(for: L10n.Common.cancel)
        cancelAction.action()

        #expect(output == [])
    }

    @Test
    func userSubmitsEmptyPin() {
        sut.handle(action: .confirmTapped)
        #expect(output == [])
    }

    @Test
    func userSubmitsNonEmptyPin() {
        sut.handle(action: .keyboardTapped(.digit(1)))
        sut.handle(action: .keyboardTapped(.digit(2)))
        sut.handle(action: .keyboardTapped(.digit(3)))
        sut.handle(action: .keyboardTapped(.digit(9)))

        #expect(sut.state.pin == "1239")

        sut.handle(action: .keyboardTapped(.delete))

        #expect(sut.state.pin == "123")

        sut.handle(action: .confirmTapped)

        #expect(sut.state.pin.isEmpty)
        #expect(output == [.pin("123")])
    }

    @Test
    func errorAppear() {
        sut.handle(action: .error("Error"))
        #expect(sut.state.error == "Error")

        sut.handle(action: .keyboardTapped(.digit(1)))
        #expect(sut.state.error == nil)
    }
}

private extension PINLockState {
    
    func alertAction(for string: LocalizedStringResource) throws -> AlertAction {
        try #require(alert?.actions.findFirst(for: string, by: \.title))
    }
    
}
