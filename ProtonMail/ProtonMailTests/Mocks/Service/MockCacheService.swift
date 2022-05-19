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

@testable import ProtonMail

class MockCacheService: CacheServiceProtocol {
    private(set) var wasParseMessagesResponseCalled: Bool = false

    var returnsError: Bool = false

    func parseMessagesResponse(labelID: LabelID, isUnread: Bool, response: [String : Any], completion: ((Error?) -> Void)?) {
        wasParseMessagesResponseCalled = true
        returnsError
        ? completion?(NSError.badParameter(nil))
        : completion?(nil)
    }
}
