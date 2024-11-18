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

@testable import InboxContacts
import proton_app_uniffi
import SwiftUI
import ViewInspector
import XCTest

final class RouteTests: XCTestCase {
    func testView_ForContactDetailsRoute_ItReturnsContactDetailsScreen() async throws {
        let id = Id(value: 1)
        let view = try await makeView(for: .contactDetails(id: id))

        let inspectableScreen = try view.find(ContactDetailsScreen.self)
        let screen = try inspectableScreen.actualView()

        XCTAssertEqual(screen.id, id)
    }

    func testView_ForContactGroupDetailsRoute_ItReturnsContactDetailsScreen() async throws {
        let id = Id(value: 2)
        let view = try await makeView(for: .contactGroupDetails(id: id))

        let inspectableScreen = try view.find(ContactGroupDetailsScreen.self)
        let screen = try inspectableScreen.actualView()

        XCTAssertEqual(screen.id, id)
    }

    // MARK: - Private

    @MainActor
    private func makeView(for route: Route) throws -> InspectableView<ViewType.ClassifiedView> {
        try route.view().inspect()
    }
}
