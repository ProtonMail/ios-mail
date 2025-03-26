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
import Testing

class PINLockStateStoreTests {

    var sut: PINLockStateStore!
    var output: [PINLockScreenOutput]!

    init() {
        output = []
        sut = PINLockStateStore(state: .init(pin: .empty), output: { self.output.append($0) })
    }

    deinit {
        output = nil
        sut = nil
    }

    @Test
    func usersSignsOut() async {
        await sut.handle(action: .signOutTapped)

        sut.state.alert = .logOutConfirmation()

        await sut.handle(action: .alertActionTapped(.signOut))

        #expect(output == [.logOut])
    }

    @Test
    func userResignSignOut() async {
        await sut.handle(action: .signOutTapped)

        sut.state.alert = .logOutConfirmation()

        await sut.handle(action: .alertActionTapped(.cancel))

        #expect(output == [])
    }

    @Test
    func userSubmitsEmptyPin() async {
        await sut.handle(action: .confirmTapped)
        #expect(output == [])
    }

    @Test
    func userSubmitsNonEmptyPin() async {
        await sut.handle(action: .keyboardTapped(.digit(1)))
        await sut.handle(action: .keyboardTapped(.digit(2)))
        await sut.handle(action: .keyboardTapped(.digit(3)))
        await sut.handle(action: .keyboardTapped(.digit(9)))

        #expect(sut.state.pin == "1239")

        await sut.handle(action: .keyboardTapped(.delete))

        #expect(sut.state.pin == "123")

        await sut.handle(action: .confirmTapped)

        #expect(sut.state.pin.isEmpty)
        #expect(output == [.pin("123")])
    }

    @Test
    func errorAppear() async {
        await sut.handle(action: .error("Error"))
        #expect(sut.state.error == "Error")

        await sut.handle(action: .keyboardTapped(.digit(1)))
        #expect(sut.state.error == nil)
    }

}
