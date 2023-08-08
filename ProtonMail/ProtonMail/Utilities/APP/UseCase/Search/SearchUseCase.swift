// Copyright (c) 2023 Proton Technologies AG
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

typealias SearchUseCase = NewUseCase<[MessageEntity], MessageSearch.Params>

final class MessageSearch: SearchUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(
        params: Params,
        callback: @escaping NewUseCase<[MessageEntity], Params>.Callback
    ) {
        guard dependencies.isESEnable,
              isEncryptedSearchOn(),
              shouldDoContentSearch() else {
            dependencies.backendSearch.execute(
                params: .init(query: params.query, page: params.page),
                callback: callback
            )
            return
        }
        dependencies.encryptedSearch.execute(
            params: .init(query: params.query, page: params.page),
            callback: callback
        )
    }

    private func isEncryptedSearchOn() -> Bool {
        dependencies.esDefaultCache.isEncryptedSearchOn(
            of: dependencies.userID
        )
    }

    private func shouldDoContentSearch() -> Bool {
        let expectedState: [EncryptedSearchIndexState] = [.complete, .partial]
        return expectedState.contains(
            dependencies.esStateProvider.indexBuildingState(for: dependencies.userID)
        )
    }
}

extension MessageSearch {
    struct Dependencies {
        let isESEnable: Bool
        let esDefaultCache: EncryptedSearchUserCache
        let userID: UserID
        let backendSearch: BackendSearchUseCase
        let encryptedSearch: EncryptedSearchUseCase
        let esStateProvider: EncryptedSearchStateProvider
    }

    struct Params {
        let query: String
        let page: UInt
    }
}
