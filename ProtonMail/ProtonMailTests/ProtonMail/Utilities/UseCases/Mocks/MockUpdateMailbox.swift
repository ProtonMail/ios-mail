// Copyright (c) 2022 Proton Technologies AG
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
@testable import ProtonMail

final class MockUpdateMailbox: UpdateMailboxUseCase {
    var isFetching: Bool = false
    var isFirstFetch: Bool = false
    var error: Error?
    var isExecuted = false
    var source: UpdateMailboxSourceProtocol?


    func exec(showUnreadOnly: Bool,
              isCleanFetch: Bool,
              time: Int,
              errorHandler: @escaping (Error) -> Void,
              completion: @escaping () -> Void) {
        if let error = self.error {
            errorHandler(error)
        }
        self.isExecuted = true
        completion()
    }

    func setup(source: UpdateMailboxSourceProtocol) {
        self.source = source
    }
}
