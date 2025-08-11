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

@testable import InboxCoreUI
import Foundation
import InboxCore
import Testing

@MainActor
class PINLockStateStoreTests {
    lazy var sut: PINLockStateStore = PINLockStateStore(
        state: .init(isLogoutButtonVisible: true, pin: .empty),
        output: { [unowned self] in output.append($0) }
    )
    var output: [PINLockScreenOutput] = []

    @Test
    func userSignsOut_ItEmitsLogOutOutput() async throws {
        sut.handle(action: .signOutTapped)

        #expect(sut.state.alert == .logOutConfirmation(action: { _ in }))

        let signOutAction = try sut.state.alertAction(for: L10n.PINLock.signOut)
        await signOutAction.action()

        #expect(output == [.logOut])
    }

    @Test
    func userResignsSignOut_ItDoesNotEmitAnyOutput() async throws {
        sut.handle(action: .signOutTapped)

        #expect(sut.state.alert == .logOutConfirmation(action: { _ in }))

        let cancelAction = try sut.state.alertAction(for: CommonL10n.cancel)
        await cancelAction.action()

        #expect(output == [])
    }

    @Test
    func userSubmitsEmptyPIN_ItDoesNotEmitAnyOutput() async {
        sut.handle(action: .confirmTapped)
        #expect(output == [])
    }

    @Test
    func userSubmitsValidPIN_ItEmitsPINInOutput() {
        sut.handle(action: .pinEntered(.init(digits: [1, 2, 3, 4, 5])))
        sut.handle(action: .confirmTapped)

        #expect(output == [.pin(.init(digits: [1, 2, 3, 4, 5]))])
    }

    @Test
    func remainingAttemtsErrorIsPresented_WhenPINIsEntered_ItStillShowsError() {
        sut.handle(action: .error(.attemptsRemaining(3)))
        sut.handle(action: .pinEntered(.init(digits: [1, 2, 3, 4, 5])))

        #expect(sut.state.error == .attemptsRemaining(3))
    }

    @Test
    func customErrorIsPresented_WhenPINIsEntered_ItHidesError() {
        sut.handle(action: .error(.custom("Error")))
        sut.handle(action: .pinEntered(.init(digits: [1, 2, 3, 4, 5])))

        #expect(sut.state.error == nil)
    }

    @Test
    func tooFrequentAttemptsErrorIsThrown_ItDoesNotCleanPINField() {
        sut.handle(action: .pinEntered(.init(digits: [1, 2])))
        sut.handle(action: .error(.tooFrequentAttempts))

        #expect(sut.state.error == .tooFrequentAttempts)
        #expect(sut.state.pin == .init(digits: [1, 2]))
    }

}

private extension PINLockState {

    func alertAction(for string: LocalizedStringResource) throws -> AlertAction {
        try #require(alert?.actions.findFirst(for: string, by: \.title))
    }

}
