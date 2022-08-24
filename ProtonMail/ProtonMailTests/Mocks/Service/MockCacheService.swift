// Copyright (c) 2022 Proton AG
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

import CoreData
import ProtonCore_TestingToolkit
@testable import ProtonMail

class MockCacheService: CacheServiceProtocol {
    private(set) var wasParseMessagesResponseCalled: Bool = false

    var returnsError: Bool = false

    func parseMessagesResponse(labelID: LabelID,
                               isUnread: Bool,
                               response: [String: Any],
                               completion: ((Error?) -> Void)?) {
        wasParseMessagesResponseCalled = true
        returnsError
            ? completion?(NSError.badParameter(nil))
            : completion?(nil)
    }

    @FuncStub(MockCacheService.addNewLabel) var callAddNewLabel
    func addNewLabel(serverResponse: [String: Any], objectID: String?, completion: (() -> Void)?) {
        callAddNewLabel(serverResponse, objectID, completion)
    }

    @FuncStub(MockCacheService.updateLabel) var callUpdateLabel
    func updateLabel(serverReponse: [String: Any], completion: (() -> Void)?) {
        callUpdateLabel(serverReponse, completion)
    }

    @FuncStub(MockCacheService.deleteLabels) var callDeleteLabels
    func deleteLabels(objectIDs: [NSManagedObjectID], completion: (() -> Void)?) {
        callDeleteLabels(objectIDs, completion)
    }
}
