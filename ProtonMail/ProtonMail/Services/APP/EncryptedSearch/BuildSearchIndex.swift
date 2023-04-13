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

protocol BuildSearchIndexDelegate: AnyObject {
    func indexBuildingStateDidChange(state: EncryptedSearchIndexState)
    func indexBuildingProgressUpdate(progress: Double)
    func indexBuildingEstimatedTimeUpdate(estimatedTime: String)
}

final class BuildSearchIndex {
    private let dependencies: Dependencies
    private let params: Params
    private weak var delegate: BuildSearchIndexDelegate?
    private var progressUpdateTimer: Timer?
    private var timerFireTimes: Int = 0
    /// Time to start build search index
    private var startingTime: CFAbsoluteTime?
    private var totalMessagesCount: Int = 0
    private var interruptReason: InterruptReason = .none {
        didSet { interruptReasonHasUpdated() }
    }
    private var pageSize: Int = 150 {
        didSet { log(message: "Page size is updated to \(pageSize)")}
    }
    private var indexingSpeed = OperationQueue.defaultMaxConcurrentOperationCount
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

    private(set) var currentState: EncryptedSearchIndexState?
    private var processedMessagesCount: Int = 0
    private let observerID = UUID()

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
    }

    var isBuildingIndexInProgress: Bool {
        // TODO: No computed variable should be changing the state of the indexing.
        // Should have a way to observe user disable encrypted search
//        guard isEncryptedSearchEnabled else {
//            updateCurrentState(to: .disabled)
//            return false
//        }
        guard let state = currentState else { return false }
        let expectedStatus: [EncryptedSearchIndexState] = [.background, .downloading, .refresh]
        return expectedStatus.containsCase(state)
    }

    var isEncryptedSearchEnabled: Bool {
        dependencies.esUserCache.isEncryptedSearchOn(of: params.userID)
    }

    func start() {
        guard canBuildSearchIndex(),
              !isBuildingIndexInProgress else { return }
        log(message: "Build search index")

        registerForPowerStateChange()
        registerForThermalState()
        registerForNetworkChange()

        // TODO schedule background task
        scheduleProgressUpdateTimer()
        enableOperationQueue()
        adaptIndexingSpeedByMemoryUsage()

        initializeCurrentState { [weak self] in
            guard let self = self else { return }
            switch self.currentState {
            case .downloading:
                self.downloadAndProcessPage()
            case .refresh:
                self.refreshSearchIndex()
            case .complete:
                self.cleanupAfterIndexing()
            default:
                break
            }
        }
    }

    func pause() {
        stopAndClearOperationQueue()
        cleanupAfterIndexing()
        timerFireTimes = 0
        guard isBuildingIndexInProgress else { return }
        updateCurrentState(to: .paused(nil))
    }

    func update(delegate: BuildSearchIndexDelegate?) {
        self.delegate = delegate
    }

    func signOut() {
        pause()
        try? dependencies.searchIndexDB.deleteSearchIndex()
    }

    /// Update build index state if the value haven't been initialized
    /// Receive updated value from delegate
    func updateCurrentState() {
        initializeCurrentState(completion: nil)
    }
}

// MARK: - prerequisite
extension BuildSearchIndex {
    private func canBuildSearchIndex() -> Bool {
        guard dependencies.connectionStatusProvider.currentStatus.isConnected else {
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

    private func enableOperationQueue() {
        messageIndexingQueue.isSuspended = false
        downloadPageQueue.isSuspended = false
    }

    private func stopAndClearOperationQueue() {
        messageIndexingQueue.isSuspended = true
        messageIndexingQueue.cancelAllOperations()

        downloadPageQueue.isSuspended = true
        downloadPageQueue.cancelAllOperations()
    }
}

// MARK: - Progress update
extension BuildSearchIndex {
    private func scheduleProgressUpdateTimer() {
        startingTime = CFAbsoluteTimeGetCurrent()
        progressUpdateTimer?.invalidate()
        timerFireTimes = 0
        progressUpdateTimer = Timer.scheduledTimer(
            timeInterval: 2,
            target: self,
            selector: #selector(self.updateProgress),
            userInfo: nil,
            repeats: true
        )
    }

    private func invalidateProgressUpdateTimer() {
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = nil
    }

    @objc
    private func updateProgress() {
        guard isBuildingIndexInProgress else {
            invalidateProgressUpdateTimer()
            return
        }
        timerFireTimes += 1
        switch currentState {
        case .downloading:
            guard let result = estimateDownloadingIndexingTime() else { return }
            updateEstimatedResultIfNeeded(result: result)
            // TODO case .refresh:
        default:
            break
        }
        stopIndexIfNoEnoughStorage()
        stopIndexIfExceedStorageLimit()
        adaptIndexingSpeedByMemoryUsage()
    }

    private func estimateDownloadingIndexingTime() -> EstimatedProgress? {
        guard totalMessagesCount > 0,
              processedMessagesCount > 0,
              let startingTime = startingTime else {
            return nil
        }
        //TODO consider previous processed message when implement refresh build
        let remainingMessagesCount = Double(totalMessagesCount) - Double(processedMessagesCount)
        let currentTime = CFAbsoluteTimeGetCurrent()
        let timeDifference = Double(currentTime - startingTime)
        let estimatedTime = (timeDifference / Double(processedMessagesCount)) * remainingMessagesCount
        let currentProgress = Double(processedMessagesCount) / Double(totalMessagesCount)
        return EstimatedProgress(
            estimatedTimeString: timeToDate(timeInSecond: estimatedTime),
            estimatedTime: estimatedTime,
            currentProgress: max(0, min(1, currentProgress)) * 100
        )
    }

    private func timeToDate(timeInSecond: Double) -> String {
        if timeInSecond < 60 {
            return L11n.EncryptedSearch.less_than_a_minute
        }
        return formatter.string(from: timeInSecond) ?? L11n.EncryptedSearch.estimating_time_remaining
    }

    private func updateEstimatedResultIfNeeded(result: EstimatedProgress) {
        delegate?.indexBuildingProgressUpdate(progress: result.currentProgress)

        guard totalMessagesCount > 0 else { return }
        // Just show an time estimate after a few rounds (to have a more stable estimate)
        let waitRoundsBeforeShowingTimeEstimate: Int = 5
        if timerFireTimes >= waitRoundsBeforeShowingTimeEstimate {
            delegate?.indexBuildingEstimatedTimeUpdate(estimatedTime: result.estimatedTimeString)
        }
    }
}

// MARK: - Device capability
extension BuildSearchIndex {
    /// Stop if device has no enough storage
    /// - Returns: true: stop process
    @discardableResult
    private func stopIndexIfNoEnoughStorage() -> Bool {
        guard isBuildingIndexInProgress else { return false }

        if dependencies.diskUsage.isLowOnFreeSpace {
            interruptReason = .lowStorage
            return true
        }
        return false
    }

    /// Stop if saved data exceeds given storage limit
    /// - Returns: true: stop processing
    @discardableResult
    private func stopIndexIfExceedStorageLimit() -> Bool {
        guard isBuildingIndexInProgress else { return false }

        let storageLimit = dependencies.esDeviceCache.storageLimit
        // Int.max means user didn't set limitation
        if storageLimit == Int.max { return false }

        let sizeOfDB = dependencies.searchIndexDB.size ?? 0
        if sizeOfDB > (storageLimit - 2_000) {
            updateCurrentState(to: .partial)
            pause()
            return true
        }
        return false
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
        dependencies.connectionStatusProvider.registerConnectionStatus(observerID: observerID) { [weak self] status in
            self?.networkStatusChanged(to: status)
        }
    }

    private func networkStatusChanged(to status: ConnectionStatus) {
        guard status.isConnected else {
            interruptReason.insert(.noConnection)
            return
        }
        interruptReason.remove(.noConnection)
        switch status {
        case .connectedViaCellular:
            guard dependencies.esUserCache.canDownloadViaMobileData(of: params.userID) else {
                interruptReason.insert(.noWiFi)
                return
            }
            interruptReason.remove(.noWiFi)
            resumeSearchIndex()
        case .connected, .connectedViaWiFi, .connectedViaEthernet:
            interruptReason.remove(.noWiFi)
            resumeSearchIndex()
        case .connectedViaCellularWithoutInternet,
                .connectedViaEthernetWithoutInternet,
                .connectedViaWiFiWithoutInternet,
                .notConnected:
            break
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
    private func initializeCurrentState(completion: (() -> Void)?) {
        guard currentState == nil else {
            completion?()
            return
        }
        guard isEncryptedSearchEnabled else {
            updateCurrentState(to: .disabled)
            completion?()
            return
        }
        dependencies.countMessagesForLabel.execute(params: .init(labelID: params.labelID)) { [weak self] result in
            guard let self = self else { return }
            defer { completion?() }
            switch result {
            case .failure(let error):
                self.log(message: "error: Fetch messages count failed \(error)", isError: true)
                self.interruptReason.insert(.unExpectedError)
            case .success(let messageCount):
                guard messageCount > 0 else {
                    self.updateCurrentState(to: .complete)
                    return
                }
                self.totalMessagesCount = messageCount
                self.log(message: "Fetch messages count success, total \(messageCount)")
                do {
                    let numOfMessageInIndex = try self.dependencies.searchIndexDB.numberOfEntries()
                    if numOfMessageInIndex <= 0 {
                        self.updateCurrentState(to: .downloading)
                    } else if numOfMessageInIndex == messageCount {
                        self.updateCurrentState(to: .complete)
                    } else {
                        self.updateCurrentState(to: .refresh)
                    }
                } catch {
                    self.log(message: "Fetch local cache messages count failed \(error)")
                    // TODO discussion No db connection or query has issue, recreate db and build index from scratch could be a solution
                    self.interruptReason.insert(.unExpectedError)
                }
            }
        }
    }

    private func downloadAndProcessPage() {
        if addTimeOutWhenIndexingAsMemoryExceeds {
            log(message: "Sleep 2 seconds to lower memory usage")
            Thread.sleep(forTimeInterval: 2)
        }
        if processedMessagesCount >= totalMessagesCount {
            updateCurrentState(to: .complete)
        }
        downloadPage()
    }

    private func downloadPage() {
        guard isBuildingIndexInProgress else { return }
        adaptIndexingSpeedByMemoryUsage()
        let time = dependencies.searchIndexDB.oldestMessageTime() ?? 0

        let operation = DownloadPageOperation(
            apiService: dependencies.apiService,
            endTime: time,
            labelID: params.labelID,
            pageSize: pageSize,
            userID: params.userID
        )
        downloadPageQueue.addOperation(operation)
        downloadPageQueue.waitUntilAllOperationsAreFinished()
        guard let result = operation.result else { return }
        switch result {
        case .failure(let error):
            log(message: "Download page error \(error)", isError: true)
        case .success(let esMessages):
            downloadDetail(for: esMessages)
        }
        downloadAndProcessPage()
    }

    private func downloadDetail(for messages: [ESMessage]) {
        guard isBuildingIndexInProgress else {
            return
        }

        guard !messages.isEmpty else {
            updateCurrentState(to: .complete)
            return
        }
        messageIndexingQueue.maxConcurrentOperationCount = indexingSpeed
        var operations: [IndexSingleMessageDetailOperation] = []
        for message in messages {
            let operation = IndexSingleMessageDetailOperation(
                apiService: dependencies.apiService,
                message: message,
                userID: params.userID
            )
            messageIndexingQueue.addOperation(operation)
            operations.append(operation)
        }
        messageIndexingQueue.waitUntilAllOperationsAreFinished()
        processDownloadDetail(indexOperations: operations)
    }

    private func processDownloadDetail(indexOperations: [IndexSingleMessageDetailOperation]) {
        var processedCount = 0
        for operation in indexOperations {
            guard let result = operation.result else { continue }
            switch result {
            case .failure(let error):
                // TODO discussion error handling
                log(message: "Index single message detail failed \(error)", isError: true)
            case .success(let esMessage):
                let canContinue = decryptAndExtractDataSingleMessage(
                    message: esMessage.toEntity(),
                    userID: params.userID
                )
                if !canContinue {
                    break
                }
                processedCount += 1
            }
        }
        processedMessagesCount += processedCount
        // TODO discussion update progress, there is a timer to update UI every 2 seconds
        // Really need this one?
    }

    /// - Returns: isSuccess
    private func addMessageToSearchIndex(
        message: MessageEntity,
        encryptedContent: EncryptedsearchEncryptedMessageContent?
    ) -> Bool {
        guard isBuildingIndexInProgress else { return false }
        let cipherText = encryptedContent?.ciphertext
        let encryptedContentSize: Int = Data(base64Encoded: cipherText ?? "")?.count ?? 0

        do {
            if stopIndexIfExceedStorageLimit() || stopIndexIfNoEnoughStorage() {
                log(message: "Shrink search index to fix message")
                let size = dependencies.searchIndexDB.size ?? 0
                let expectedSize = size - encryptedContentSize
                try dependencies.searchIndexDB.shrinkSearchIndex(expectedSize: expectedSize)
                // TOOD: if the space is not enough
                // Do we need to delete existing cache to save older message?
                // Or just abandon it
            }

            let rowID = try dependencies.searchIndexDB.addNewEntryToSearchIndex(
                messageID: message.messageID,
                time: Int(message.time?.timeIntervalSince1970 ?? 0),
                order: message.order,
                labelIDs: message.labels.map { $0.labelID },
                encryptionIV: encryptedContent?.iv,
                encryptedContent: cipherText,
                encryptedContentFile: "",
                encryptedContentSize: encryptedContentSize
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
            // TODO error handling
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

    private func cleanupAfterIndexing() {
        log(message: "Clean up after indexing")
        invalidateProgressUpdateTimer()
        let finishStates: [EncryptedSearchIndexState] = [.complete, .partial]
        guard let state = currentState,
              finishStates.contains(state) else { return }
        delegate?.indexBuildingProgressUpdate(progress: 100)

        // TODO cancel background task
        // TODO sendIndexingMetrics
        if currentState == .complete {
            // TODO processEventsAfterIndexing
            // Process new added message during indexing
            // The data is from core data
            // I think this is not very reliable, imagine the messages are coming when app is terminated
        }
    }

    private func log(message: String, isError: Bool = false) {
        SystemLogger.log(message: message, category: .encryptedSearch, isError: isError)
    }
}

// MARK: - Refresh
extension BuildSearchIndex {
    private func refreshSearchIndex() {
        // TODO todo
    }

    private func resumeSearchIndex() {
        // TODO todo
    }
}

// MARK: - Delegate transfer
extension BuildSearchIndex {
    private func interruptReasonHasUpdated() {
        if interruptReason == .none {
            // TODO resume
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
        currentState = newState
        delegate?.indexBuildingStateDidChange(state: newState)
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
            searchIndexDB: SearchIndexDB
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
        }
    }

    struct EstimatedProgress {
        /// Time that human readable, e.g. 3 days 2 hour
        let estimatedTimeString: String
        /// Time in second
        let estimatedTime: Double
        /// Download progress, 0 ~ 100
        let currentProgress: Double
    }
}
