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

import Foundation

/**
 Bolean representation for Sendable objects that need mutation.

 A common example would be a UI cell model that needs to be selected.

 Notice that @unchecked Sendable is ensured by the @MainActor annotation in the setter function
 */
@Observable
final class SendableBool: @unchecked Sendable {
    private(set) var value: Bool

    init(_ value: Bool) {
        self.value = value
    }

    @MainActor
    func set(_ value: Bool) {
        self.value = value
    }
}
