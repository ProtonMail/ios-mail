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
import GoLibs
import ProtonCore_Services
import ProtonCore_Utilities

protocol BuildSearchIndexDelegate: AnyObject {
    func indexBuildingStateDidChange(state: EncryptedSearchIndexState)
    func indexBuildingProgressUpdate(progress: BuildSearchIndexEstimatedProgress)
}

final class BuildSearchIndex {
    private let dependencies: Dependencies
    private let params: Params
    private weak var delegate: BuildSearchIndexDelegate?
    private var loadingCheckTimer: Timer?
    private var timerFireTimes: Int = 0
    /// Time to start build search index
    private var startingTime: CFAbsoluteTime?
    private var totalMessagesCount: Int = 0
    private var interruptReason: InterruptReason = .none {
        didSet {
            guard oldValue != interruptReason else { return }
            if oldValue == .none {
                let numOfInterruptions = dependencies.esUserCache.numberOfInterruptions(of: params.userID)
                dependencies.esUserCache.setNumberOfInterruptions(of: params.userID, value: numOfInterruptions + 1)
            }
            interruptReasonHasUpdated()
        }
    }
    private var pageSize: Int = 150 {
        didSet {
            guard oldValue != pageSize else { return }
            log(message: "Page size is updated to \(pageSize)")
        }
    }
    private var indexingSpeed = OperationQueue.defaultMaxConcurrentOperationCount {
        didSet {
            guard oldValue != indexingSpeed else { return }
            log(message: "Indexing speed is updated to \(indexingSpeed)")
        }
    }
    /// Sleep 2 seconds between each API when memory resource tight
    private var addTimeOutWhenIndexingAsMemoryExceeds = false
    private let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .full    // spells out units
        formatter.includesTimeRemainingPhrase = true    // adds remaining in the end
        formatter.zeroFormattingBehavior = .dropAll // drops all units that are zero
        return formatter
    }()
    private let messageIndexingQueue: OperationQueue
    private var downloadPageQueue: OperationQueue
    private var indexingQueue = DispatchQueue(label: "ch.protonmail.protonmail.build.index")

    private(set) var currentState: EncryptedSearchIndexState?
    private(set) var estimatedProgress: Atomic<BuildSearchIndexEstimatedProgress?>
    private var savedMessagesCount: Int = 0
    private var downloadedMessagesCount: Int = 0
    private var preexistingIndexedMessagesCount: Int = 0
    private let observerID = UUID()
    private var connectionStatus: ConnectionStatus?
    private var isPaused = false

    init(
        dependencies: Dependencies,
        delegate: BuildSearchIndexDelegate? = nil,
        params: Params
    ) {
        self.dependencies = dependencies
        self.delegate = delegate
        self.params = params

        self.messageIndexingQueue = OperationQueue()
        self.messageIndexingQueue.name = "Message Indexing Queue"
        self.messageIndexingQueue.maxConcurrentOperationCount = ProcessInfo.processInfo.activeProcessorCount
        self.messageIndexingQueue.qualityOfService = .userInitiated

        self.downloadPageQueue = OperationQueue()
        self.downloadPageQueue.name = "Download Page Queue"
        self.downloadPageQueue.maxConcurrentOperationCount = 1 // Download 1 page at a time
        self.downloadPageQueue.qualityOfService = .userInitiated
        self.estimatedProgress = .init(nil)
    }

    var isBuildingIndexInProgress: Bool {
        guard let state = currentState else { return false }
        switch state {
        case .background, .creatingIndex, .downloadingNewMessage:
            return !isPaused
        default:
            return false
        }
    }

    var isEncryptedSearchEnabled: Bool {
        dependencies.esUserCache.isEncryptedSearchOn(of: params.userID)
    }

    var oldestMessageTime: Int? {
        dependencies.searchIndexDB.oldestMessageTime()
    }

    var indexSize: Measurement<UnitInformationStorage>? {
        dependencies.searchIndexDB.size
    }

    // MARK: - Basic operations
    func start() {
        indexingQueue.async { [weak self] in
            guard let self = self,
                  self.canBuildSearchIndex(),
                  !self.isBuildingIndexInProgress else { return }
            self.log(message: "Build search index")

            self.registerForPowerStateChange()
            self.registerForThermalState()
            self.registerForNetworkChange()

            // TODO schedule background task
            self.scheduleLoadingCheckTimer()
            self.adaptIndexingSpeedByMemoryUsage()

            self.initializeCurrentState { [weak self] in
                guard let self = self else { return }
                // To initialize progress bar
                _ = self.estimateDownloadingIndexingTime(currentTime: CFAbsoluteTimeGetCurrent())
                switch self.currentState {
                case .creatingIndex, .downloadingNewMessage:
                    self.downloadAndProcessPage()
                case .complete:
                    self.invalidateLoadingCheckTimer()
                default:
                    break
                }
            }
        }
    }

    func pause() {
        log(message: "click paused, isPaused: \(isPaused)")
        if isPaused { return }
        isPaused = true
        stopBuildIndex()
        indexingQueue.async { [weak self] in
            guard let self = self else { return }
            self.log(message: "run pause block")
            self.updateCurrentState(to: .paused(nil))
            self.dependencies.esUserCache.setIndexingPausedByUser(of: self.params.userID, value: true)
            let numberOfPaused = self.dependencies.esUserCache.numberOfPauses(of: self.params.userID)
            self.dependencies.esUserCache.setNumberOfPauses(of: self.params.userID, value: numberOfPaused + 1)
        }
    }

    func resume() {
        guard isPaused,
              case .paused = currentState else { return }
        isPaused = false
        indexingQueue.async { [weak self] in
            guard let self = self else { return }
            self.dependencies.esUserCache.setIndexingPausedByUser(of: self.params.userID, value: false)
            self.start()
        }
    }

    func disable() {
        indexingQueue.async { [weak self] in
            guard let self = self else { return }
            self.dependencies.esUserCache.setIndexingPausedByUser(of: self.params.userID, value: false)
            self.stopBuildIndex()
            self.invalidateLoadingCheckTimer()
            self.updateCurrentState(to: .disabled)
            try? self.dependencies.searchIndexDB.deleteSearchIndex()
        }
    }

    func stopInBackground() {
        stopBuildIndex()
        indexingQueue.sync { [weak self] in
            guard let self = self else { return }
            self.updateCurrentState(to: .backgroundStopped)
        }
    }

    func didChangeDownloadViaMobileDataConfiguration() {
        indexingQueue.async { [weak self] in
            guard let self = self else { return }
            let networkStatus = self.dependencies.connectionStatusProvider.status
            self.networkConditionsChanged(internetStatus: networkStatus)
        }
    }

    func update(delegate: BuildSearchIndexDelegate?) {
        self.delegate = delegate
    }

    /// Update build index state if the value haven't been initialized
    /// Receive updated value from delegate
    func updateCurrentState() {
        indexingQueue.async { [weak self] in
            guard let self = self else { return }
            self.initializeCurrentState(completion: nil)
        }
    }

    // MARK: - Event update
    func rebuildSearchIndex() {
        indexingQueue.async { [weak self] in
            guard let self = self else { return }
            self.updateCurrentState(to: .disabled)
            self.stopBuildIndex()
            self.resetMetricData()
            try? self.dependencies.searchIndexDB.deleteSearchIndex()
            self.dependencies.esUserCache.setIsExternalRefreshed(of: self.params.userID, value: true)
            if self.interruptReason == .none {
                self.start()
            } else {
                // none will trigger start() automatically
                self.interruptReason = .none
            }
        }
    }

    func fetchNewerMessageIfNeeded() {
        indexingQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.currentState == .complete || self.currentState == .partial else { return }
            self.start()
        }
    }

    func remove(messageIDs: [MessageID]) {
        if messageIDs.isEmpty { return }
        indexingQueue.async { [weak self] in
            guard let self = self else { return }
            for id in messageIDs {
                _ = try? self.dependencies.searchIndexDB.removeEntryFromSearchIndex(messageID: id)
            }
        }
    }

    func update(drafts: [MessageEntity]) {
        if drafts.isEmpty { return }
        indexingQueue.async { [weak self] in
            guard let self = self else { return }
            let messageIDs = drafts.map { $0.messageID }
            do {
                guard self.continueBuildIndex() else { return }
                let messages = try self.downloadDetail(for: messageIDs)
                guard self.continueBuildIndex() else { return }
                self.saveDownloadMessages(messages: messages, isUpdate: true)
            } catch {
                self.log(message: "Update draft from event failed, \(error)")
            }
        }
    }

    // MARK: - SearchDB API
    func numberOfEntriesInSearchIndex() -> Int {
        return dependencies.searchIndexDB.numberOfEntries()
    }

    func getDBParams() -> GoLibsEncryptedSearchDBParams? {
        dependencies.searchIndexDB.getDBParams()
    }
}

// MARK: - prerequisite
extension BuildSearchIndex {
    private func canBuildSearchIndex() -> Bool {
        guard dependencies.connectionStatusProvider.status.isConnected else {
            interruptReason.insert(.noConnection)
            return false
        }

        guard createTempDirectoryIfNeeded() else {
            interruptReason.insert(.unExpectedError)
            return false
        }

        guard isTempDirectoryWritable() else {
            interruptReason.insert(.unExpectedError)
            return false
        }

        guard createSearchIndexDBIfNeeded() else {
            interruptReason.insert(.unExpectedError)
            return false
        }

        guard interruptReason == .none else {
            updateCurrentState(to: .paused(interruptReason))
            return false
        }

        return dependencies.searchIndexDB.dbExists
    }

    /// Workaround for disk I/O error: operation not permitted
    /// sometimes /tmp not correctly being detected or being available
    /// check for the tmp directory when building the search index
    /// If it is not available, create it.
    /// - Returns: `true` if temp folder is existed
    ///            `false` if temp folder doesn't exist after creating
    private func createTempDirectoryIfNeeded() -> Bool {
        // TODO discussion indexDB is saved in document directory
        // But this check temporary directory? why ?
        if isTempDirectoryExisted() { return true }
        let tempDirectoryURL = dependencies.fileManager.temporaryDirectory

        try? dependencies.fileManager.createDirectory(
            at: tempDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return isTempDirectoryExisted()
    }

    private func isTempDirectoryExisted() -> Bool {
        let tempDirectoryURL = dependencies.fileManager.temporaryDirectory
        return dependencies.fileManager.fileExists(atPath: tempDirectoryURL.relativePath)
    }

    private func isTempDirectoryWritable() -> Bool {
        let tempDirectoryURL = dependencies.fileManager.temporaryDirectory
        return dependencies.fileManager.isWritableFile(atPath: tempDirectoryURL.relativePath)
    }

    /// - Returns: `true`, search index db is ready
    private func createSearchIndexDBIfNeeded() -> Bool {
        dependencies.searchIndexDB.createIfNeeded()
        return dependencies.searchIndexDB.dbExists
    }

    private func stopAndClearOperationQueue() {
        log(message: "stopAndClearOperationQueue")
        messageIndexingQueue.cancelAllOperations()
        downloadPageQueue.cancelAllOperations()
    }
}

// MARK: - Progress update
extension BuildSearchIndex {
    private func scheduleLoadingCheckTimer() {
        startingTime = CFAbsoluteTimeGetCurrent()
        loadingCheckTimer?.invalidate()
        timerFireTimes = 0
        loadingCheckTimer = Timer.scheduledTimer(
            timeInterval: 2,
            target: self,
            selector: #selector(self.checkLoading),
            userInfo: nil,
            repeats: true
        )
    }

    private func invalidateLoadingCheckTimer() {
        loadingCheckTimer?.invalidate()
        loadingCheckTimer = nil
    }

    @objc
    private func checkLoading() {
        guard isBuildingIndexInProgress else {
            invalidateLoadingCheckTimer()
            return
        }
        timerFireTimes += 1
        adaptIndexingSpeedByMemoryUsage()
    }

    func estimateDownloadingIndexingTime(currentTime: CFAbsoluteTime) -> (BuildSearchIndexEstimatedProgress, Int)? {
        guard totalMessagesCount > 0,
              savedMessagesCount + preexistingIndexedMessagesCount > 0 else {
            return nil
        }
        let remainingMessagesCount = Double(
            totalMessagesCount - downloadedMessagesCount - preexistingIndexedMessagesCount
        )
        let totalIndexedMessages = savedMessagesCount + preexistingIndexedMessagesCount
        let currentProgress = Double(totalIndexedMessages) / Double(totalMessagesCount)

        guard let startingTime = self.startingTime,
              downloadedMessagesCount > 0 else {
            let progress = BuildSearchIndexEstimatedProgress(
                totalMessages: totalMessagesCount,
                indexedMessages: totalIndexedMessages,
                estimatedTimeString: nil,
                currentProgress: max(0, min(1, currentProgress)) * 100
            )
            estimatedProgress.mutate { value in
                value = progress
            }
            return (progress, 0)
        }
        let timeDifference = Double(currentTime - startingTime)
        let estimatedTime = (timeDifference / Double(downloadedMessagesCount)) * remainingMessagesCount
        let progress = BuildSearchIndexEstimatedProgress(
            totalMessages: totalMessagesCount,
            indexedMessages: totalIndexedMessages,
            estimatedTimeString: timeToDate(timeInSecond: estimatedTime),
            currentProgress: max(0, min(1, currentProgress)) * 100
        )
        estimatedProgress.mutate { value in
            value = progress
        }
        return (progress, Int(estimatedTime))
    }

    private func timeToDate(timeInSecond: Double) -> String {
        if timeInSecond < 60 {
            return L11n.EncryptedSearch.less_than_a_minute
        }
        return formatter.string(from: timeInSecond) ?? L11n.EncryptedSearch.estimating_time_remaining
    }

    private func notifyEstimatedProgress(currentTime: CFAbsoluteTime) {
        guard let estimatedInfo = estimateDownloadingIndexingTime(currentTime: currentTime) else { return }
        var progress = estimatedInfo.0
        // Just show a time estimate after a few rounds (to have a more stable estimate)
        let waitRoundsBeforeShowingTimeEstimate: Int = 5
        if timerFireTimes < waitRoundsBeforeShowingTimeEstimate {
            // we set the time estimation to nil
            progress = BuildSearchIndexEstimatedProgress(
                totalMessages: progress.totalMessages,
                indexedMessages: progress.indexedMessages,
                estimatedTimeString: nil,
                currentProgress: progress.currentProgress
            )
        } else {
            if dependencies.esUserCache.initialIndexingEstimationTime(of: params.userID) == 0 {
                let time = estimatedInfo.1
                dependencies.esUserCache.setInitialIndexingEstimationTime(of: params.userID, value: time)
            }
        }
        delegate?.indexBuildingProgressUpdate(progress: progress)
    }
}

// MARK: - Device capability
extension BuildSearchIndex {
    private func isUserAllowedStorageExceeded() -> Bool {
        let storageLimit = dependencies.esDeviceCache.storageLimit
        // Measurement<UnitInformationStorage>.max means user didn't set limitation
        if storageLimit == Measurement<UnitInformationStorage>.max { return false }

        let sizeOfDB = dependencies.searchIndexDB.size ?? .zero
        let safetyBuffer = Measurement<UnitInformationStorage>(value: 2.0, unit: .kilobytes)
        return sizeOfDB > (storageLimit - safetyBuffer)
    }

    private func adaptIndexingSpeedByMemoryUsage() {
        defer {
            messageIndexingQueue.maxConcurrentOperationCount = indexingSpeed
        }
        indexingSpeed = ProcessInfo.processInfo.activeProcessorCount
        addTimeOutWhenIndexingAsMemoryExceeds = false
        let memoryUsage = dependencies.memoryUsage.usagePercentage
        if memoryUsage > 15 {
            addTimeOutWhenIndexingAsMemoryExceeds = true
            pageSize = 1
        } else if memoryUsage > 10 {
            pageSize = ProcessInfo.processInfo.activeProcessorCount
        } else {
            pageSize = 50
        }
    }

    private func registerForNetworkChange() {
        dependencies.connectionStatusProvider.register(receiver: self, fireWhenRegister: false)
    }

    /// Either the internet connection or the user network configuration has changed
    private func networkConditionsChanged(internetStatus: ConnectionStatus) {
        if connectionStatus == nil {
            connectionStatus = internetStatus
            return
        }
        connectionStatus = internetStatus
        guard internetStatus.isConnected else {
            interruptReason.insert(.noConnection)
            return
        }
        interruptReason.remove(.noConnection)
        switch internetStatus {
        case .connectedViaCellular:
            guard dependencies.esUserCache.canDownloadViaMobileData(of: params.userID) else {
                interruptReason.insert(.noWiFi)
                return
            }
            interruptReason.remove(.noWiFi)
        case .connected, .connectedViaWiFi, .connectedViaEthernet:
            interruptReason.remove(.noWiFi)
        case .connectedViaCellularWithoutInternet,
                .connectedViaEthernetWithoutInternet,
                .connectedViaWiFiWithoutInternet,
                .notConnected:
            break
        case .initialize:
            return
        }
    }

    private func registerForThermalState() {
        dependencies.notificationCenter.removeObserver(
            self,
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
        dependencies.notificationCenter.addObserver(
            self,
            selector: #selector(self.thermalStateDidChange),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
    }

    @objc
    private func thermalStateDidChange() {
        let thermalState = ProcessInfo.processInfo.thermalState
        switch thermalState {
        case .nominal, .fair:
            interruptReason.remove(.overHeating)
        case .serious, .critical:
            interruptReason.insert(.overHeating)
        @unknown default:
            break
        }
    }

    private func registerForPowerStateChange() {
        dependencies.notificationCenter.removeObserver(
            self,
            name: .NSProcessInfoPowerStateDidChange,
            object: nil
        )
        dependencies.notificationCenter.addObserver(
            self,
            selector: #selector(self.powerStateDidChange),
            name: .NSProcessInfoPowerStateDidChange,
            object: nil
        )
    }

    @objc
    private func powerStateDidChange() {
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            interruptReason.insert(.lowBattery)
        } else {
            interruptReason.remove(.lowBattery)
        }
    }
}

// MARK: - Start build index
extension BuildSearchIndex {
    private func stopBuildIndex() {
        stopAndClearOperationQueue()
        invalidateLoadingCheckTimer()
        timerFireTimes = 0
    }

    private func initializeCurrentState(completion: (() -> Void)?) {
        guard !isBuildingIndexInProgress else {
            completion?()
            return
        }
        guard isEncryptedSearchEnabled else {
            updateCurrentState(to: .disabled)
            completion?()
            return
        }
        updateMessageCounts { [weak self] error in
            guard let self = self else { return }
            self.savedMessagesCount = 0
            self.downloadedMessagesCount = 0
            self.preexistingIndexedMessagesCount = self.dependencies.searchIndexDB.numberOfEntries()
            if let error {
                self.log(message: "error: Fetch messages count failed \(error)", isError: true)
                self.interruptReason.insert(.unExpectedError)
            } else {
                self.log(message: "Fetch messages count success, total \(self.totalMessagesCount)")
                let isUserPaused = self.dependencies.esUserCache.indexingPausedByUser(of: self.params.userID)
                self.isPaused = isUserPaused
                if self.preexistingIndexedMessagesCount <= 0 {
                    self.dependencies.esUserCache.setShouldSendMetric(of: self.params.userID, value: true)
                    self.updateCurrentState(to: isUserPaused ? .paused(nil) : .creatingIndex)
                } else if self.preexistingIndexedMessagesCount == self.totalMessagesCount {
                    self.updateCurrentState(to: .complete)
                } else {
                    self.updateCurrentState(
                        to: isUserPaused ? .paused(nil) : .downloadingNewMessage(isInitialIndexComplete: false)
                    )
                }
            }
            completion?()
        }
    }

    private func updateMessageCounts(completion: ((Error?) -> Void)?) {
        dependencies
            .countMessagesForLabel
            .callbackOn(indexingQueue)
            .execute(params: .init(labelID: params.labelID)) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    completion?(error)
                case .success(let messageCount):
                    self.totalMessagesCount = messageCount
                    completion?(nil)
                }
            }
    }

    private func continueBuildIndex() -> Bool {
        guard isEncryptedSearchEnabled else {
            updateCurrentState(to: .disabled)
            log(message: "Encrypted search is disabled")
            return false
        }
        guard isBuildingIndexInProgress else {
            log(message: "building index is stop")
            return false
        }
        return true
    }

    private func updateStateDueToEmptyMessageList() {
        if case let .downloadingNewMessage(isInitialIndexComplete: value) = currentState,
           value == false {
            updateCurrentState(to: .creatingIndex)
            downloadAndProcessPage()
        } else if currentState == .creatingIndex {
            updateMessageCounts { [weak self] error in
                guard error == nil else { return }
                self?.updateCurrentState(to: .downloadingNewMessage(isInitialIndexComplete: true))
                self?.downloadAndProcessPage()
            }
        } else {
            updateCurrentState(to: .complete)
        }
    }

    private func downloadAndProcessPage() {
        if addTimeOutWhenIndexingAsMemoryExceeds {
            log(message: "Sleep 2 seconds to lower memory usage")
            Thread.sleep(forTimeInterval: 2)
        }
        guard continueBuildIndex() else { return }
        adaptIndexingSpeedByMemoryUsage()
        let indexingStart = CFAbsoluteTimeGetCurrent()
        do {
            let messageIDs = try downloadAPageOfMessageIDs()
            log(message: "Get \(messageIDs.count) messageIDs")
            if messageIDs.isEmpty {
                updateStateDueToEmptyMessageList()
                log(message: "This page is empty")
                return
            }
            defer { downloadAndProcessPage() }
            guard continueBuildIndex() else { return }
            let downloadedMessages = try downloadDetail(for: messageIDs)
            log(message: "Download detail for \(downloadedMessages.count) messages")

            guard continueBuildIndex() else { return }
            saveDownloadMessages(messages: downloadedMessages, isUpdate: false)
            log(message: "Save downloaded message to searchIndexDB")

            let timeDifference = CFAbsoluteTimeGetCurrent() - indexingStart
            let previousIndexingTime = dependencies.esUserCache.indexingTime(of: params.userID)
            dependencies.esUserCache.setIndexingTime(
                of: params.userID,
                value: previousIndexingTime + Int(timeDifference)
            )
            log(message: "Take \(Int(timeDifference)) seconds for this page")
        } catch {
            log(message: "Error happens in indexing \(error)", isError: true)
        }
    }

    private func downloadAPageOfMessageIDs() throws -> [MessageID] {
        var endTime: Int?
        var beginTime: Int?
        switch currentState {
        case .creatingIndex:
            endTime = dependencies.searchIndexDB.oldestMessageTime() ?? 0
        case .downloadingNewMessage:
            if let newestTime = dependencies.searchIndexDB.newestMessageTime() {
                beginTime = newestTime + 1
            } else {
                beginTime = 0
            }
        default:
            break
        }

        let operation = DownloadPageOperation(
            apiService: dependencies.apiService,
            endTime: endTime,
            beginTime: beginTime,
            labelID: params.labelID,
            pageSize: pageSize,
            userID: params.userID
        )
        downloadPageQueue.addOperation(operation)
        downloadPageQueue.waitUntilAllOperationsAreFinished()
        guard let result = operation.result else {
            throw IndexError.noResult
        }
        switch result {
        case .failure(let error):
            throw error
        case .success(let messageIDs):
            return messageIDs
        }
    }

    private func downloadDetail(for messageIDs: [MessageID], isUpdate: Bool = false) throws -> [ESMessage] {
        let queue = isUpdate ? OperationQueue() : messageIndexingQueue
        queue.maxConcurrentOperationCount = indexingSpeed
        var operations: [IndexSingleMessageDetailOperation] = []
        for id in messageIDs {
            let operation = IndexSingleMessageDetailOperation(
                apiService: dependencies.apiService,
                messageID: id,
                userID: params.userID
            )
            queue.addOperation(operation)
            operations.append(operation)
        }
        log(message: "waiting for download detail")
        queue.waitUntilAllOperationsAreFinished()
        var messages: [ESMessage] = []
        for operation in operations {
            guard let message = try operation.result?.get() else { continue }
            messages.append(message)
        }
        return messages
    }

    private func saveDownloadMessages(messages: [ESMessage], isUpdate: Bool) {
        downloadedMessagesCount += messages.count
        let now = CFAbsoluteTimeGetCurrent()
        for message in messages {
            let canContinue = decryptAndExtractDataSingleMessage(
                message: message.toEntity(),
                userID: params.userID
            )
            if !isUpdate {
                savedMessagesCount += 1
                notifyEstimatedProgress(currentTime: now)
            }
            if !canContinue {
                break
            }
        }
    }

    // - Returns: can continue?
    private func decryptAndExtractDataSingleMessage(
        message: MessageEntity,
        userID: UserID,
        isUpdate: Bool = false
    ) -> Bool {
        var body = ""
        do {
            let result = try dependencies.messageDataService.messageDecrypter.decrypt(message: message)
            body = result.body
        } catch {
            log(message: "Decrypt and extract data failed \(error)")
        }
        let emailContent = body.isEmpty ? "" : EmailparserExtractData(body, true)
        let encryptedContent = EncryptedSearchHelper.createEncryptedMessageContent(
            from: message,
            cleanedBody: emailContent,
            userID: userID
        )
        if isUpdate {
            guard let encryptedContent = encryptedContent else { return true }
            let cipher = encryptedContent.ciphertext
            do {
                _ = try dependencies.searchIndexDB.updateEntryInSearchIndex(
                    messageID: message.messageID,
                    encryptedContent: cipher,
                    encryptionIV: encryptedContent.iv,
                    encryptedContentSize: cipher.count
                )
                return true
            } catch {
                log(message: "Update message to search index failed \(error)", isError: true)
                return true
            }
        } else {
            return addMessageToSearchIndex(message: message, encryptedContent: encryptedContent)
        }
    }

    /// - Returns: isSuccess
    private func addMessageToSearchIndex(
        message: MessageEntity,
        encryptedContent: EncryptedsearchEncryptedMessageContent?
    ) -> Bool {
        guard isBuildingIndexInProgress else { return false }
        let cipherText = encryptedContent?.ciphertext
        let encryptedContentSizeInBytes: Double = Double(Data(base64Encoded: cipherText ?? "")?.count ?? 0)
        let encryptedContentSize = Measurement<UnitInformationStorage>(value: encryptedContentSizeInBytes, unit: .bytes)

        do {

            let isLowOnFreeSpace = dependencies.diskUsage.isLowOnFreeSpace
            let isUserAllowedStorageExceeded = isUserAllowedStorageExceeded()
            if isLowOnFreeSpace || isUserAllowedStorageExceeded {
                guard let state = currentState else { return false }
                switch state {
                case .downloadingNewMessage:
                    log(message: "Shrink search index to save new coming message")
                    let size = dependencies.searchIndexDB.size ?? .zero
                    let expectedSize = size - encryptedContentSize
                    try dependencies.searchIndexDB.shrinkSearchIndex(expectedSize: expectedSize)
                default:
                    if isLowOnFreeSpace {
                        interruptReason.insert(.lowStorage)
                    } else if isUserAllowedStorageExceeded {
                        updateCurrentState(to: .partial)
                    }
                    return false
                }
            }

            let rowID = try dependencies.searchIndexDB.addNewEntryToSearchIndex(
                messageID: message.messageID,
                time: Int(message.time?.timeIntervalSince1970 ?? 0),
                order: message.order,
                labelIDs: message.labels.map { $0.labelID },
                encryptionIV: encryptedContent?.iv,
                encryptedContent: cipherText,
                encryptedContentFile: "",
                encryptedContentSize: Int(encryptedContentSize.converted(to: .bytes).value)
            )
            if rowID == nil {
                log(
                    message: "Error-Insert: message \(message.messageID.rawValue) couldn't be inserted to search index.",
                    isError: true
                )
                return false
            }
            return true
        } catch {
            log(message: "Error-Insert: \(error)", isError: true)
            return false
        }
    }

    private func log(message: String, isError: Bool = false) {
        SystemLogger.log(message: message, category: .encryptedSearch, isError: isError)
    }

    private func sendMetric() {
        guard
            dependencies.userManager.hasTelemetryEnabled,
            dependencies.esUserCache.shouldSendMetric(of: params.userID)
        else { return }
        let numMessagesIndexed = dependencies.searchIndexDB.numberOfEntries()
        let size = dependencies.searchIndexDB.size ?? .zero
        let indexingTime = dependencies.esUserCache.indexingTime(of: params.userID)
        let originalEstimatedTime = dependencies.esUserCache.initialIndexingEstimationTime(of: params.userID)
        let metricData: [String: Any] = [
            "numMessagesIndexed": numMessagesIndexed,
            // the size of the index in Bytes
            "indexSize": size.value,
            // an estimated amount of time taken by indexing, expressed in seconds
            "indexTime": indexingTime,
            // the number of seconds that indexing was first estimated to take
            "originalEstimate": originalEstimatedTime,
            "numPauses": dependencies.esUserCache.numberOfPauses(of: params.userID),
            "numInterruptions": dependencies.esUserCache.numberOfInterruptions(of: params.userID),
            // whether the indexing process was automatically started per effect of a refresh or not.
            "isRefreshed": dependencies.esUserCache.isExternalRefreshed(of: params.userID)
        ]
        let request = MetricEncryptedSearch(type: .index, data: metricData)
        dependencies.apiService.perform(request: request, jsonDictionaryCompletion: { _, _ in })
    }

    private func resetMetricData() {
        dependencies.esUserCache.setNumberOfPauses(of: params.userID, value: 0)
        dependencies.esUserCache.setNumberOfInterruptions(of: params.userID, value: 0)
        dependencies.esUserCache.setIndexingTime(of: params.userID, value: 0)
        dependencies.esUserCache.setInitialIndexingEstimationTime(of: params.userID, value: 0)
        dependencies.esUserCache.setShouldSendMetric(of: params.userID, value: false)
        dependencies.esUserCache.setIsExternalRefreshed(of: params.userID, value: false)
    }
}

// MARK: - Delegate transfer
extension BuildSearchIndex {
    private func interruptReasonHasUpdated() {
        if interruptReason == .none {
            start()
        } else if interruptReason.contains(.unExpectedError) {
            updateCurrentState(to: .undetermined)
            pause()
        } else {
            updateCurrentState(to: .paused(interruptReason))
            pause()
        }
    }

    private func updateCurrentState(to newState: EncryptedSearchIndexState) {
        log(message: "Current state is changed \(newState)")
        if newState == .complete || newState == .partial {
            sendMetric()
            resetMetricData()
        }
        if newState == .complete || newState == .partial || newState == .disabled {
            estimatedProgress.mutate { value in
                value = nil
            }
        }
        currentState = newState
        delegate?.indexBuildingStateDidChange(state: newState)
    }
}

extension BuildSearchIndex: ConnectionStatusReceiver {
    func connectionStatusHasChanged(newStatus: ConnectionStatus) {
        networkConditionsChanged(internetStatus: newStatus)
    }
}

extension BuildSearchIndex {
    struct InterruptReason: OptionSet {
        let rawValue: Int
        static let none = InterruptReason([])
        static let noConnection = InterruptReason(rawValue: 1 << 0)
        /// Has cellular but `download via mobile data` is disabled
        static let noWiFi = InterruptReason(rawValue: 1 << 1)
        static let overHeating = InterruptReason(rawValue: 1 << 2)
        static let lowBattery = InterruptReason(rawValue: 1 << 3)
        /// There is less than 100MB storage left on the device
        static let lowStorage = InterruptReason(rawValue: 1 << 4)
        static let unExpectedError = InterruptReason(rawValue: 1 << 5)

        var stateDescription: String {
            if self.contains(.noConnection) {
                return L11n.EncryptedSearch.download_paused_no_connectivity
            } else if self.contains(.noWiFi) {
                return L11n.EncryptedSearch.download_paused_no_wifi
            } else if self.contains(.lowBattery) {
                return L11n.EncryptedSearch.download_paused_low_battery
            } else if self.contains(.overHeating) {
                // TODO why there is no string for this case
                assertionFailure("Without translation")
                return "Download paused due to over heating"
            } else if self.contains(.lowStorage) {
                return L11n.EncryptedSearch.download_paused_low_storage
            } else if self.contains(.none) {
                return .empty
            } else {
                assertionFailure("Unknown interrupt reason")
                return .empty
            }
        }

        var adviceDescription: String {
            if self.contains(.noConnection) {
                return L11n.EncryptedSearch.download_paused_no_connectivity_advice
            } else if self.contains(.noWiFi) {
                return L11n.EncryptedSearch.download_paused_no_wifi_advice
            } else if self.contains(.lowBattery) {
                return L11n.EncryptedSearch.download_paused_low_battery_advice
            } else if self.contains(.overHeating) {
                // TODO why there is no string for this case
                return "Cool down"
            } else if self.contains(.lowStorage) {
                return L11n.EncryptedSearch.download_paused_low_storage_advice
            } else if self.contains(.none) {
                return .empty
            } else {
                assertionFailure("Unknown interrupt reason")
                return .empty
            }
        }
    }

    struct Params {
        let userID: UserID
        let labelID: LabelID

        init(userID: UserID, labelID: LabelID = LabelLocation.allmail.labelID) {
            self.userID = userID
            self.labelID = labelID
        }
    }

    struct Dependencies {
        let apiService: APIService
        let connectionStatusProvider: InternetConnectionStatusProvider
        let countMessagesForLabel: CountMessagesForLabelUseCase
        let diskUsage: DiskUsageProtocol
        let esDeviceCache: EncryptedSearchDeviceCache
        let esUserCache: EncryptedSearchUserCache
        let fileManager: FileManagerProtocol
        let memoryUsage: MemoryUsageProtocol
        let messageDataService: MessageDataService
        let notificationCenter: NotificationCenter
        let searchIndexDB: SearchIndexDB
        let userManager: UserManager

        init(
            apiService: APIService,
            connectionStatusProvider: InternetConnectionStatusProvider,
            countMessagesForLabel: CountMessagesForLabelUseCase,
            diskUsage: DiskUsageProtocol = DeviceCapacity.Disk(),
            esDeviceCache: EncryptedSearchDeviceCache,
            esUserCache: EncryptedSearchUserCache,
            fileManager: FileManagerProtocol = FileManager.default,
            memoryUsage: MemoryUsageProtocol = DeviceCapacity.Memory(),
            messageDataService: MessageDataService,
            notificationCenter: NotificationCenter = NotificationCenter.default,
            searchIndexDB: SearchIndexDB,
            userManager: UserManager
        ) {
            self.apiService = apiService
            self.connectionStatusProvider = connectionStatusProvider
            self.countMessagesForLabel = countMessagesForLabel
            self.diskUsage = diskUsage
            self.esDeviceCache = esDeviceCache
            self.esUserCache = esUserCache
            self.fileManager = fileManager
            self.memoryUsage = memoryUsage
            self.messageDataService = messageDataService
            self.notificationCenter = notificationCenter
            self.searchIndexDB = searchIndexDB

            self.userManager = userManager
        }
    }
}

struct BuildSearchIndexEstimatedProgress {
    /// Total number of messages
    let totalMessages: Int
    /// Number of messages already indexed
    let indexedMessages: Int
    /// Time that is human readable, e.g. 3 days 2 hour
    let estimatedTimeString: String?
    /// Download progress, 0 ~ 100
    let currentProgress: Double
}

extension BuildSearchIndex {
    enum IndexError: Error {
        case encryptedSearchIsDisabled
        case selfIsReleased
        case previousTaskDidNotFinish
        case noResult
        case taskIsCancelled
    }
}
