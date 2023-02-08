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
import ProtonCore_TestingToolkit
@testable import ProtonMail
import GoLibs

class MockEncryptedSearchGolangCache: EncryptedSearchGolangCacheProtocol {
    @FuncStub(MockEncryptedSearchGolangCache.deleteAll) var callDeleteAll
    func deleteAll() {
        callDeleteAll()
    }

    @ThrowingFuncStub(MockEncryptedSearchGolangCache.cacheIndexIntoDB) var callCacheIndex
    func cacheIndexIntoDB(
        dbParams: EncryptedSearchDBParams?,
        cipher: EncryptedSearchAESGCMCipher?,
        batchSize: Int
    ) throws {
        try callCacheIndex(dbParams, cipher, batchSize)
    }

    @FuncStub(MockEncryptedSearchGolangCache.deleteMessage(_:), initialReturn: false) var callDeleteMessage
    func deleteMessage(_ id: String?) -> Bool {
        return callDeleteMessage(id)
    }

    @FuncStub(MockEncryptedSearchGolangCache.isBuilt, initialReturn: false) var callIsBuilt
    func isBuilt() -> Bool {
        return callIsBuilt()
    }

    @FuncStub(MockEncryptedSearchGolangCache.updateCache) var callUpdateCache
    func updateCache(messageToInsert: ProtonMail.EncryptedSearchMessage?) {
        callUpdateCache(messageToInsert)
    }
}
