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
import SwiftUI
import ViewInspector
import XCTest

final class RouteTests: XCTestCase {
    func testView_ForContactDetailsRoute_ItReturnsContactDetailsScreen() async throws {
        let view = try await makeView(for: .contactDetails(id: .init(value: 1)))

        XCTAssertNoThrow(try view.find(ContactDetailsScreen.self))
    }

    func testView_ForContactGroupDetailsRoute_ItReturnsContactDetailsScreen() async throws {
        let view = try await makeView(for: .contactGroupDetails(id: .init(value: 2)))

        XCTAssertNoThrow(try view.find(ContactGroupDetailsScreen.self))
    }

    // MARK: - Private

    @MainActor
    private func makeView(for route: Route) throws -> InspectableView<ViewType.ClassifiedView> {
        try route.view().inspect()
    }
}
