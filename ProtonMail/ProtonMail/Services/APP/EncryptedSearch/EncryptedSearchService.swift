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

final class EncryptedSearchService {
    static let shared = EncryptedSearchService()
    private var buildSearchIndex: [UserID: BuildSearchIndex] = [:]
    private let esDefaultCache = EncryptedSearchUserDefaultCache()
    private let connectionStatusProvider = InternetConnectionStatusProvider()

    func buildIndexIfESEnabled() {
        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        pauseBuildSearchIndex()
        guard let primaryUser = usersManager.firstUser,
              esDefaultCache.isEncryptedSearchOn(of: primaryUser.userID) else { return }
        let build = buildSearchIndex(for: primaryUser)
        build?.start()
    }

    func userDidSwitch() {
        buildIndexIfESEnabled()
    }

    func pauseBuildSearchIndex() {
        buildSearchIndex.values.forEach { $0.pause() }
    }

    func userSignOut(userID: UserID) {
        guard let build = buildSearchIndex[userID] else { return }
        build.signOut()
        buildSearchIndex[userID] = nil
    }

    func updateBuildSearchIndexDelegate(for user: UserManager, delegate: BuildSearchIndexDelegate) {
        guard let build = buildSearchIndex(for: user) else { return }
        build.update(delegate: delegate)
    }
}

extension EncryptedSearchService {
    private func buildSearchIndex(for user: UserManager) -> BuildSearchIndex? {
        if let build = buildSearchIndex[user.userID] {
            return build
        }
        let searchIndexDB = SearchIndexDB(userID: user.userID)
        let build = BuildSearchIndex(
            dependencies: .init(
                apiService: user.apiService,
                connectionStatusProvider: connectionStatusProvider,
                countMessagesForLabel: CountMessagesForLabel(dependencies: .init(apiService: user.apiService)),
                esDeviceCache: esDefaultCache,
                esUserCache: esDefaultCache,
                messageDataService: user.messageService,
                searchIndexDB: searchIndexDB
            ),
            params: .init(userID: user.userID)
        )
        // TODO workaround, since build index doesn't support resume function
        // Delete searchIndexDB every time to make sure app won't crash
        try? searchIndexDB.deleteSearchIndex()
        buildSearchIndex[user.userID] = build
        return build
    }
}
