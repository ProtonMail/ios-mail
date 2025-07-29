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

@MainActor
struct SnoozeStoreTests {

    let sut = SnoozeStore(state: .initial(screen: .main))

    @Test
    func testCustomButtonTapped_transitionsToCustomView() async {
        await sut.handle(action: .customButtonTapped)

        #expect(sut.state.screen == .custom)
    }

    @Test
    func customSnoozeCancelTapped_transitionsToMainView() async {
        sut.state = sut.state.copy(\.screen, to: .custom)

        await sut.handle(action: .customSnoozeCancelTapped)

        #expect(sut.state.screen == .main)
    }

}
