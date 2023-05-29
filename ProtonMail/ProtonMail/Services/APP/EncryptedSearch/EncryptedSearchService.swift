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

import ProtonCore_Crypto

// sourcery: mock
protocol EncryptedSearchServiceProtocol {
    func setBuildSearchIndexDelegate(for userID: UserID, delegate: BuildSearchIndexDelegate?)
    func indexBuildingState(for userID: UserID) -> EncryptedSearchIndexState
    func indexBuildingEstimatedProgress(for userID: UserID) -> BuildSearchIndexEstimatedProgress?
    func isIndexBuildingComplete(for userID: UserID) -> Bool
    func startBuildingIndex(for userID: UserID)
    func pauseBuildingIndex(for userID: UserID)
    func resumeBuildingIndex(for userID: UserID)
    func stopBuildingIndex(for userID: UserID)
    func didChangeDownloadViaMobileData(for userID: UserID)
    func indexSize(for userID: UserID) -> Measurement<UnitInformationStorage>?
    func oldesMessageTime(for userID: UserID) -> Int?
    func search(
        userID: UserID,
        query: String,
        page: UInt,
        completion: @escaping (Result<EncryptedSearchService.SearchResult, Error>) -> Void
    )
}

final class EncryptedSearchService: EncryptedSearchServiceProtocol {
    static let shared = EncryptedSearchService()

    private var buildSearchIndexes: [UserID: BuildSearchIndex] = [:]
    private let serial = DispatchQueue(label: "me.proton.EncryptedSearchService")
    private var searchCacheServiceMap: [UserID: EncryptedSearchCacheService] = [:]
    private let dependencies: Dependencies

    init(dependencies: Dependencies = Dependencies()) {
        self.dependencies = dependencies
        observeMemoryWarningNotification()
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
        buildSearchIndex(for: userID)?.resume()
    }

    func stopBuildingIndex(for userID: UserID) {
        buildSearchIndex(for: userID)?.disable()
    }

    func didChangeDownloadViaMobileData(for userID: UserID) {
        buildSearchIndex(for: userID)?.didChangeDownloadViaMobileDataConfiguration()
    }

    func indexSize(for userID: UserID) -> Measurement<UnitInformationStorage>? {
        buildSearchIndex(for: userID)?.indexSize
    }

    func oldesMessageTime(for userID: UserID) -> Int? {
        buildSearchIndex(for: userID)?.oldestMessageTime
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

// MARK: - Search related functions
extension EncryptedSearchService {
    struct SearchResult {
        let resultFromCache: [GoLibsEncryptedSearchResultList]
        let resultFromIndex: [GoLibsEncryptedSearchResultList]
    }

    func search(
        userID: UserID,
        query: String,
        page: UInt,
        completion: @escaping (Result<SearchResult, Error>) -> Void
    ) {
        guard !query.isEmpty,
              dependencies.esDefaultCache.isEncryptedSearchOn(of: userID) else {
            completion(.failure(EncryptedSearchServiceError.notEnable))
            return
        }
        let processedQuery = SearchQueryHelper().sanitizeAndExtractKeywords(query: query)
        guard let indexCipher = EncryptedSearchHelper.getEncryptedCipher(userID: userID),
              let searcher = EncryptedSearchHelper.createSearcher(processedQuery: processedQuery) else {
            return
        }
        guard let searchState = GoLibsEncryptedSearchSearchState(),
              let buildIndex = buildSearchIndexes[userID],
              let dbParams = buildIndex.getDBParams() else {
            completion(.failure(EncryptedSearchServiceError.noIndexFound))
            return
        }

        searchInCache(
            searcher: searcher,
            page: page,
            userID: userID,
            searchState: searchState,
            cipher: indexCipher,
            dbParameters: dbParams,
            batchSize: Constant.searchResultPageSize
        ) { result in
            switch result {
            case .failure(let error):
                SystemLogger.logTemporarily(message: "Cache Search error: \(error)", category: .encryptedSearch, isError: true)
            case .success(let searchResultFromCache):
                let cachedSearchResultCount = searchResultFromCache.reduce(0) { partialResult, resultList in
                    return partialResult + resultList.length()
                }
                self.performSearchInIndexIfNeeded(
                    cachedSearchResultCount,
                    searchResultFromCache,
                    numberOfMessagesInSearchIndex: buildIndex.numberOfEntriesInSearchIndex(),
                    searcher: searcher,
                    cipher: indexCipher,
                    userID: userID,
                    page: page,
                    searchState: searchState,
                    dbParameters: dbParams,
                    completion: completion
                )
            }
        }
    }

    // swiftlint:disable function_parameter_count
    private func performSearchInIndexIfNeeded(
        _ cachedSearchResultCount: Int,
        _ searchResultFromCache: [GoLibsEncryptedSearchResultList],
        numberOfMessagesInSearchIndex: Int,
        searcher: GoLibsEncryptedSearchSimpleSearcher,
        cipher: GoLibsEncryptedSearchAESGCMCipher,
        userID: UserID,
        page: UInt,
        searchState: GoLibsEncryptedSearchSearchState,
        dbParameters: GoLibsEncryptedSearchDBParams,
        completion: @escaping (Result<SearchResult, Error>) -> Void
    ) {
        // Perform search in index if needed
        if searchState.isComplete == false && cachedSearchResultCount <= Constant.searchResultPageSize {
            self.searchInIndex(
                searcher: searcher,
                cipher: cipher,
                userID: userID,
                page: page,
                numberOfMessagesInSearchIndex: numberOfMessagesInSearchIndex,
                searchState: searchState,
                dbParameters: dbParameters
            ) { result in
                switch result {
                case .success(let searchResultFromIndex):
                    completion(.success(.init(
                        resultFromCache: searchResultFromCache,
                        resultFromIndex: searchResultFromIndex
                    )))
                case .failure(let error):
                    SystemLogger.logTemporarily(message: "Cache Search error: \(error)", category: .encryptedSearch, isError: true)
                    completion(.failure(error))
                }
            }
        } else {
            completion(.success(.init(
                resultFromCache: searchResultFromCache,
                resultFromIndex: []
            )))
        }
    }

    // swiftlint:disable function_parameter_count
    private func searchInIndex(
        searcher: GoLibsEncryptedSearchSimpleSearcher,
        cipher: GoLibsEncryptedSearchAESGCMCipher,
        userID: UserID,
        page: UInt,
        numberOfMessagesInSearchIndex: Int,
        searchState: GoLibsEncryptedSearchSearchState,
        dbParameters: GoLibsEncryptedSearchDBParams,
        completion: @escaping (Result<[GoLibsEncryptedSearchResultList], Error>) -> Void
    ) {
        guard let index = GoLibsEncryptedSearchIndex(dbParameters) else {
            completion(.failure(EncryptedSearchServiceError.indexFailedToCreate))
            return
        }
        do {
            try index.openDBConnection()
        } catch {
            completion(.failure(error))
            return
        }

        var searchResults: [GoLibsEncryptedSearchResultList] = []
        var resultCount = 0
        var batchCount = 0
        while searchState.isComplete == false && resultCount < Constant.searchResultPageSize {
            // fix infinity loop caused by errors - prevent app from crashing
            if batchCount > numberOfMessagesInSearchIndex {
                searchState.isComplete = true
                break
            }

            // Percentage of heap that can be used to load messages from the index
            let searchBatchHeapPercent: Double = 0.1
            // An estimation of how many bytes take a search message in memory
            let searchMsgSize: Double = 14_000
            let batchSize = Int(DeviceCapacity.Memory().availableMemory * searchBatchHeapPercent / searchMsgSize)

            do {
                let result = try index.searchNewBatch(
                    fromDB: searcher,
                    cipher: cipher,
                    state: searchState,
                    batchSize: batchSize
                )
                resultCount += result.length()
                if result.length() > 0 {
                    searchResults.append(result)
                }
            } catch {
                completion(.failure(error))
                return
            }
            batchCount += 1
        }

        do {
            try index.closeDBConnection()
        } catch {
            assertionFailure("Index DB close failed: \(error)")
        }

        completion(.success(searchResults))
    }

    // swiftlint:disable function_parameter_count
    private func searchInCache(
        searcher: GoLibsEncryptedSearchSimpleSearcher,
        page: UInt,
        userID: UserID,
        searchState: GoLibsEncryptedSearchSearchState,
        cipher: GoLibsEncryptedSearchAESGCMCipher,
        dbParameters: GoLibsEncryptedSearchDBParams,
        batchSize: Int,
        completion: @escaping (Result<[GoLibsEncryptedSearchResultList], Error>) -> Void
    ) {
        guard let cache = buildCacheIfNeeded(userID: userID,
                                             cipher: cipher,
                                             dbParameters: dbParameters),
            cache.getLength() > 0 else {
            completion(.success([]))
            return
        }

        var found = 0
        var batchCount = 0
        var searchResults: [GoLibsEncryptedSearchResultList] = []

        while searchState.cachedSearchDone == false && found < Constant.searchResultPageSize {
            do {
                let result = try cache.search(
                    searchState,
                    searcher: searcher,
                    batchSize: batchSize
                )
                found += result.length()
                if result.length() > 0 {
                    searchResults.append(result)
                }
            } catch {
                completion(.failure(error))
                return
            }
            batchCount += 1
        }

        SystemLogger.logTemporarily(message: "Cache search found: \(found) results.\nBatch count: \(batchCount)\nBatch size: \(batchSize)", category: .encryptedSearch)
        completion(.success(searchResults))
    }

    private func buildCacheIfNeeded(
        userID: UserID,
        cipher: GoLibsEncryptedSearchAESGCMCipher,
        dbParameters: GoLibsEncryptedSearchDBParams
    ) -> GoLibsEncryptedSearchCache? {
        if let cacheService = searchCacheServiceMap[userID], cacheService.isCacheBuilt() {
            return cacheService.cache
        } else {
            let cacheService = EncryptedSearchCacheService(userID: userID)
            searchCacheServiceMap[userID] = cacheService
            return cacheService?.buildCacheForUser(
                dbParams: dbParameters,
                cipher: cipher
            )
        }
    }

    private func observeMemoryWarningNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    @objc
    private func handleMemoryWarning() {
        for cacheService in searchCacheServiceMap {
            cacheService.value.deleteCache()
        }
        searchCacheServiceMap.removeAll()
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

    enum Constant {
        static let searchResultPageSize = 50
    }

    enum EncryptedSearchServiceError: Error {
        case noSearchResult
        case indexFailedToCreate
        case noIndexFound
        case notEnable
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
