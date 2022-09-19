//
//  EncryptedSearchService.swift
//  ProtonMail
//
//  Created by Ralph Ankele on 05.07.21.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import Foundation
import CoreData
import SwiftSoup
import SQLite
import Crypto
import CryptoKit
import Network
import Groot
import BackgroundTasks
//import Reachability

import ProtonCore_Services
import ProtonCore_DataModel
import UIKit

extension Array {
    func chunks(_ chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

public class EncryptedSearchService {
    // Instance of Singleton
    static let shared = EncryptedSearchService()

    // Set initializer to private - Singleton
    private init(){
        let users: UsersManager = sharedServices.get(by: UsersManager.self)
        if users.firstUser != nil {
            user = users.firstUser //should return the currently active user
            messageService = user.messageService
            self.apiService = user.apiService
            self.userDataSource = user.messageService.userDataSource
        }

        self.timeFormatter.allowedUnits = [.hour, .minute, .second]
        self.timeFormatter.unitsStyle = .abbreviated

        // Enable temperature monitoring
        self.registerForTermalStateChangeNotifications()
        // Enable battery level monitoring
        self.registerForPowerStateChangeNotifications()
        // Enable network monitoring
        if #available(iOS 12, *) {
            // Enable network monitoring if not already enabled
            if self.networkMonitor == nil {
                self.registerForNetworkChangeNotifications()
            }
        } else {
            // Use Reachability for iOS 11
        }
    }

    // State variables
    enum EncryptedSearchIndexState: Int {
        case disabled = 0
        case partial = 1
        case lowstorage = 2
        case downloading = 3
        case paused = 4
        case refresh = 5
        case complete = 6
        case undetermined = 7
        case background = 8     // Indicates that the index is currently build in the background
        case backgroundStopped = 9  // Indicates that the index building has been paused while building in the background
    }

    // User dependent variables
    internal var user: UserManager!
    internal var messageService: MessageDataService? = nil
    internal var apiService: APIService? = nil
    internal var userDataSource: UserDataSource? = nil
    var totalMessages: Int = 0
    var lastMessageTimeIndexed: Int = 0     // Stores the time of the last indexed message in case of an interrupt, or to fetch more than the limit of messages per request
    var processedMessages: Int = 0
    var noNewMessagesFound: Int = 0 // counter to break message fetching loop if no new messages are fetched after 5 attempts
    internal var prevProcessedMessages: Int = 0 // number of messages that are processed in an previous index building attempt
    internal var cipherForSearchIndex: EncryptedsearchAESGCMCipher? = nil
    internal var searchState: EncryptedsearchSearchState? = nil
    lazy var messageIndexingQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Message Indexing Queue"
        return queue
    }()
    lazy var downloadPageQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Download Page Queue"
        queue.maxConcurrentOperationCount = 1   // Download 1 page at a time
        return queue
    }()
    internal var numPauses: Int = 0
    internal var numInterruptions: Int = 0
    internal var isFirstSearch: Bool = true
    internal var isFirstIndexingTimeEstimate: Bool = true
    internal var initialIndexingEstimate: Int = 0
    internal var estimateIndexTimeRounds: Int = 0
    internal var isRefreshed: Bool = false
    public var isSearching: Bool = false    // indicates that a search is currently active

    // Device dependent variables
    internal var viewModel: SettingsEncryptedSearchViewModel? = nil
    #if !APP_EXTENSION
    internal var searchViewModel: SearchViewModel? = nil
    #endif
    internal var slowDownIndexBuilding: Bool = false
    @available(iOS 12, *)
    internal lazy var networkMonitor: NWPathMonitor? = nil
    internal var pauseIndexingDueToNetworkConnectivityIssues: Bool = false
    internal var pauseIndexingDueToWiFiNotDetected: Bool = false
    internal var pauseIndexingDueToOverheating: Bool = false
    internal var pauseIndexingDueToLowBattery: Bool = false
    internal var pauseIndexingDueToLowStorage: Bool = false

    // Independent variables
    let timeFormatter = DateComponentsFormatter()
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    internal var indexingStartTime: Double = 0
    internal var eventsWhileIndexing: [MessageAction]? = []
    internal var indexBuildingTimer: Timer? = nil
    internal var slowSearchTimer: Timer? = nil
}

extension EncryptedSearchService {
    func updateViewModelIfNeeded(viewModel: SettingsEncryptedSearchViewModel) {
        if self.viewModel == nil {
            self.viewModel = viewModel
        }
    }

    func resizeSearchIndex(expectedSize: Int64, userID: String) -> Void {
        DispatchQueue.global(qos: .userInitiated).async {
            let success: Bool = EncryptedSearchIndexService.shared.resizeSearchIndex(userID: userID, expectedSize: expectedSize)
            if success == false {
                self.setESState(userID: userID, indexingState: .complete)
            } else {
                self.setESState(userID: userID, indexingState: .partial)

                self.lastMessageTimeIndexed = EncryptedSearchIndexService.shared.getNewestMessageInSearchIndex(for: userID)
            }
        }
    }

    // MARK: - Index Building Functions
    func buildSearchIndex(userID: String, viewModel: SettingsEncryptedSearchViewModel) -> Void {
        // Update API services to current user
        self.updateUserAndAPIServices()

        #if !APP_EXTENSION
            if #available(iOS 13, *) {
                self.scheduleNewAppRefreshTask()
                self.scheduleNewBGProcessingTask()
            }
        #endif

        self.viewModel = viewModel
        self.setESState(userID: userID, indexingState: .downloading)

        // Check if search index db exists - and if not create it
        EncryptedSearchIndexService.shared.createSearchIndexDBIfNotExisting(for: userID)

        // Network checks
        if #available(iOS 12, *) {
            // Check network status - enable network monitoring if not available
            print("ES-NETWORK - build search index - enable network monitoring")
            self.registerForNetworkChangeNotifications()
            if self.pauseIndexingDueToNetworkConnectivityIssues || self.pauseIndexingDueToWiFiNotDetected {
                return
            }
        } else {
            // Fallback on earlier versions
        }

        // Set up timer to estimate time for index building every 2 seconds
        DispatchQueue.main.async {
            self.indexingStartTime = CFAbsoluteTimeGetCurrent()
            self.indexBuildingTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.updateRemainingIndexingTime), userInfo: nil, repeats: true)
        }

        // Set indexbuilding queues suspension to false if previously suspended
        self.messageIndexingQueue.isSuspended = false
        self.downloadPageQueue.isSuspended = false

        self.getTotalMessages(userID: userID) {
            print("Total messages: ", self.totalMessages)

            let numberOfMessageInIndex: Int = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID)
            if numberOfMessageInIndex == 0 {
                print("ES-DEBUG: Build search index completely new")
                // If there are no message in the search index - build completely new
                DispatchQueue.global(qos: .userInitiated).async {
                    self.downloadAndProcessPage(userID: userID){ [weak self] in
                        self?.checkIfIndexingIsComplete(userID: userID, completionHandler: {})
                    }
                }
            } else if numberOfMessageInIndex == self.totalMessages {
                // No new messages on server - set to complete
                self.setESState(userID: userID, indexingState: .complete)

                // update user cached status
                userCachedStatus.indexComplete = true

                self.cleanUpAfterIndexing(userID: userID)
            } else {
                print("ES-DEBUG: refresh search index")
                // There are some new messages on the server - refresh the index
                self.refreshSearchIndex(userID: userID)
            }
        }
    }

    func restartIndexBuilding(userID: String) -> Void {
        // Set the state to downloading
        self.setESState(userID: userID, indexingState: .downloading)

        // Set indexbuilding queues suspension to false if previously suspended
        self.messageIndexingQueue.isSuspended = false
        self.downloadPageQueue.isSuspended = false

        // Update API services to current user
        self.updateUserAndAPIServices()

        // Update the UI with refresh state
        self.updateUIWithIndexingStatus()

        // Set processed message to the number of entries in the search index
        self.processedMessages = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID)
        self.prevProcessedMessages = self.viewModel?.progressedMessages.value ?? EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID)

        // Update last indexed message with the newest message in search index
        self.lastMessageTimeIndexed = EncryptedSearchIndexService.shared.getNewestMessageInSearchIndex(for: userID)

        // Restart index building timers
        DispatchQueue.main.async {
            self.indexingStartTime = CFAbsoluteTimeGetCurrent()
            if self.indexBuildingTimer != nil {
                self.indexBuildingTimer?.invalidate()
                self.indexBuildingTimer = nil
            }
            self.indexBuildingTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.updateRemainingIndexingTime), userInfo: nil, repeats: true)
        }

        // Enable network monitoring - if not already enabled
        if #available(iOS 12, *) {
            if self.networkMonitor == nil {
                self.registerForNetworkChangeNotifications()
            }
        } else {
            // Use Reachability for iOS 11
        }

        // Start refreshing the index
        DispatchQueue.global(qos: .userInitiated).async {
            self.getTotalMessages(userID: userID) {
                self.downloadAndProcessPage(userID: userID){ [weak self] in
                    self?.checkIfIndexingIsComplete(userID: userID, completionHandler: {})
                }
            }
        }
    }

    private func refreshSearchIndex(userID: String) -> Void {
        // Set the state to refresh
        self.setESState(userID: userID, indexingState: .refresh)

        // Set indexbuilding queues suspension to false if previously suspended
        self.messageIndexingQueue.isSuspended = false
        self.downloadPageQueue.isSuspended = false

        // Update the UI with refresh state
        self.updateUIWithIndexingStatus()

        // Set processed message to the number of entries in the search index
        self.processedMessages = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID)
        self.prevProcessedMessages = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID)

        // Update last indexed message with the newest message in search index
        self.lastMessageTimeIndexed = EncryptedSearchIndexService.shared.getNewestMessageInSearchIndex(for: userID)

        // Start refreshing the index
        DispatchQueue.global(qos: .userInitiated).async {
            self.downloadAndProcessPage(userID: userID){ [weak self] in
                self?.checkIfIndexingIsComplete(userID: userID, completionHandler: {})
            }
        }
    }

    private func checkIfIndexingIsComplete(userID: String, completionHandler: @escaping () -> Void) {
        self.getTotalMessages(userID: userID) {
            let numberOfEntriesInSearchIndex: Int = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID)
            print("ES-DEBUG: entries in search index: \(numberOfEntriesInSearchIndex), total messages: \(self.totalMessages)")
            if numberOfEntriesInSearchIndex == self.totalMessages {
                self.setESState(userID: userID, indexingState: .complete)

                // update user cached status
                userCachedStatus.indexComplete = true

                // cleanup
                self.cleanUpAfterIndexing(userID: userID)
            } else {
                let expectedESStates: [EncryptedSearchIndexState] = [.downloading, .refresh]
                if expectedESStates.contains(self.getESState(userID: userID)) {
                    self.setESState(userID: userID, indexingState: .partial)

                    // update user cached status
                    userCachedStatus.indexComplete = true

                    // cleanup
                    self.cleanUpAfterIndexing(userID: userID)
                }
            }
            completionHandler()
        }
    }

    private func cleanUpAfterIndexing(userID: String) {
        let expectedESStates: [EncryptedSearchIndexState] = [.complete, .partial]
        if expectedESStates.contains(self.getESState(userID: userID)) {
            // set some status variables
            self.viewModel?.isEncryptedSearch = true
            self.viewModel?.currentProgress.value = 100
            self.viewModel?.estimatedTimeRemaining.value = nil
            self.estimateIndexTimeRounds = 0
            self.isFirstIndexingTimeEstimate = true
            self.initialIndexingEstimate = 0

            // Unregister network monitoring
            if #available(iOS 12, *) {
                self.unRegisterForNetworkChangeNotifications()
            } else {
                // Fallback on earlier versions
            }

            // Invalidate timer on same thread as it has been created
            DispatchQueue.main.async {
                self.indexBuildingTimer?.invalidate()
            }

            // Stop background tasks
            #if !APP_EXTENSION
                if #available(iOS 13, *) {
                    self.cancelBGProcessingTask()
                    self.cancelBGAppRefreshTask()
                }
            #endif

            // Send indexing metrics to backend
            var indexingTime: Double = CFAbsoluteTimeGetCurrent() - self.indexingStartTime
            if indexingTime.isLess(than: 0.0) {
                print("Error indexing time negative!")
                indexingTime = 0.0
            }
            self.sendIndexingMetrics(indexTime: indexingTime, userID: userID)

            // Compress sqlite database
            DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                EncryptedSearchIndexService.shared.compressSearchIndex(for: userID)
            }

            // Update UI
            self.updateUIIndexingComplete()

            // TODO set state according to user
            let stateBeforeRefreshing: EncryptedSearchIndexState = self.getESState(userID: userID)
            // Process events that have been accumulated during indexing
            self.processEventsAfterIndexing(userID: userID) {
                // Set state when finished
                self.setESState(userID: userID, indexingState: stateBeforeRefreshing)
                self.viewModel?.indexStatus = self.getESState(userID: userID).rawValue

                // Invalidate timer on same thread as it has been created
                DispatchQueue.main.async {
                    self.indexBuildingTimer?.invalidate()
                }

                // Update UI
                self.updateUIIndexingComplete()
            }
        } else if self.getESState(userID: userID) == .paused {
            // Invalidate timer on same thread as it has been created
            DispatchQueue.main.async {
                self.indexBuildingTimer?.invalidate()
            }
        }
    }

    func pauseAndResumeIndexingByUser(isPause: Bool, userID: String) -> Void {
        if isPause {
            self.numPauses += 1
            self.setESState(userID: userID, indexingState: .paused)
        } else {
            self.setESState(userID: userID, indexingState: .downloading)
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.pauseAndResumeIndexing(userID: userID)
        }
    }

    func pauseAndResumeIndexingDueToInterruption(isPause: Bool, userID: String){
        if isPause {
            self.numInterruptions += 1
            self.setESState(userID: userID, indexingState: .paused)
        } else {
            // Check if any of the flags is set to true
            if self.pauseIndexingDueToLowBattery || self.pauseIndexingDueToNetworkConnectivityIssues || self.pauseIndexingDueToOverheating || self.pauseIndexingDueToLowStorage || self.pauseIndexingDueToWiFiNotDetected {
                self.setESState(userID: userID, indexingState: .paused)

                return
            }
            self.setESState(userID: userID, indexingState: .downloading)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.pauseAndResumeIndexing(userID: userID)
        }
    }

    private func pauseAndResumeIndexing(userID: String) {
        if self.getESState(userID: userID) == .paused {
            print("Pause indexing!")
            self.downloadPageQueue.cancelAllOperations()
            self.messageIndexingQueue.cancelAllOperations()

            self.cleanUpAfterIndexing(userID: userID)
            // In case of an interrupt - update UI
            if self.pauseIndexingDueToLowBattery || self.pauseIndexingDueToNetworkConnectivityIssues || self.pauseIndexingDueToOverheating || self.pauseIndexingDueToLowStorage || self.pauseIndexingDueToWiFiNotDetected {
                self.updateUIWithIndexingStatus()
            }
        } else {
            print("Resume indexing...")
            self.restartIndexBuilding(userID: userID)
        }
    }

    struct MessageAction {
        var action: NSFetchedResultsChangeType? = nil
        var message: Message? = nil
    }

    func updateSearchIndex(action: NSFetchedResultsChangeType, message: Message?, userID: String, completionHandler: @escaping () -> Void) {
        let expectedESStates: [EncryptedSearchIndexState] = [.downloading, .paused, .background, .backgroundStopped]
        if expectedESStates.contains(self.getESState(userID: userID)) {
            let messageAction: MessageAction = MessageAction(action: action, message: message)
            self.eventsWhileIndexing!.append(messageAction)
            completionHandler()
        } else {
            switch action {
                case .delete, .move:
                    self.updateMessageMetadataInSearchIndex(action: action, message: message, userID: userID) {
                        // Update cache if existing
                        if EncryptedSearchCacheService.shared.isCacheBuilt(userID: userID){
                            let _ = EncryptedSearchCacheService.shared.updateCachedMessage(userID: userID, message: message)
                        }
                        completionHandler()
                    }
                case .insert:
                    self.insertSingleMessageToSearchIndex(message: message, userID: userID) {
                        // Update cache if existing
                        if EncryptedSearchCacheService.shared.isCacheBuilt(userID: userID){
                            let _ = EncryptedSearchCacheService.shared.updateCachedMessage(userID: userID, message: message)
                        }
                        completionHandler()
                    }
            case .update:
                completionHandler()
                break
            default:
                completionHandler()
                return
            }
        }
    }

    private func processEventsAfterIndexing(userID: String, completionHandler: @escaping () -> Void) {
        if self.eventsWhileIndexing!.isEmpty {
            completionHandler()
        } else {
            // Set state to refresh
            self.setESState(userID: userID, indexingState: .refresh)

            let messageAction: MessageAction = self.eventsWhileIndexing!.removeFirst()
            self.updateSearchIndex(action: messageAction.action!, message: messageAction.message, userID: userID, completionHandler: {})
            self.processEventsAfterIndexing(userID: userID) {
                print("All events processed that have been accumulated during indexing...")

                // Set state to complete when finished
                self.setESState(userID: userID, indexingState: .complete)

                // Update UI
                self.updateUIIndexingComplete()
            }
        }
    }

    func insertSingleMessageToSearchIndex(message: Message?, userID: String, completionHandler: @escaping () -> Void) {
        guard let messageToInsert = message else {
            completionHandler()
            return
        }
        // Just insert a new message if the search index exists for the user - otherwise it needs to be build first
        if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: userID) {
            let esMessage:ESMessage? = self.convertMessageToESMessage(for: messageToInsert)
            self.fetchMessageDetailForMessage(userID: userID, message: esMessage!) { [weak self] (error, messageWithDetails) in
                if error == nil {
                    self?.decryptAndExtractDataSingleMessage(for: messageWithDetails!, userID: userID) {
                        self?.processedMessages += 1
                        self?.lastMessageTimeIndexed = Int((messageWithDetails!.Time))
                        completionHandler()
                    }
                } else {
                    print("Error: Cannot fetch message details for message.")
                    completionHandler()
                }
            }
        } else {
            print("Error: No search index found for user: \(userID)")
            completionHandler()
        }
    }

    func deleteMessageFromSearchIndex(message: Message?, userID: String, completionHandler: @escaping () -> Void) {
        guard let messageToDelete = message else {
            completionHandler()
            return
        }

        // Just delete a message if the search index exists for the user - otherwise it needs to be build first
        if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: userID) {
            let _ = EncryptedSearchIndexService.shared.removeEntryFromSearchIndex(user: userID, message: messageToDelete.messageID)
            // delete message from cache if cache is built
            if EncryptedSearchCacheService.shared.isCacheBuilt(userID: userID){
                let _ = EncryptedSearchCacheService.shared.deleteCachedMessage(userID: userID, messageID: messageToDelete.messageID)
            }
            completionHandler()
        } else {
            print("Error: No search index found for user: \(userID)")
            completionHandler()
        }
    }

    func deleteSearchIndex(userID: String) {
        // Run on a seperate thread to avoid blocking the main thread
        DispatchQueue.global(qos: .userInitiated).async {
            // Update state
            self.setESState(userID: userID, indexingState: .disabled)

            // Cancle any running indexing process
            self.downloadPageQueue.isSuspended = true
            self.downloadPageQueue.cancelAllOperations()
            // Wait until all operations are finished then continue
            self.downloadPageQueue.waitUntilAllOperationsAreFinished()

            self.messageIndexingQueue.isSuspended = true
            self.messageIndexingQueue.cancelAllOperations()
            // Wait until all operations are finished then continue
            self.messageIndexingQueue.waitUntilAllOperationsAreFinished()

            // update user cached status
            userCachedStatus.isEncryptedSearchOn = false
            userCachedStatus.indexComplete = false

            // Just delete the search index if it exists
            var isIndexSuccessfullyDelete: Bool = false
            if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: userID) {
                isIndexSuccessfullyDelete = EncryptedSearchIndexService.shared.deleteSearchIndex(for: userID)
            }

            // Update some variables
            self.totalMessages = 0
            self.lastMessageTimeIndexed = 0
            self.processedMessages = 0
            self.prevProcessedMessages = 0
            self.noNewMessagesFound = 0
            self.indexingStartTime = 0
            self.slowDownIndexBuilding = false
            self.eventsWhileIndexing = []

            self.pauseIndexingDueToNetworkConnectivityIssues = false
            self.pauseIndexingDueToWiFiNotDetected = false
            self.pauseIndexingDueToOverheating = false
            self.pauseIndexingDueToLowBattery = false
            self.pauseIndexingDueToLowStorage = false
            self.numPauses = 0
            self.numInterruptions = 0
            self.estimateIndexTimeRounds = 0

            // Reset view model
            self.viewModel?.isEncryptedSearch = false
            self.viewModel?.indexComplete = false
            self.viewModel?.progressedMessages.value = 0
            self.viewModel?.currentProgress.value = 0
            self.viewModel?.isIndexingComplete.value = false
            self.viewModel?.interruptStatus.value = nil
            self.viewModel?.interruptAdvice.value = nil
            self.viewModel?.estimatedTimeRemaining.value = nil
            self.viewModel = nil
            #if !APP_EXTENSION
                self.searchViewModel = nil
            #endif

            // Invalidate timer on same thread as it has been created
            DispatchQueue.main.async {
                self.indexBuildingTimer?.invalidate()
            }

            // Stop background tasks
            #if !APP_EXTENSION
                self.endBackgroundTask()
            #endif
            if #available(iOS 13.0, *) {
                self.cancelBGProcessingTask()
                self.cancelBGAppRefreshTask()
            }

            // Unregister network monitoring
            if #available(iOS 12, *) {
                self.unRegisterForNetworkChangeNotifications()
            } else {
                // Fallback on earlier versions
            }

            // Update UI
            self.updateUIWithIndexingStatus()

            if isIndexSuccessfullyDelete {
                print("Search index for user \(userID) sucessfully deleted!")
            } else {
                print("Error when deleting the search index!")
            }
        }
    }

    private func updateMessageMetadataInSearchIndex(action: NSFetchedResultsChangeType, message: Message?, userID: String, completionHandler: @escaping () -> Void) {
        guard let messageToUpdate = message else {
            completionHandler()
            return
        }
        if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: userID){
            self.deleteMessageFromSearchIndex(message: messageToUpdate, userID: userID) {
                // Wait until delete is done - then insert updated message
                self.insertSingleMessageToSearchIndex(message: messageToUpdate, userID: userID) {
                    completionHandler()
                }
            }
        } else {
            print("Error: No search index found for user: \(userID)")
            completionHandler()
        }
    }

    private func updateUserAndAPIServices() -> Void {
        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        let user: UserManager? = usersManager.firstUser
        self.messageService = user?.messageService
        self.apiService = user?.apiService
        self.userDataSource = self.messageService?.userDataSource
    }

    // Checks the total number of messages on the backend
    private func getTotalMessages(userID: String, completionHandler: @escaping () -> Void) -> Void {
        let request = FetchMessagesByLabel(labelID: Message.Location.allmail.rawValue, endTime: 0, isUnread: false)
        self.apiService?.GET(request){ [weak self] (_, responseDict, error) in
            if error != nil {
                print("Error for api get number of messages: \(String(describing: error))")
            } else if let response = responseDict {
                self?.totalMessages = response["Total"] as! Int
            } else {
                print("Unable to parse response: \(NSError.unableToParseResponse(responseDict))")
            }
            completionHandler()
        }
    }

    func convertMessageToESMessage(for message: Message) -> ESMessage {
        let decoder = JSONDecoder()

        let jsonSenderData: Data = Data(message.sender!.utf8)
        var sender: ESSender? = ESSender(Name: "", Address: "")
        do {
            sender = try decoder.decode(ESSender.self, from: jsonSenderData)
        } catch {
            print("Error when decoding message.sender")
        }

        let senderAddress: String = sender?.Address ?? ""
        let senderName: String = sender?.Name ?? ""

        var toList: [ESSender?] = []
        var ccList: [ESSender?] = []
        var bccList: [ESSender?] = []
        let jsonToListData: Data = message.toList.data(using: .utf8)!
        let jsonCCListData: Data = message.ccList.data(using: .utf8)!
        let jsonBCCListData: Data = message.bccList.data(using: .utf8)!

        do {
            toList = try decoder.decode([ESSender].self, from: jsonToListData)
            ccList = try decoder.decode([ESSender].self, from: jsonCCListData)
            bccList = try decoder.decode([ESSender].self, from: jsonBCCListData)
        } catch {
            print("Error when decoding message.tolist, ccList or bccList")
        }

        let isReplied: Int = message.replied ? 1 : 0
        let isRepliedAll: Int = message.repliedAll ? 1 : 0
        let isForwarded: Int = message.forwarded ? 1 : 0
        var labelIDs: Set<String> = Set()
        message.labels.forEach { label in
            labelIDs.insert((label as! Label).labelID)
        }
        let externalID: String = ""
        let unread: Int = message.unRead ? 1 : 0
        let time: Double = message.time!.timeIntervalSince1970
        let isEncrypted: Int = message.isE2E ? 1 : 0

        let newESMessage = ESMessage(id: message.messageID, order: Int(truncating: message.order), conversationID: message.conversationID, subject: message.subject, unread: unread, type: Int(truncating: message.messageType), senderAddress: senderAddress, senderName: senderName, sender: sender!, toList: toList, ccList: ccList, bccList: bccList, time: time, size: Int(truncating: message.size), isEncrypted: isEncrypted, expirationTime: message.expirationTime, isReplied: isReplied, isRepliedAll: isRepliedAll, isForwarded: isForwarded, spamScore: Int(truncating: message.spamScore), addressID: message.addressID, numAttachments: Int(truncating: message.numAttachments), flags: Int(truncating: message.flags), labelIDs: labelIDs, externalID: externalID, body: message.body, header: message.header, mimeType: message.mimeType, userID: message.userID)
        newESMessage.Starred = message.starred
        return newESMessage
    }

    private func jsonStringToESMessage(jsonData: Data) throws -> ESMessage? {
        let decoder = JSONDecoder()
        let message: ESMessage? = try decoder.decode(ESMessage.self, from: jsonData)
        return message
    }

    private func parseMessageResponse(userID: String, labelID: String, isUnread:Bool, response: [String:Any], completion: ((Error?, [ESMessage]?) -> Void)?) -> Void {
        guard var messagesArray = response["Messages"] as? [[String: Any]] else {
            completion?(NSError.unableToParseResponse(response), nil)
            return
        }

        for (index, _) in messagesArray.enumerated() {
            messagesArray[index]["UserID"] = userID
        }

        do {
            var messages: [ESMessage] = []
            for (index, _) in messagesArray.enumerated() {
                let jsonDict = messagesArray[index]
                let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
                
                let message: ESMessage? = try self.jsonStringToESMessage(jsonData: jsonData)
                message?.isDetailsDownloaded = false
                messages.append(message!)
            }
            completion?(nil, messages)
        } catch {
            PMLog.D("error: \(error)")
            completion?(error, nil)
        }
    }

    private func parseMessageDetailResponse(userID: String, response: [String: Any], completion: ((Error?, ESMessage?)-> Void)?) -> Void {
        guard var msg = response["Message"] as? [String: Any] else {
            completion?(NSError.unableToParseResponse(response), nil)
            return
        }

        msg.removeValue(forKey: "Location")
        msg.removeValue(forKey: "Starred")
        msg.removeValue(forKey: "test")
        msg["UserID"] = userID

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: msg, options: [])
            let message: ESMessage? = try self.jsonStringToESMessage(jsonData: jsonData)

            message?.isDetailsDownloaded = true
            message?.Starred = false

            completion?(nil, message)
        } catch {
            PMLog.D("error when serialization: \(error)")
            completion?(error, nil)
        }
    }

    private func fetchSingleMessageFromServer(byMessageID messageID: String, completionHandler: ((Error?) -> Void)?) -> Void {
        let request = FetchMessagesByID(msgIDs: [messageID])
        self.apiService?.GET(request) { [weak self] (task, responseDict, error) in
            if error != nil {
                DispatchQueue.main.async {
                    completionHandler?(error)
                }
            } else if let response = responseDict {
                self?.messageService?.cacheService.parseMessagesResponse(labelID: Message.Location.allmail.rawValue, isUnread: false, response: response) { (errorFromParsing) in
                    if let err = errorFromParsing {
                        DispatchQueue.main.async {
                            completionHandler?(err as NSError)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completionHandler?(nil)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completionHandler?(NSError.unableToParseResponse(responseDict))
                }
            }
        }
    }

    public func fetchMessages(userID: String, byLabel labelID: String, time: Int, completionHandler: ((Error?, [ESMessage]?) -> Void)?) -> Void {
        let request = FetchMessagesByLabel(labelID: labelID, endTime: time, isUnread: false, pageSize: 150)
        self.apiService?.GET(request, priority: "u=7"){ [weak self] (task, responseDict, error) in
            if error != nil {
                DispatchQueue.main.async {
                    completionHandler?(error, nil)
                }
            } else if let response = responseDict {
                self?.parseMessageResponse(userID: userID, labelID: labelID, isUnread: false, response: response){ errorFromParsing, messages in
                    if let err = errorFromParsing {
                        DispatchQueue.main.async {
                            completionHandler?(err as NSError, nil)
                        }
                    } else {
                        //everything went well - return messages
                        DispatchQueue.main.async {
                            completionHandler?(error, messages)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completionHandler?(NSError.unableToParseResponse(responseDict), nil)
                }
            }
        }
    }

    private func fetchMessageDetailForMessage(userID: String, message: ESMessage, completionHandler: ((Error?, ESMessage?) -> Void)?){
        if message.isDetailsDownloaded! {
            DispatchQueue.main.async {
                completionHandler?(nil, message)
            }
        } else {
            self.apiService?.messageDetail(messageID: message.ID, priority: "u=7"){ [weak self] (task, responseDict, error) in
                if error != nil {
                    // 429 - too many requests - retry after some time
                    let urlResponse: HTTPURLResponse? = task?.response as? HTTPURLResponse
                    if urlResponse?.statusCode == 429 {
                        let headers: [String: Any]? = urlResponse?.allHeaderFields as? [String: Any]
                        let timeOut: String? = headers?["retry-after"] as? String
                        if let retryTime = timeOut {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(retryTime)!){
                                print("Error 429: Retry fetch after \(timeOut!) seconds for message: \(message.ID)")
                                self?.fetchMessageDetailForMessage(userID: userID, message: message){ err, msg in
                                    completionHandler?(err, msg)
                                }
                            }
                        } else {
                            // Retry-after header not present, return error
                            DispatchQueue.main.async {
                                completionHandler?(error, nil)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            completionHandler?(error, nil)
                        }
                    }
                } else if let response = responseDict {
                    self?.parseMessageDetailResponse(userID: userID, response: response) { (errorFromParsing, msg) in
                        if let err = errorFromParsing {
                            DispatchQueue.main.async {
                                completionHandler?(err as NSError, nil)
                            }
                        } else {
                            // everything went well - return messages
                            DispatchQueue.main.async {
                                completionHandler?(error, msg)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completionHandler?(NSError.unableToParseResponse(responseDict), nil)
                    }
                }
            }
        }
    }

    private func downloadAndProcessPage(userID: String, completionHandler: @escaping () -> Void) -> Void {
        let group = DispatchGroup()
        group.enter()
        self.downloadPage(userID: userID) {
            print("Processed messages: \(self.processedMessages), total messages: \(self.totalMessages)")
            group.leave()
        }

        group.notify(queue: .main) {
            if self.processedMessages >= self.totalMessages {
                completionHandler()
            } else {
                if self.noNewMessagesFound > 5 {
                    completionHandler()
                }
                let expectedESStates: [EncryptedSearchIndexState] = [.downloading, .background, .refresh]
                if expectedESStates.contains(self.getESState(userID: userID)) {
                    // Recursion
                    self.downloadAndProcessPage(userID: userID){
                        completionHandler()
                    }
                } else {
                    // Index building stopped from outside - finish up current page and return
                    completionHandler()
                }
            }
        }
    }

    private func downloadPage(userID: String, completionHandler: @escaping () -> Void){
        // Start a new thread to download page
        DispatchQueue.global(qos: .userInitiated).async {
            var op: Operation? = DownloadPageAsyncOperation(userID: userID)
            self.downloadPageQueue.addOperation(op!)
            self.downloadPageQueue.waitUntilAllOperationsAreFinished()
            // Cleanup
            self.downloadPageQueue.cancelAllOperations()
            op = nil
            completionHandler()
        }
    }

    func processPageOneByOne(forBatch messages: [ESMessage]?, userID: String, completionHandler: @escaping () -> Void) -> Void {
        guard messages!.count > 0 else {
            completionHandler()
            return
        }

        // Start a new thread to process the page
        DispatchQueue.global(qos: .userInitiated).async {
            for m in messages! {
                autoreleasepool {
                    var op: Operation? = IndexSingleMessageAsyncOperation(m, userID)
                    self.messageIndexingQueue.addOperation(op!)
                    op = nil    // Clean up
                }
            }
            self.messageIndexingQueue.waitUntilAllOperationsAreFinished()
            // Clean up
            self.messageIndexingQueue.cancelAllOperations()
            completionHandler()
        }
    }

    func getMessageDetailsForSingleMessage(for message: ESMessage, userID: String, completionHandler: @escaping (ESMessage?) -> Void) -> Void {
        if message.isDetailsDownloaded! {
            completionHandler(message)
        } else {
            self.fetchMessageDetailForMessage(userID: userID, message: message) { error, msg in
                if error == nil {
                    completionHandler(msg)
                } else {
                    print("Error when fetching message details: \(String(describing: error))")
                }
            }
        }
    }

    private func getMessage(messageID: String, completionHandler: @escaping (Message?) -> Void) -> Void {
        let fetchedResultsController = self.messageService?.fetchedMessageControllerForID(messageID)

        if let fetchedResultsController = fetchedResultsController {
            do {
                try fetchedResultsController.performFetch()
            } catch let ex as NSError {
                PMLog.D(" error: \(ex)")
            }
        }

        if let context = fetchedResultsController?.managedObjectContext{
            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                completionHandler(message)
            } else {
                completionHandler(nil)
            }
        } else {
            completionHandler(nil)
        }
    }

    func decryptBodyIfNeeded(message: ESMessage) throws -> String? {
        var keys: [Key] = []
        if let addressID = message.AddressID, let _keys = self.userDataSource?.getAllAddressKey(address_id: addressID) {
            keys = _keys
        } else {
            keys = self.userDataSource!.addressKeys
        }

        if let passphrase = self.userDataSource?.mailboxPassword, var body = self.userDataSource!.newSchema ? try message.decryptBody(keys: keys, userKeys: self.userDataSource!.userPrivateKeys, passphrase: passphrase) : try message.decryptBody(keys: keys, passphrase: passphrase) {
            if message.isPgpMime! || message.isSignedMime! {
                if let mimeMsg = MIMEMessage(string: body) {
                    if let html = mimeMsg.mainPart.part(ofType: Message.MimeType.html)?.bodyString {
                        body = html
                    } else if let text = mimeMsg.mainPart.part(ofType: Message.MimeType.plainText)?.bodyString {
                        body = text.encodeHtml()
                        body = "<html><body>\(body.ln2br())</body></html>"
                    }

                    let cidParts = mimeMsg.mainPart.partCIDs()

                    for cidPart in cidParts {
                        if var cid = cidPart.cid,
                            let rawBody = cidPart.rawBodyString {
                            cid = cid.preg_replace("<", replaceto: "")
                            cid = cid.preg_replace(">", replaceto: "")
                            let attType = "image/jpg" //cidPart.headers[.contentType]?.body ?? "image/jpg;name=\"unknow.jpg\""
                            let encode = cidPart.headers[.contentTransferEncoding]?.body ?? "base64"
                            body = body.stringBySetupInlineImage("src=\"cid:\(cid)\"", to: "src=\"data:\(attType);\(encode),\(rawBody)\"")
                        }
                    }
                    /// cache the decrypted inline attachments
                    let atts = mimeMsg.mainPart.findAtts()
                    var inlineAtts = [AttachmentInline]()
                    for att in atts {
                        if let filename = att.getFilename()?.clear {
                            let data = att.data
                            let path = FileManager.default.attachmentDirectory.appendingPathComponent(filename)
                            do {
                                try data.write(to: path, options: [.atomic])
                            } catch {
                                continue
                            }
                            inlineAtts.append(AttachmentInline(fnam: filename, size: data.count, mime: filename.mimeType(), path: path))
                        }
                    }
                    //message.tempAtts = inlineAtts
                    //TODO
                } else { //backup plan
                    body = body.multipartGetHtmlContent ()
                }
            } else if message.isPgpInline {
                if message.isPlainText {
                    let head = "<html><head></head><body>"
                    // The plain text draft from android and web doesn't have
                    // the head, so if the draft contains head
                    // It means the draft already encoded
                    if !body.hasPrefix(head) {
                        body = body.encodeHtml()
                        body = body.ln2br()
                    }
                    return body
                } else if message.isMultipartMixed {
                    ///TODO:: clean up later
                    if let mimeMsg = MIMEMessage(string: body) {
                        if let html = mimeMsg.mainPart.part(ofType: Message.MimeType.html)?.bodyString {
                            body = html
                        } else if let text = mimeMsg.mainPart.part(ofType: Message.MimeType.plainText)?.bodyString {
                            body = text.encodeHtml()
                            body = "<html><body>\(body.ln2br())</body></html>"
                        }

                        if let cidPart = mimeMsg.mainPart.partCID(),
                            var cid = cidPart.cid,
                            let rawBody = cidPart.rawBodyString {
                            cid = cid.preg_replace("<", replaceto: "")
                            cid = cid.preg_replace(">", replaceto: "")
                            let attType = "image/jpg" //cidPart.headers[.contentType]?.body ?? "image/jpg;name=\"unknow.jpg\""
                            let encode = cidPart.headers[.contentTransferEncoding]?.body ?? "base64"
                            body = body.stringBySetupInlineImage("src=\"cid:\(cid)\"", to: "src=\"data:\(attType);\(encode),\(rawBody)\"")
                        }
                        /// cache the decrypted inline attachments
                        let atts = mimeMsg.mainPart.findAtts()
                        var inlineAtts = [AttachmentInline]()
                        for att in atts {
                            if let filename = att.getFilename()?.clear {
                                let data = att.data
                                let path = FileManager.default.attachmentDirectory.appendingPathComponent(filename)
                                do {
                                    try data.write(to: path, options: [.atomic])
                                } catch {
                                    continue
                                }
                                inlineAtts.append(AttachmentInline(fnam: filename, size: data.count, mime: filename.mimeType(), path: path))
                            }
                        }
                        //message.tempAtts = inlineAtts
                        //TODO
                    } else { //backup plan
                        body = body.multipartGetHtmlContent ()
                    }
                } else {
                    return body
                }
            }
            if message.isPlainText {
                if message.draft {
                    return body
                } else {
                    body = body.encodeHtml()
                    return body.ln2br()
                }
            }
            return body
        }

        Analytics.shared.error(message: .decryptedMessageBodyFailed,
                               error: "passphrase is nil")
        return message.Body
    }

    func decryptAndExtractDataSingleMessage(for message: ESMessage, userID: String,  completionHandler: @escaping () -> Void) -> Void {
        var body: String? = ""
        var decryptionFailed: Bool = true
        do {
            body = try self.decryptBodyIfNeeded(message: message)
            decryptionFailed = false
        } catch {
            print("Error when decrypting messages: \(error).")
        }

        let emailContent: String = EmailparserExtractData(body!, true)
        let encryptedContent: EncryptedsearchEncryptedMessageContent? = self.createEncryptedContent(message: message, cleanedBody: emailContent, userID: userID)

        // add message to search index db
        self.addMessageKewordsToSearchIndex(userID, message, encryptedContent, decryptionFailed)
        completionHandler()
    }

    func createEncryptedContent(message: ESMessage, cleanedBody: String, userID: String) -> EncryptedsearchEncryptedMessageContent? {
        let sender: EncryptedsearchRecipient? = EncryptedsearchRecipient(message.Sender.Name, email: message.Sender.Address)
        let toList: EncryptedsearchRecipientList = EncryptedsearchRecipientList()
        message.ToList.forEach { s in
            let r: EncryptedsearchRecipient? = EncryptedsearchRecipient(s!.Name, email: s!.Address)
            toList.add(r)
        }
        let ccList: EncryptedsearchRecipientList = EncryptedsearchRecipientList()
        message.CCList.forEach { s in
            let r: EncryptedsearchRecipient? = EncryptedsearchRecipient(s!.Name, email: s!.Address)
            ccList.add(r)
        }
        let bccList: EncryptedsearchRecipientList = EncryptedsearchRecipientList()
        message.BCCList.forEach { s in
            let r: EncryptedsearchRecipient? = EncryptedsearchRecipient(s!.Name, email: s!.Address)
            bccList.add(r)
        }
        let decryptedMessageContent: EncryptedsearchDecryptedMessageContent? = EncryptedsearchNewDecryptedMessageContent(message.Subject, sender, cleanedBody, toList, ccList, bccList)

        let cipher: EncryptedsearchAESGCMCipher = self.getCipher(userID: userID)
        var encryptedMessageContent: EncryptedsearchEncryptedMessageContent? = nil

        do {
            encryptedMessageContent = try cipher.encrypt(decryptedMessageContent)
        } catch {
            print(error)
        }

        return encryptedMessageContent
    }

    // TODO make user dependent
    private func getCipher(userID: String) -> EncryptedsearchAESGCMCipher {
        if self.cipherForSearchIndex == nil {   //TODO we need to regenerate the cipher if there is a switch between users
            let key: Data? = self.retrieveSearchIndexKey(userID: userID)
            //TODO error when key is nil
            let cipher: EncryptedsearchAESGCMCipher = EncryptedsearchAESGCMCipher(key!)!
            self.cipherForSearchIndex = cipher
        }
        return self.cipherForSearchIndex!
    }

    private func generateSearchIndexKey(userID: String) -> Data? {
        let keylen: Int = 32
        var error: NSError?
        let bytes = CryptoRandomToken(keylen, &error)
        self.storeSearchIndexKey(key: bytes, userID: userID)
        return bytes
    }

    // TODO do we additionally want to encrypt the key?
    private func storeSearchIndexKey(key: Data?, userID: String) {
        // Add search index key to KeyChain
        KeychainWrapper.keychain.set(key!, forKey: "searchIndexKey_" + userID)
    }

    private func retrieveSearchIndexKey(userID: String) -> Data? {
        var key: Data? = KeychainWrapper.keychain.data(forKey: "searchIndexKey_" + userID)
        // Check if user already has an key - otherwise generate one
        if key == nil {
            key = self.generateSearchIndexKey(userID: userID)
        }
        return key
    }

    func addMessageKewordsToSearchIndex(_ userID: String, _ message: ESMessage, _ encryptedContent: EncryptedsearchEncryptedMessageContent?, _ decryptionFailed: Bool) -> Void {
        let location: Int = Int(Message.Location.allmail.rawValue)!
        let time: Int = Int(message.Time)
        let order: Int = message.Order

        let ciphertext: String? = encryptedContent?.ciphertext
        let encryptedContentSize: Int = ciphertext?.count ?? 0

        let _: Int64? = EncryptedSearchIndexService.shared.addNewEntryToSearchIndex(for: userID, messageID: message.ID, time: time, labelIDs: message.LabelIDs, isStarred: message.Starred!, unread: (message.Unread != 0), location: location, order: order, hasBody: decryptionFailed, decryptionFailed: decryptionFailed, encryptionIV: encryptedContent?.iv, encryptedContent: ciphertext, encryptedContentFile: "", encryptedContentSize: encryptedContentSize)
    }

    // MARK: - Search Functions
    #if !APP_EXTENSION
    func search(userID: String, query: String, page: Int, searchViewModel: SearchViewModel, completion: ((NSError?, Int?) -> Void)?) {
        print("encrypted search on client side!")
        print("Query: ", query)
        print("Page: ", page)

        if query == "" {
            completion?(nil, nil) //There are no results for an empty search query
        }

        // Update API services to current user
        self.updateUserAndAPIServices()

        // Set the viewmodel
        self.searchViewModel = searchViewModel

        // Check if this is the first search
        self.isFirstSearch = self.hasSearchedBefore(userID: userID)

        // Start timing search
        let startSearch: Double = CFAbsoluteTimeGetCurrent()
        DispatchQueue.main.async {
            self.slowSearchTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.reactToSlowSearch), userInfo: nil, repeats: false)
        }

        // Initialize searcher, cipher
        let searcher: EncryptedsearchSimpleSearcher = self.getSearcher(query: query)
        let cipher: EncryptedsearchAESGCMCipher = self.getCipher(userID: userID)

        // Build the cache
        let cache: EncryptedsearchCache? = self.getCache(cipher: cipher, userID: userID)
        print("Number of messages in cache: \(cache!.getLength())")

        // Create new search state if not already existing
        if self.searchState == nil {
            self.searchState = EncryptedsearchSearchState()
        }

        // Do cache search first
        let numberOfResultsFoundByCachedSearch: Int = self.doCachedSearch(searcher: searcher, cache: cache!, searchState: &self.searchState, searchViewModel: searchViewModel, page: page)
        print("Results found by cache search: ", numberOfResultsFoundByCachedSearch)

        // Do index search next - unless search is already completed
        var numberOfResultsFoundByIndexSearch: Int = 0
        if !self.searchState!.isComplete {
            numberOfResultsFoundByIndexSearch = self.doIndexSearch(searcher: searcher, cipher: cipher, searchState: &self.searchState, resultsFoundInCache: numberOfResultsFoundByCachedSearch, userID: userID, searchViewModel: searchViewModel, page: page)
        }
        print("Results found by index search: ", numberOfResultsFoundByIndexSearch)

        // Do timings for entire search procedure
        let endSearch: Double = CFAbsoluteTimeGetCurrent()
        print("Search finished. Time: \(endSearch-startSearch)")

        // Search finished - clean up
        self.isSearching = false
        // Invalidate timer on same thread as it has been created
        DispatchQueue.main.async {
            self.slowSearchTimer?.invalidate()
        }

        // Send some search metrics
        self.sendSearchMetrics(searchTime: endSearch-startSearch, cache: cache, userID: userID)

        // Call completion handler
        completion?(nil, numberOfResultsFoundByCachedSearch + numberOfResultsFoundByIndexSearch)
    }
    #endif

    #if !APP_EXTENSION
    @objc private func reactToSlowSearch() -> Void {
        self.searchViewModel?.slowSearch = true
    }
    #endif

    private func hasSearchedBefore(userID: String) -> Bool {
        let cachedUserID: String? = EncryptedSearchCacheService.shared.getLastCacheUserID()
        if let cachedUserID = cachedUserID {
            if cachedUserID == userID {
                return true
            }
        }
        return false
    }

    func clearSearchState() {
        self.searchState = nil
    }

    private func getSearcher(query: String) -> EncryptedsearchSimpleSearcher {
        let contextSize: CLong = 100 // The max size of the content showed in the preview
        let keywords: EncryptedsearchStringList? = self.createEncryptedSearchStringList(query: query)   // Split query into individual keywords
        return EncryptedsearchSimpleSearcher(keywords, contextSize: contextSize)!
    }

    private func createEncryptedSearchStringList(query: String) -> EncryptedsearchStringList {
        let result: EncryptedsearchStringList? = EncryptedsearchStringList()
        let searchQueryArray: [String] = query.components(separatedBy: " ")
        searchQueryArray.forEach { q in
            result?.add(q)
        }
        return result!
    }

    private func getCache(cipher: EncryptedsearchAESGCMCipher, userID: String) -> EncryptedsearchCache {
        let dbParams: EncryptedsearchDBParams = EncryptedSearchIndexService.shared.getDBParams(userID)
        let cache: EncryptedsearchCache = EncryptedSearchCacheService.shared.buildCacheForUser(userId: userID, dbParams: dbParams, cipher: cipher)
        return cache
    }

    private func extractSearchResults(_ searchResults: EncryptedsearchResultList, _ page: Int, completionHandler: @escaping ([Message]?) -> Void) -> Void {
        if searchResults.length() == 0 {
            completionHandler([])
        } else {
            let pageSize: Int = 50
            let numberOfPages: Int = Int(ceil(Double(searchResults.length()/pageSize)))
            if page > numberOfPages {
                completionHandler([])
            } else {
                let startIndex: Int = page * pageSize
                var endIndex: Int = startIndex + (pageSize-1)
                if page == numberOfPages {  //final page
                    endIndex = startIndex + (searchResults.length() % pageSize)-1
                }

                var messages: [Message] = []
                let group = DispatchGroup()

                for index in startIndex...endIndex {
                    group.enter()
                    let result: EncryptedsearchSearchResult? = searchResults.get(index)
                    let id: String = (result?.message!.id_)!
                    self.getMessage(messageID: id) { message in
                        if message == nil {
                            self.fetchSingleMessageFromServer(byMessageID: id) { [weak self] (error) in
                                if error != nil {
                                    print("Error when fetching message from server: \(String(describing: error))")
                                    group.leave()
                                } else {
                                    self?.getMessage(messageID: id) { msg in
                                        messages.append(msg!)
                                        group.leave()
                                    }
                                }
                            }
                        } else {
                            messages.append(message!)
                            group.leave()
                        }
                    }
                }

                group.notify(queue: .main){
                    completionHandler(messages)
                }
            }
        }
    }

    #if !APP_EXTENSION
    private func doIndexSearch(searcher: EncryptedsearchSimpleSearcher, cipher: EncryptedsearchAESGCMCipher, searchState: inout EncryptedsearchSearchState?, resultsFoundInCache:Int, userID: String, searchViewModel: SearchViewModel, page: Int) -> Int {
        let startIndexSearch: Double = CFAbsoluteTimeGetCurrent()
        let index: EncryptedsearchIndex = self.getIndex(userID: userID)
        do {
            try index.openDBConnection()
        } catch {
            print("Error when opening DB connection: \(error)")
        }

        var batchCount: Int = 0
        let searchFetchPageSize: Int = 150
        var resultsFound: Int = resultsFoundInCache
        print("Start index search...")
        while !searchState!.isComplete && resultsFound < searchFetchPageSize {
            let startBatchSearch: Double = CFAbsoluteTimeGetCurrent()

            let searchBatchHeapPercent: Double = 0.1 // Percentage of heap that can be used to load messages from the index
            let searchMsgSize: Double = 14000 // An estimation of how many bytes take a search message in memory
            let batchSize: Int = Int((getTotalAvailableMemory() * searchBatchHeapPercent)/searchMsgSize)

            var newResults: EncryptedsearchResultList? = EncryptedsearchResultList()
            do {
                newResults = try index.searchNewBatch(fromDB: searcher, cipher: cipher, state: searchState, batchSize: batchSize)
                resultsFound += newResults!.length()
            } catch {
                print("Error while searching... ", error)
            }

            // If some results are found - disable timer for slow search
            if resultsFound > 0 {
                DispatchQueue.main.async {
                    self.slowSearchTimer?.invalidate()
                    self.slowSearchTimer = nil
                    // start a new timer if search continues
                    self.slowSearchTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.reactToSlowSearch), userInfo: nil, repeats: false)
                }
            }

            // Visualize intermediate results
            self.publishIntermediateResults(searchResults: newResults, searchViewModel: searchViewModel, currentPage: page)

            let endBatchSearch: Double = CFAbsoluteTimeGetCurrent()
            print("Batch \(batchCount) search. time: \(endBatchSearch-startBatchSearch), with batchsize: \(batchSize)")
            batchCount += 1
        }

        do {
            try index.closeDBConnection()
        } catch {
            print("Error while closing database Connection: \(error)")
        }

        let endIndexSearch: Double = CFAbsoluteTimeGetCurrent()
        print("Index search finished. Time: \(endIndexSearch-startIndexSearch)")

        return resultsFound
    }
    #endif

    private func getIndex(userID: String) -> EncryptedsearchIndex {
        let dbParams: EncryptedsearchDBParams = EncryptedSearchIndexService.shared.getDBParams(userID)
        let index: EncryptedsearchIndex = EncryptedsearchIndex(dbParams)!
        return index
    }

    #if !APP_EXTENSION
    private func doCachedSearch(searcher: EncryptedsearchSimpleSearcher, cache: EncryptedsearchCache, searchState: inout EncryptedsearchSearchState?, searchViewModel: SearchViewModel, page: Int) -> Int {
        var found: Int = 0
        let searchResultPageSize: Int = 50
        let batchSize: Int = Int(EncryptedSearchCacheService.shared.batchSize)
        var batchCount: Int = 0
        while !searchState!.cachedSearchDone && found < searchResultPageSize {
            let startCacheSearch: Double = CFAbsoluteTimeGetCurrent()

            var newResults: EncryptedsearchResultList? = EncryptedsearchResultList()
            do {
                newResults = try cache.search(searchState, searcher: searcher, batchSize: batchSize)
            } catch {
                print("Error when doing cache search \(error)")
            }
            found += (newResults?.length())!

            // If some results are found - disable timer for slow search
            if found > 0 {
                DispatchQueue.main.async {
                    self.slowSearchTimer?.invalidate()
                    self.slowSearchTimer = nil
                    // start a new timer if search continues
                    self.slowSearchTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.reactToSlowSearch), userInfo: nil, repeats: false)
                }
            }

            // Visualize intermediate results
            self.publishIntermediateResults(searchResults: newResults, searchViewModel: searchViewModel, currentPage: page)

            let endCacheSearch: Double = CFAbsoluteTimeGetCurrent()
            print("Cache batch \(batchCount) search: \(endCacheSearch-startCacheSearch) seconds, batchSize: \(batchSize)")
            batchCount += 1
        }
        return found
    }
    #endif

    #if !APP_EXTENSION
    private func publishIntermediateResults(searchResults: EncryptedsearchResultList?, searchViewModel: SearchViewModel, currentPage: Int){
        self.extractSearchResults(searchResults!, 0) { messageBatch in
            let messages: [Message.ObjectIDContainer]? = messageBatch!.map(ObjectBox.init)
            searchViewModel.displayIntermediateSearchResults(messageBoxes: messages, currentPage: currentPage)
        }
    }
    #endif

    // MARK: - Background Tasks
    //pre-ios 13 background tasks
    @available(iOSApplicationExtension, unavailable, message: "This method is NS_EXTENSION_UNAVAILABLE")
    public func continueIndexingInBackground(userID: String) {
        self.speedUpIndexing(userID: userID)
        self.backgroundTask = UIApplication.shared.beginBackgroundTask(){ [weak self] in
            self?.endBackgroundTask()
        }
    }

    //pre-ios 13 background tasks
    @available(iOSApplicationExtension, unavailable, message: "This method is NS_EXTENSION_UNAVAILABLE")
    public func endBackgroundTask() {
        if self.backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }
    }

    // BG Processing Task functions
    @available(iOS 13.0, *)
    @available(iOSApplicationExtension, unavailable, message: "This method is NS_EXTENSION_UNAVAILABLE")
    func registerBGProcessingTask() {
        let registeredSuccessful = BGTaskScheduler.shared.register(forTaskWithIdentifier: "ch.protonmail.protonmail.encryptedsearch_indexbuilding", using: nil) { bgTask in
            self.bgProcessingTask(task: bgTask as! BGProcessingTask)
        }
        if !registeredSuccessful {
            print("Error when registering background processing task!")
        }
    }

    @available(iOS 13.0, *)
    private func cancelBGProcessingTask() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "ch.protonmail.protonmail.encryptedsearch_indexbuilding")
    }

    @available(iOS 13.0, *)
    private func scheduleNewBGProcessingTask() {
        let request = BGProcessingTaskRequest(identifier: "ch.protonmail.protonmail.encryptedsearch_indexbuilding")
        request.requiresNetworkConnectivity = true

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Error when scheduling index building background task: \(error)")
        }
    }

    @available(iOS 13.0, *)
    private func bgProcessingTask(task: BGProcessingTask) {
        // Check if user is known
        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        guard let userID = usersManager.firstUser?.userInfo.userId else {
            print("Error when running bg processing task. User unknown!")
            task.setTaskCompleted(success: true)
            return
        }

        // Provide an expiration handler in case indexing is not finished in time
        task.expirationHandler = {
            // Schedule a new background processing task if index building is not finished
            self.scheduleNewBGProcessingTask()

            self.setESState(userID: userID, indexingState: .backgroundStopped)

            // Slow down indexing again - will be speed up if user switches to ES screen
            self.slowDownIndexing(userID: userID)
        }

        // Index is build in foreground - no need for a background task
        if self.getESState(userID: userID) == .downloading {
            task.setTaskCompleted(success: true)
        } else {
            // Check if indexing is in progress
            let expectedESStates: [EncryptedSearchIndexState] = [.undetermined, .disabled, .complete, .partial]
            if expectedESStates.contains(self.getESState(userID: userID)) {
                task.setTaskCompleted(success: true)
                return
            }

            self.setESState(userID: userID, indexingState: .background)

            // in the background we can index with full speed
            self.speedUpIndexing(userID: userID)

            // Start indexing in background
            self.pauseAndResumeIndexingDueToInterruption(isPause: false, userID: userID)
        }
    }

    @available(iOS 13.0, *)
    @available(iOSApplicationExtension, unavailable, message: "This method is NS_EXTENSION_UNAVAILABLE")
    func registerBGAppRefreshTask() {
        let registeredSuccessful = BGTaskScheduler.shared.register(forTaskWithIdentifier: "ch.protonmail.protonmail.encryptedsearch_apprefresh", using: nil) { bgTask in
            self.appRefreshTask(task: bgTask as! BGAppRefreshTask)
        }
        if !registeredSuccessful {
            print("Error when registering background app refresh task!")
        }
    }

    @available(iOS 13.0, *)
    private func cancelBGAppRefreshTask() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "ch.protonmail.protonmail.encryptedsearch_apprefresh")
    }

    @available(iOS 13.0, *)
    private func scheduleNewAppRefreshTask(){
        let request = BGAppRefreshTaskRequest(identifier: "ch.protonmail.protonmail.encryptedsearch_apprefresh")

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Unable to sumit app refresh task: \(error.localizedDescription)")
        }
    }

    @available(iOS 13.0, *)
    private func appRefreshTask(task: BGAppRefreshTask) {
        // Check if user is known
        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        guard let userID = usersManager.firstUser?.userInfo.userId else {
            print("Error when running bg apprefresh task. User unknown!")
            task.setTaskCompleted(success: true)
            return
        }

        // Provide an expiration handler in case indexing is not finished in time
        task.expirationHandler = {
            // Schedule a new background app refresh task
            self.scheduleNewAppRefreshTask()

            self.setESState(userID: userID, indexingState: .backgroundStopped)

            // Slow down indexing again - will be speed up if user switches to ES screen
            self.slowDownIndexing(userID: userID)
        }

        // Index is build in foreground - no need for a background task
        if self.getESState(userID: userID) == .downloading {
            task.setTaskCompleted(success: true)
        } else {
            // Check if indexing is in progress
            let expectedESStates: [EncryptedSearchIndexState] = [.undetermined, .disabled, .complete, .partial]
            if expectedESStates.contains(self.getESState(userID: userID)) {
                task.setTaskCompleted(success: true)
                return
            }

            self.setESState(userID: userID, indexingState: .background)

            // in the background we can index with full speed
            self.speedUpIndexing(userID: userID)

            // Start indexing in background
            self.pauseAndResumeIndexingDueToInterruption(isPause: false, userID: userID)
        }
    }

    // MARK: - Analytics/Metrics Functions
    enum Metrics {
        case index
        case search
    }

    private func sendIndexingMetrics(indexTime: Double, userID: String) {
        let indexSize: Int64? = EncryptedSearchIndexService.shared.getSizeOfSearchIndex(for: userID).asInt64 ?? 0
        let numMessagesIndexed = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID)
        let indexingMetricsData: [String:Any] = ["numMessagesIndexed" : numMessagesIndexed,
                                                 "indexSize"          : indexSize!,
                                                 "indexTime"          : indexTime,
                                                 "originalEstimate"   : self.initialIndexingEstimate,
                                                 "numPauses"          : self.numPauses,
                                                 "numInterruptions"   : self.numInterruptions,
                                                 "isRefreshed"        : self.isRefreshed]
        self.sendMetrics(metric: Metrics.index, data: indexingMetricsData){_,_,error in
            if error != nil {
                print("Error when sending indexing metrics: \(String(describing: error))")
            }
        }
    }
    
    private func sendSearchMetrics(searchTime: Double, cache: EncryptedsearchCache?, userID: String){
        let indexSize: Int64? = EncryptedSearchIndexService.shared.getSizeOfSearchIndex(for: userID).asInt64 ?? 0
        let numMessagesIndexed = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID)
        let cacheSize: Int64? = cache?.getSize() ?? 0
        let isCacheLimited: Bool = cache?.isPartial() ?? false
        let searchMetricsData: [String:Any] = ["numMessagesIndexed" : numMessagesIndexed,
                                               "indexSize"          : indexSize!,
                                               "cacheSize"          : cacheSize!,
                                               "isFirstSearch"      : self.isFirstSearch,
                                               "isCacheLimited"     : isCacheLimited,
                                               "searchTime"         : Int(searchTime*100)]   // Search time is expressed in milliseconds instead of seconds
        self.sendMetrics(metric: Metrics.search, data: searchMetricsData){_,_,error in
            if error != nil {
                print("Error when sending search metrics: \(String(describing: error))")
            }
        }
    }

    private func sendMetrics(metric: Metrics, data: [String: Any], completion: @escaping CompletionBlock) {
        var title: String = ""
        switch metric {
        case .index:
            title = "index"
        case .search:
            title = "search"
        }

        if metric == .search {
            let delay: Int = Int.random(in: 1...180) // add a random delay between 1 second and 3 minutes
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay)) {
                self.apiService?.metrics(log: "encrypted_search", title: title, data: data, completion: completion)
            }
        } else {
            self.apiService?.metrics(log: "encrypted_search", title: title, data: data, completion: completion)
        }
    }

    // MARK: - Helper Functions
    func setESState(userID: String, indexingState: EncryptedSearchIndexState) {
        self.viewModel?.indexStatus = indexingState.rawValue
        print("ENCRYPTEDSEARCH-STATE: \(indexingState)")

        // TODO check for nil

        let stateValue: String = userID + "-" + String(indexingState.rawValue)
        let stateKey: String = "ES-INDEXSTATE-" + userID

        KeychainWrapper.keychain.set(stateValue, forKey: stateKey)
    }

    func getESState(userID: String) -> EncryptedSearchIndexState {
        // TODO check userID for correct format?

        let stateKey: String = "ES-INDEXSTATE-" + userID
        var indexingState: EncryptedSearchIndexState = .undetermined
        if let stateValue = KeychainWrapper.keychain.string(forKey: stateKey) {
            let index = stateValue.index(stateValue.endIndex, offsetBy: -1)
            let state: String = String(stateValue.suffix(from: index))
            indexingState = EncryptedSearchIndexState(rawValue: Int(state) ?? 0) ?? .undetermined
        } else {
            print("Error: no ES state found for userID: \(userID)")
            indexingState = .disabled
        }
        return indexingState
    }

    // Called to slow down indexing - so that a user can normally use the app
    func slowDownIndexing(userID: String) {
        let expectedESStates: [EncryptedSearchIndexState] = [.downloading, .background, .refresh]
        if expectedESStates.contains(self.getESState(userID: userID)) {
            if self.slowDownIndexBuilding == false {
                self.messageIndexingQueue.maxConcurrentOperationCount = 10
                self.slowDownIndexBuilding = true
            }
        }
    }

    // speed up indexing again when in foreground
    func speedUpIndexing(userID: String) {
        let expectedESStates: [EncryptedSearchIndexState] = [.downloading, .background, .refresh]
        if expectedESStates.contains(self.getESState(userID: userID)) {
            if self.slowDownIndexBuilding {
                self.messageIndexingQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
                self.slowDownIndexBuilding = false
            }
        }
    }

    private func checkIfEnoughStorage() {
        // Check if user is known
        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        guard let userID = usersManager.firstUser?.userInfo.userId else {
            print("Error when checking the storage. User unknown!")
            return
        }

        // Check if indexing is in progress
        let expectedESStates: [EncryptedSearchIndexState] = [.undetermined, .disabled, .complete, .partial]
        if expectedESStates.contains(self.getESState(userID: userID)) {
            return
        }

        let remainingStorageSpace = self.getCurrentlyAvailableAppMemory()
        print("Current storage space: \(remainingStorageSpace)")
        if remainingStorageSpace < 100 {    // TODO is 100 correct?
            self.pauseIndexingDueToLowStorage = true
            self.pauseAndResumeIndexingDueToInterruption(isPause: true, userID: userID)
        }
    }

    private func checkIfStorageLimitIsExceeded() {
        // Check if user is known
        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        let userID: String? = usersManager.firstUser?.userInfo.userId
        guard let userID = userID else {
            print("Error when responding to low power mode. User unknown!")
            return
        }

        // Check if indexing is in progress
        let expectedESStates: [EncryptedSearchIndexState] = [.undetermined, .disabled, .complete, .partial]
        if expectedESStates.contains(self.getESState(userID: userID)) {
            return
        }

        let sizeOfSearchIndex: Int64? = EncryptedSearchIndexService.shared.getSizeOfSearchIndex(for: userID).asInt64
        if sizeOfSearchIndex! > userCachedStatus.storageLimit {
            // Cancle any running indexing process
            self.downloadPageQueue.cancelAllOperations()
            self.messageIndexingQueue.cancelAllOperations()

            // Set state to partial
            self.setESState(userID: userID, indexingState: .partial)

            // clean up indexing
            self.cleanUpAfterIndexing(userID: userID)
        }
    }

    private func estimateIndexingTime() -> (estimatedTime: String?, time: Double, currentProgress: Int){
        var estimatedTime: Double = 0
        var currentProgress: Int = 0
        let currentTime: Double = CFAbsoluteTimeGetCurrent()

        if self.totalMessages != 0 && currentTime != self.indexingStartTime && self.processedMessages != self.prevProcessedMessages {
            let remainingMessages: Double = Double(self.totalMessages - self.processedMessages)
            let timeDifference: Double = currentTime-self.indexingStartTime
            let processedMessageDifference: Double = Double(self.processedMessages-self.prevProcessedMessages)

            // Estimate time (in seconds)
            estimatedTime = ceil((timeDifference/processedMessageDifference)*remainingMessages)
            // Estimate progress (in percent)
            currentProgress = Int(ceil((Double(self.processedMessages)/Double(self.totalMessages))*100))
        }

        return (self.timeToDate(time: estimatedTime), estimatedTime, currentProgress)
    }

    @objc private func updateRemainingIndexingTime() {
        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        if let userID = usersManager.firstUser?.userInfo.userId {
            // Stop timer if indexing is finished or paused
            let expectedESStates: [EncryptedSearchIndexState] = [.complete, .partial, .paused, .undetermined, .disabled]
            if expectedESStates.contains(self.getESState(userID: userID)) {
                // Invalidate timer on same thread as it has been created
                DispatchQueue.main.async {
                    self.indexBuildingTimer?.invalidate()
                }
            }

            if self.getESState(userID: userID) == .downloading {
                DispatchQueue.global().async {
                    let result = self.estimateIndexingTime()

                    if self.isFirstIndexingTimeEstimate {
                        self.initialIndexingEstimate = Int(result.time)  // provide the initial estimate in seconds
                        self.isFirstIndexingTimeEstimate = false
                    }

                    // Update UI
                    if result.currentProgress != 0 {
                        self.viewModel?.currentProgress.value = result.currentProgress
                    }
                    if self.estimateIndexTimeRounds >= 3 {   // Just show an time estimate after a few rounds (to have a more stable estimate)
                        self.viewModel?.estimatedTimeRemaining.value = result.estimatedTime
                    } else {
                        self.estimateIndexTimeRounds += 1
                        self.viewModel?.estimatedTimeRemaining.value = nil
                    }
                    print("Remaining indexing time (seconds): \(String(describing: result.time))")
                    print("Current progress: \(result.currentProgress)")
                    print("Indexing rate: \(self.messageIndexingQueue.maxConcurrentOperationCount)")
                }
            }

            // Check if there is still enought storage left
            self.checkIfEnoughStorage()
            self.checkIfStorageLimitIsExceeded()

            // print state for debugging
            print("ES-DEBUG: \(self.getESState(userID: userID))")
        }
    }

    private func timeToDate(time: Double) -> String? {
        if time < 60 {
            return LocalString._encrypted_search_estimated_time_less_than_a_minute
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .full    // spells out units
        formatter.collapsesLargestUnit = true
        formatter.includesTimeRemainingPhrase = true    // adds remaining in the end
        formatter.zeroFormattingBehavior = .dropLeading // drops leading units that are zero

        return formatter.string(from: time)
    }

    private func registerForPowerStateChangeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(responseToLowPowerMode(_:)), name: NSNotification.Name.NSProcessInfoPowerStateDidChange, object: nil)
    }

    @available(iOS 12, *)
    private func registerForNetworkChangeNotifications() {
        if self.networkMonitor == nil {
            self.networkMonitor = NWPathMonitor()
        }
        self.networkMonitor?.pathUpdateHandler = { path in
            self.responseToNetworkChanges(path: path)
        }
        let networkMonitoringQueue = DispatchQueue(label: "NetworkMonitor")
        self.networkMonitor?.start(queue: networkMonitoringQueue)
        print("ES-NETWORK: monitoring enabled")

        //self.reachability = try! Reachability()
        /*let reachability = Reachability()!
        NotificationCenter.default.addObserver(self, selector: #selector(responseToNetworkChanges(_:)), name: NSNotification.Name.reachabilityChanged, object: self.reachability)
        do {
            try self.reachability?.startNotifier()
        } catch {
            print("Error when starting network monitoring notifier: \(error)")
        }*/
    }

    @available(iOS 12, *)
    private func unRegisterForNetworkChangeNotifications() {
        self.networkMonitor?.cancel()
        self.networkMonitor = nil
    }

    @available(iOS 12, *)
    private func responseToNetworkChanges(path: NWPath) {
        // Check if user is known
        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        guard let userID = usersManager.firstUser?.userInfo.userId else {
            print("Error when responding to network changes. User unknown!")
            return
        }

        // Check if indexing is in progress
        let expectedESStates: [EncryptedSearchIndexState] = [.undetermined, .disabled, .complete, .partial]
        if expectedESStates.contains(self.getESState(userID: userID)) {
            return
        }

        if path.status == .satisfied {
            // Either cellular or a WiFi hotspot
            if path.isExpensive {
                print("ES-NETWORK cellular")

                // If indexing with mobile data is enabled
                if userCachedStatus.downloadViaMobileData {
                    print("ES-NETWORK cellular - mobile data on")

                    // Update some state variables
                    self.pauseIndexingDueToWiFiNotDetected = false
                    self.pauseIndexingDueToNetworkConnectivityIssues = false

                    // If indexing was paused - resume indexing
                    if self.getESState(userID: userID) == .paused {
                        self.pauseAndResumeIndexingDueToInterruption(isPause: false, userID: userID)
                    }
                } else {
                    // Mobile data available - however user switched indexing on mobile data off
                    print("ES-NETWORK cellular - mobile data off")

                    // Update some state variables
                    self.pauseIndexingDueToWiFiNotDetected = true
                    self.pauseIndexingDueToNetworkConnectivityIssues = false

                    // If downloading - Pause indexing
                    if self.getESState(userID: userID) == .downloading {
                        self.pauseAndResumeIndexingDueToInterruption(isPause: true, userID: userID)
                    }
                }
            } else {    // WiFi available
                print("ES-NETWORK wifi")

                // Update some state variables
                self.pauseIndexingDueToWiFiNotDetected = false
                self.pauseIndexingDueToNetworkConnectivityIssues = false

                // If indexing was paused - continue on wifi again
                if self.getESState(userID: userID) == .paused {
                    self.pauseAndResumeIndexingDueToInterruption(isPause: false, userID: userID)
                }
            }
        } else {
            print("ES-NETWORK No Internet available")

            // Update state variable
            self.pauseIndexingDueToNetworkConnectivityIssues = true
            self.pauseIndexingDueToWiFiNotDetected = true

            // Pause indexing
            if self.getESState(userID: userID) == .downloading {
                self.pauseAndResumeIndexingDueToInterruption(isPause: true, userID: userID)
            }
        }

        // Update UI
        self.updateUIWithIndexingStatus()
    }

    @available(iOS 12, *)
    func checkIfNetworkAvailable() {
        // Run on a separate thread so that UI is not blocked
        DispatchQueue.global(qos: .userInitiated).async {
            // Check if network monitoring is enabled - otherwise enable it
            if self.networkMonitor == nil {
                self.registerForNetworkChangeNotifications()
            }

            // Check current network path
            if let networkPath = self.networkMonitor?.currentPath {
                self.responseToNetworkChanges(path: networkPath)
            } else {
                print("ES-NETWORK: Error when determining network status!")
            }
        }
    }

    @objc private func responseToLowPowerMode(_ notification: Notification) {
        // Check if user is known
        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        guard let userID = usersManager.firstUser?.userInfo.userId else {
            print("Error when responding to low power mode. User unknown!")
            return
        }

        // Check if indexing is in progress
        let expectedESStates: [EncryptedSearchIndexState] = [.undetermined, .disabled, .complete, .partial]
        if expectedESStates.contains(self.getESState(userID: userID)) {
            return
        }

        if ProcessInfo.processInfo.isLowPowerModeEnabled && !self.pauseIndexingDueToLowBattery {
            // Low power mode is enabled - pause indexing
            self.pauseIndexingDueToLowBattery = true
            print("Pause indexing due to low battery!")
            self.pauseAndResumeIndexingDueToInterruption(isPause: true, userID: userID)
        } else if !ProcessInfo.processInfo.isLowPowerModeEnabled && self.pauseIndexingDueToLowBattery {
            // Low power mode is disabled - continue indexing
            self.pauseIndexingDueToLowBattery = false
            print("Resume indexing as battery is charged again!")
            self.pauseAndResumeIndexingDueToInterruption(isPause: false, userID: userID)
        }
    }

    private func registerForTermalStateChangeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(responseToHeat(_:)), name: ProcessInfo.thermalStateDidChangeNotification, object: nil)
    }

    @objc private func responseToHeat(_ notification: Notification) {
        // Check if user is known
        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        guard let userID = usersManager.firstUser?.userInfo.userId else {
            print("Error when responding to iPhone heating up. User unknown!")
            return
        }

        // Check if indexing is in progress
        let expectedESStates: [EncryptedSearchIndexState] = [.undetermined, .disabled, .complete, .partial]
        if expectedESStates.contains(self.getESState(userID: userID)) {
            return
        }

        let termalState = ProcessInfo.processInfo.thermalState
        switch termalState {
        case .nominal:
            print("Thermal state nomial. No further action required")
            if self.pauseIndexingDueToOverheating {
                self.pauseIndexingDueToOverheating = false
                self.pauseAndResumeIndexingDueToInterruption(isPause: false, userID: userID)    // Resume indexing
            }
        case .fair:
            print("Thermal state fair. No further action required")
            if self.pauseIndexingDueToOverheating {
                self.pauseIndexingDueToOverheating = false
                self.pauseAndResumeIndexingDueToInterruption(isPause: false, userID: userID)    // Resume indexing
            }
        case .serious:
            print("Thermal state serious. Reduce CPU usage.")
        case .critical:
            print("Thermal state critical. Stop indexing!")
            self.pauseIndexingDueToOverheating = true
            self.pauseAndResumeIndexingDueToInterruption(isPause: true, userID: userID)    // Pause indexing
        @unknown default:
            break
        }
    }

    // Code from here: https://stackoverflow.com/a/64738201
    func getTotalAvailableMemory() -> Double {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let _ = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
                }
        }
        let totalMb = Float(ProcessInfo.processInfo.physicalMemory)// / 1048576.0
        return Double(totalMb)
    }

    //Code from here: https://stackoverflow.com/a/64738201
    private func getCurrentlyAvailableAppMemory() -> Double {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
                }
        }
        let usedMb = Float(taskInfo.phys_footprint)// / 1048576.0
        let totalMb = Float(ProcessInfo.processInfo.physicalMemory)// / 1048576.0
        var availableMemory: Double = 0
        if result != KERN_SUCCESS {
            availableMemory = Double(totalMb)
        } else {
            availableMemory = Double(totalMb - usedMb)
        }
        return availableMemory
    }

    private func updateUIWithIndexingStatus() {
        DispatchQueue.main.async {
            if self.pauseIndexingDueToNetworkConnectivityIssues {
                self.viewModel?.interruptStatus.value = LocalString._encrypted_search_download_paused_no_connectivity
                self.viewModel?.interruptAdvice.value = LocalString._encrypted_search_download_paused_no_connectivity_status
                return
            }
            if self.pauseIndexingDueToWiFiNotDetected {
                self.viewModel?.interruptStatus.value = LocalString._encrypted_search_download_paused_no_wifi
                self.viewModel?.interruptAdvice.value = LocalString._encrypted_search_download_paused_no_wifi_status
                return
            }
            if self.pauseIndexingDueToLowBattery {
                self.viewModel?.interruptStatus.value = LocalString._encrypted_search_download_paused_low_battery
                self.viewModel?.interruptAdvice.value = LocalString._encrypted_search_download_paused_low_battery_status
                return
            }
            if self.pauseIndexingDueToLowStorage {
                self.viewModel?.interruptStatus.value = LocalString._encrypted_search_download_paused_low_storage
                self.viewModel?.interruptAdvice.value = LocalString._encrypted_search_download_paused_low_storage_status
                return
            }
            // No interrupt
            self.viewModel?.interruptStatus.value = nil
            self.viewModel?.interruptAdvice.value = nil
        }
    }

    // This triggers the viewcontroller to reload the tableview when indexing is complete
    private func updateUIIndexingComplete() {
        self.viewModel?.isIndexingComplete.value = true
        #if !APP_EXTENSION
            self.searchViewModel?.encryptedSearchIndexingComplete = true
        #endif
    }

    func updateProgressedMessagesUI(progressedMessages: Int) {
        self.viewModel?.progressedMessages.value = progressedMessages
    }
}
