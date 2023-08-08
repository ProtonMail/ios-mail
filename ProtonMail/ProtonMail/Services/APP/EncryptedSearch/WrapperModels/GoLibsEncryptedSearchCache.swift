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
import GoLibs

 class GoLibsEncryptedSearchCache: EncryptedsearchCache {
    func cacheIndexIntoDB(
        dbParams: GoLibsEncryptedSearchDBParams?,
        cipher: GoLibsEncryptedSearchAESGCMCipher?,
        batchSize: Int
    ) throws {
        try super.cacheIndex(dbParams, cipher: cipher, batchSize: batchSize)
    }

    @objc
    func updateCache(messageToInsert: GoLibsEncryptedSearchMessage?) {
        super.update(messageToInsert)
    }

    @objc
    override func search(
        _ state: EncryptedsearchSearchState?,
        searcher: EncryptedsearchSearcherProtocol?,
        batchSize: Int
    ) throws -> GoLibsEncryptedSearchResultList {
        let searchResult = try super.search(state, searcher: searcher, batchSize: batchSize)
        if let newResult = GoLibsEncryptedSearchResultList(resultList: searchResult) {
            return newResult
        } else {
            throw EncryptedSearchGolangCacheServiceError.failToCreateSearchResultList
        }
    }

    enum EncryptedSearchGolangCacheServiceError: Error {
        case failToCreateSearchResultList
    }
}
