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

// sourcery: mock
protocol EncryptedSearchServiceProtocol {
    func setBuildSearchIndexDelegate(for userID: UserID, delegate: BuildSearchIndexDelegate?)
    func indexBuildingState(for userID: UserID) -> EncryptedSearchIndexState
    func indexBuildingEstimatedProgress(for userID: UserID) -> BuildSearchIndexEstimatedProgress?
    func isIndexBuildingInProgress(for userID: UserID) -> Bool
    func isIndexBuildingComplete(for userID: UserID) -> Bool
    func startBuildingIndex(for userID: UserID)
    func pauseBuildingIndex(for userID: UserID)
    func resumeBuildingIndex(for userID: UserID)
    func stopBuildingIndex(for userID: UserID)
    func didChangeDownloadViaMobileData(for userID: UserID)
}

final class EncryptedSearchService: EncryptedSearchServiceProtocol {
    static let shared = EncryptedSearchService()

    private var buildSearchIndexes: [UserID: BuildSearchIndex] = [:]
    private let serial = DispatchQueue(label: "me.proton.EncryptedSearchService")
    private let dependencies: Dependencies

    init(dependencies: Dependencies = Dependencies()) {
        self.dependencies = dependencies
    }

    func setBuildSearchIndexDelegate(for userID: UserID, delegate: BuildSearchIndexDelegate?) {
        createBuildSearchIndexIfNeeded(for: userID)
        buildSearchIndex(for: userID)?.update(delegate: delegate)
    }

    func indexBuildingState(for userID: UserID) -> EncryptedSearchIndexState {
        buildSearchIndex(for: userID)?.currentState ?? .undetermined
    }

    func indexBuildingEstimatedProgress(for userID: UserID) -> BuildSearchIndexEstimatedProgress? {
        buildSearchIndex(for: userID)?.estimatedProgress
    }

    func isIndexBuildingInProgress(for userID: UserID) -> Bool {
        buildSearchIndex(for: userID)?.currentState?.isIndexing ?? false
    }

    func isIndexBuildingComplete(for userID: UserID) -> Bool {
        buildSearchIndex(for: userID)?.currentState == .complete
    }

    func startBuildingIndex(for userID: UserID) {
        buildSearchIndex(for: userID)?.start()
    }

    func pauseBuildingIndex(for userID: UserID) {
        buildSearchIndex(for: userID)?.pause()
    }

    func resumeBuildingIndex(for userID: UserID) {
        // TODO: missing BuildSearchIndex API to resume
    }

    func stopBuildingIndex(for userID: UserID) {
        // TODO: missing BuildSearchIndex API to stop and set `disabled`
    }

    func didChangeDownloadViaMobileData(for userID: UserID) {
        buildSearchIndex(for: userID)?.didChangeDownloadViaMobileDataConfiguration()
    }

    func userAuthenticated(_ user: UserManager) {
        createBuildSearchIndexIfNeeded(for: user)
    }

    func userWillSignOut(userID: UserID) {
        guard let build = buildSearchIndex(for: userID) else { return }
        build.disable()
        serial.sync {
            buildSearchIndexes[userID] = nil
        }
    }
}

extension EncryptedSearchService {

    private func createBuildSearchIndexIfNeeded(for userID: UserID) {
        guard let user = dependencies.usersManager.users.first(where: { $0.userID == userID }) else {
            return
        }
        createBuildSearchIndexIfNeeded(for: user)
    }

    private func createBuildSearchIndexIfNeeded(for user: UserManager) {
        var buildIndex: BuildSearchIndex?
        serial.sync {
            buildIndex = buildSearchIndexes[user.userID]
        }
        guard buildIndex == nil else { return }
        let searchIndexDB = SearchIndexDB(userID: user.userID)
        let build = BuildSearchIndex(
            dependencies: .init(
                apiService: user.apiService,
                connectionStatusProvider: dependencies.connectionStatusProvider,
                countMessagesForLabel: CountMessagesForLabel(dependencies: .init(apiService: user.apiService)),
                esDeviceCache: dependencies.esDefaultCache,
                esUserCache: dependencies.esDefaultCache,
                messageDataService: user.messageService,
                searchIndexDB: searchIndexDB
            ),
            params: .init(userID: user.userID)
        )
        serial.sync {
            buildSearchIndexes[user.userID] = build
        }
    }

    private func buildSearchIndex(for userID: UserID, caller: String = #function) -> BuildSearchIndex? {
        var build: BuildSearchIndex?
        serial.sync {
            build = buildSearchIndexes[userID]
        }
        guard let build = build else {
            let message = "\(caller): BuildSearchIndex not found for userID \(userID)"
            log(message: message, isError: true)
            assertionFailure(message)
            return nil
        }
        return build
    }
}

extension EncryptedSearchService {

    struct Dependencies {
        let esDefaultCache = EncryptedSearchUserDefaultCache()
        let connectionStatusProvider = InternetConnectionStatusProvider()
        let usersManager = sharedServices.get(by: UsersManager.self)
    }
}

extension EncryptedSearchService {

    private func log(message: String, isError: Bool) {
        SystemLogger.log(message: message, category: .encryptedSearch, isError: isError)
    }
}
