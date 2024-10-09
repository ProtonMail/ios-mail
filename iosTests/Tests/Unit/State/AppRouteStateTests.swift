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

import Combine
@testable import ProtonMail
import XCTest

final class AppRouteStateTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    @MainActor
    func testOnSelectedMailboxChange_whenRouteIsNotUpdated_itDoesNotEmitAnySelectedMailbox() {
        let initialRoute: Route = .mailbox(selectedMailbox: .inbox)
        let sut = AppRouteState(route: initialRoute)

        var selectedMailboxChange: SelectedMailbox?

        sut.onSelectedMailboxChange
            .sink { selectedMailbox in
                selectedMailboxChange = selectedMailbox
            }
            .store(in: &cancellables)

        // Runs after the sink closure because the `onSelectedMailboxChange` publisher emits synchronously in this case.
        XCTAssertNil(selectedMailboxChange)
    }

    @MainActor
    func testOnSelectedMailboxChange_whenRouteIsUpdated_itEmitNewSelectedMailbox() {
        let initialRoute: Route = .mailbox(selectedMailbox: .inbox)
        let newSelectedMailbox: SelectedMailbox = .systemFolder(labelId: .init(value: 1), systemFolder: .inbox)
        let updatedRoute: Route = .mailbox(selectedMailbox: newSelectedMailbox)
        let sut = AppRouteState(route: initialRoute)

        var selectedMailboxChange: SelectedMailbox?

        sut.onSelectedMailboxChange
            .sink { selectdMailbox in
                selectedMailboxChange = selectdMailbox
            }
            .store(in: &cancellables)
        sut.updateRoute(to: updatedRoute)

        XCTAssertEqual(selectedMailboxChange, newSelectedMailbox)
    }
}
