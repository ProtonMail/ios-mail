// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
@testable import ProtonMail

final class MockFetchMessages: FetchMessagesUseCase {
    let uuid: UUID = UUID()
    private(set) var executeWasCalled: Bool = false
    var result: Result<Void, Error> = .success(Void())

    func execute(endTime: Int, isUnread: Bool, hasToBeQueued: Bool, callback: @escaping UseCaseResult<Void>, onMessagesRequestSuccess: (() -> Void)?) {
        executeWasCalled = true

        if result.nsError == nil {
            onMessagesRequestSuccess?()
        }

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.3) {
            callback(self.result)
        }
    }
}
