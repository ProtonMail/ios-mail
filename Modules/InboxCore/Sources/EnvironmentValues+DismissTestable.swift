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

import SwiftUI

extension EnvironmentValues {

    public var dismissTestable: Dismissable {
        get { isTestingTarget ? self[DismissKey.self] : dismiss }
        set { self[DismissKey.self] = newValue }
    }

    // MARK: - Private

    private var isTestingTarget: Bool {
        NSClassFromString("XCTest") != nil
    }

}

public protocol Dismissable {
    func callAsFunction()
}

extension DismissAction: Dismissable {}

private struct DismissKey: EnvironmentKey {
    struct DefaultDismisser: Dismissable {
        // MARK: - Dismissable

        func callAsFunction() {
            let message = """
                          This should not be used at runtime. For testing purposes, please inject
                          a test double into the SwiftUI view using the `environment(_: _:)` function, specifying
                          the keyPath defined in the scope of `EnvironmentValues`, for example:

                          ```
                          let sut: View = ...
                          sut.environment(\\.dismissable, DismissSpy())
                          ```
                          """
            fatalError(message)
        }
    }

    static let defaultValue: Dismissable = DefaultDismisser()
}
