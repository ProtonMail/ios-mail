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
    //instance of Singleton
    static let shared = EncryptedSearchService()
    
    //set initializer to private - Singleton
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
        //self.registerForBatteryLevelChangeNotifications()
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
    
    enum EncryptedSearchIndexState: Int {
        case disabled = 0
        case partial = 1
        case lowstorage = 2
        case downloading = 3
        case paused = 4
        case refresh = 5
        case complete = 6
        case undetermined = 7
        case background = 8     //indicates that the index is currently build in the background
        case backgroundStopped = 9  // indicates that the index building has been paused while building in the background
    }
    var state: EncryptedSearchIndexState = .undetermined
    
    internal var user: UserManager!
    internal var messageService: MessageDataService? = nil
    internal var apiService: APIService? = nil
    internal var userDataSource: UserDataSource? = nil
    
    var totalMessages: Int = 0
    var lastMessageTimeIndexed: Int = 0     //stores the time of the last indexed message in case of an interrupt, or to fetch more than the limit of messages per request
    var processedMessages: Int = 0
    var noNewMessagesFound: Int = 0 // counter to break message fetching loop if no new messages are fetched after 5 attempts
    internal var prevProcessedMessages: Int = 0 //used to calculate estimated time for indexing
    internal var viewModel: SettingsEncryptedSearchViewModel? = nil
    #if !APP_EXTENSION
    internal var searchViewModel: SearchViewModel? = nil
    #endif

    internal var cipherForSearchIndex: EncryptedsearchAESGCMCipher? = nil
    internal var searchState: EncryptedsearchSearchState? = nil
    internal var indexBuildingInProgress: Bool = false
    internal var slowDownIndexBuilding: Bool = false
    internal var indexingStartTime: Double = 0
    internal var eventsWhileIndexing: [MessageAction]? = []
    internal var indexBuildingTimer: Timer? = nil
    internal var slowSearchTimer: Timer? = nil
    
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
    
    //internal lazy var internetStatusProvider: InternetConnectionStatusProvider? = nil
    //internal lazy var reachability: Reachability? = nil
    @available(iOS 12, *)
    internal lazy var networkMonitor: NWPathMonitor? = nil

    internal var pauseIndexingDueToNetworkConnectivityIssues: Bool = false
    internal var pauseIndexingDueToWiFiNotDetected: Bool = false
    internal var pauseIndexingDueToOverheating: Bool = false
    internal var pauseIndexingDueToLowBattery: Bool = false
    internal var pauseIndexingDueToLowStorage: Bool = false
    internal var numPauses: Int = 0
    internal var numInterruptions: Int = 0
    
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    let timeFormatter = DateComponentsFormatter()

    internal var isFirstSearch: Bool = true
    internal var isFirstIndexingTimeEstimate: Bool = true
    internal var initialIndexingEstimate: Int = 0
    internal var isRefreshed: Bool = false
    
    public var isSearching: Bool = false    // indicates that a search is currently active
}

extension EncryptedSearchService {
    func determineEncryptedSearchState(){
        // Run on a separate thread so that UI is not blocked
        DispatchQueue.global(qos: .userInitiated).async {
            //check if encrypted search is switched on in settings
            if !userCachedStatus.isEncryptedSearchOn {
                self.state = .disabled
                self.viewModel?.indexStatus = self.state.rawValue
                print("ENCRYPTEDSEARCH-STATE: disabled")
            } else {
                if self.pauseIndexingDueToLowStorage {
                    self.state = .lowstorage
                    self.viewModel?.indexStatus = self.state.rawValue
                    print("ENCRYPTEDSEARCH-STATE: lowstorage")
                    return
                }
                if self.pauseIndexingDueToOverheating || self.pauseIndexingDueToLowBattery || self.pauseIndexingDueToNetworkConnectivityIssues || self.pauseIndexingDueToWiFiNotDetected {
                    self.state = .paused
                    self.viewModel?.indexStatus = self.state.rawValue
                    print("ENCRYPTEDSEARCH-STATE: paused")
                    return
                }
                if self.indexBuildingInProgress {
                    self.state = .downloading
                    self.viewModel?.indexStatus = self.state.rawValue
                    print("ENCRYPTEDSEARCH-STATE: downloading")
                } else {
                    //Check if search index is complete
                    if userCachedStatus.indexComplete {
                        self.state = .complete
                        self.viewModel?.indexStatus = self.state.rawValue
                        print("ENCRYPTEDSEARCH-STATE: complete 1")
                        return
                    } else {
                        //check if search index exists and the number of messages in the search index
                        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
                        let userID: String? = usersManager.firstUser?.userInfo.userId
                        if userID == nil {
                            print("Error: userID unknown!")
                            self.state = .undetermined
                            self.viewModel?.indexStatus = self.state.rawValue
                            print("ENCRYPTEDSEARCH-STATE: undetermined")
                            return
                        }
                        if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: userID!) {
                            self.checkIfIndexingIsComplete() {
                                self.state = .complete
                                self.viewModel?.indexStatus = self.state.rawValue
                                print("ENCRYPTEDSEARCH-STATE: complete 2")
                                
                                // update user cached status
                                userCachedStatus.indexComplete = true
                                
                                self.updateUIIndexingComplete()
                            }
                            // Set state to partial in the meantime - if it is complete it will get updated once determined
                            self.state = .partial
                            self.viewModel?.indexStatus = self.state.rawValue
                            print("ENCRYPTEDSEARCH-STATE: partial 1")
                        } else {
                            print("Error search index does not exist for user!")
                            self.state = .undetermined
                            self.viewModel?.indexStatus = self.state.rawValue
                            print("ENCRYPTEDSEARCH-STATE: undetermined")
                        }
                    }
                }
                //TODO refresh?
                //self.state = .refresh
            }
        }
    }

    func resizeSearchIndex(expectedSize: Int64) -> Void {
        DispatchQueue.global(qos: .userInitiated).async {
            let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
            let userID: String? = usersManager.firstUser?.userInfo.userId
            if let userID = userID {
                let success: Bool = EncryptedSearchIndexService.shared.resizeSearchIndex(userID: userID, expectedSize: expectedSize)
                if success == false {
                    self.state = .complete
                    self.viewModel?.indexStatus = self.state.rawValue
                    print("ENCRYPTEDSEARCH-STATE: complete 3")
                } else {
                    self.state = .partial
                    self.viewModel?.indexStatus = self.state.rawValue
                    print("ENCRYPTEDSEARCH-STATE: partial 2")

                    self.lastMessageTimeIndexed = EncryptedSearchIndexService.shared.getNewestMessageInSearchIndex(for: userID)
                }
            } else {
                print("Error when resizing the search index: User not found!")
            }
        }
    }

    // MARK: - Index Building Functions
    //function to build the search index needed for encrypted search
    func buildSearchIndex(_ viewModel: SettingsEncryptedSearchViewModel) -> Void {
        #if !APP_EXTENSION
            if #available(iOS 13, *) {
                self.scheduleNewAppRefreshTask()
                self.scheduleNewBGProcessingTask()
            }
        #endif
        
        self.indexBuildingInProgress = true
        self.viewModel = viewModel

        self.state = .downloading
        self.viewModel?.indexStatus = self.state.rawValue
        print("ENCRYPTEDSEARCH-STATE: downloading")

        let uid: String? = self.updateCurrentUserIfNeeded()    // Check that we have the correct user selected
        if let userID = uid {
            // Check if search index db exists - and if not create it
            EncryptedSearchIndexService.shared.createSearchIndexDBIfNotExisting(for: userID)

            // Network checks
            if #available(iOS 12, *) {
                // Check network status - enable network monitoring if not available
                print("ES-NETWORK - build search index - enable network monitoring")
                self.registerForNetworkChangeNotifications()
                if self.pauseIndexingDueToNetworkConnectivityIssues || self.pauseIndexingDueToWiFiNotDetected {
                    self.indexBuildingInProgress = false
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

            self.getTotalMessages() {
                print("Total messages: ", self.totalMessages)

                let numberOfMessageInIndex: Int = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID)
                if numberOfMessageInIndex == 0 {
                    print("ES-DEBUG: Build search index completely new")
                    // If there are no message in the search index - build completely new
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.downloadAndProcessPage(userID: userID){ [weak self] in
                            self?.checkIfIndexingIsComplete(){}
                            return
                        }
                    }
                } else if numberOfMessageInIndex == self.totalMessages {
                    // No new messages on server - set to complete
                    self.state = .complete
                    self.viewModel?.indexStatus = self.state.rawValue
                    print("ENCRYPTEDSEARCH-STATE: complete 4")

                    // update user cached status
                    userCachedStatus.indexComplete = true

                    self.cleanUpAfterIndexing()
                    return
                } else {
                    print("ES-DEBUG: refresh search index")
                    // There are some new messages on the server - refresh the index
                    self.refreshSearchIndex(userID: userID)
                }
            }
        } else {
            print("Error: User ID unknown!")
        }
    }

    func restartIndexBuilding(userID: String, viewModel: SettingsEncryptedSearchViewModel) -> Void {
        // set viewmodel
        self.viewModel = viewModel

        // Set the state to downloading
        self.state = .downloading
        self.viewModel?.indexStatus = self.state.rawValue
        print("ENCRYPTEDSEARCH-STATE: downloading - restart index building")
        self.indexBuildingInProgress = true

        // Update the UI with refresh state
        self.updateUIWithIndexingStatus()

        // Set processed message to the number of entries in the search index
        self.processedMessages = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID)
        self.prevProcessedMessages = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID)

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

        // Start refreshing the index
        DispatchQueue.global(qos: .userInitiated).async {
            self.downloadAndProcessPage(userID: userID){ [weak self] in
                self?.checkIfIndexingIsComplete(){}
            }
        }
    }

    private func refreshSearchIndex(userID: String) -> Void {
        // Set the state to refresh
        self.state = .refresh
        self.viewModel?.indexStatus = self.state.rawValue
        print("ENCRYPTEDSEARCH-STATE: refresh")

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
                self?.checkIfIndexingIsComplete(){}
            }
        }
    }

    private func checkIfIndexingIsComplete(completionHandler: @escaping () -> Void) {
        self.getTotalMessages() {
            let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
            let userID: String = (usersManager.firstUser?.userInfo.userId)!
            let numberOfEntriesInSearchIndex: Int = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID)
            print("ES-DEBUG: entries in search index: \(numberOfEntriesInSearchIndex), total messages: \(self.totalMessages)")
            if numberOfEntriesInSearchIndex == self.totalMessages {
                self.state = .complete
                self.viewModel?.indexStatus = self.state.rawValue
                print("ENCRYPTEDSEARCH-STATE: complete 5")
                
                // update user cached status
                userCachedStatus.indexComplete = true
                
                // cleanup
                self.cleanUpAfterIndexing()
            } else {
                if self.state == .downloading || self.state == .refresh {
                    self.state = .partial
                    self.viewModel?.indexStatus = self.state.rawValue
                    print("ENCRYPTEDSEARCH-STATE: partial 3")

                    // update user cached status
                    userCachedStatus.indexComplete = true

                    // cleanup
                    self.cleanUpAfterIndexing()
                }
            }
            completionHandler()
        }
    }
    
    //called when indexing is complete
    private func cleanUpAfterIndexing() {
        if self.state == .complete || self.state == .partial {
            let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
            let userID: String = (usersManager.firstUser?.userInfo.userId)!

            // set some status variables
            self.viewModel?.isEncryptedSearch = true
            self.viewModel?.currentProgress.value = 100
            self.viewModel?.estimatedTimeRemaining.value = nil
            self.indexBuildingInProgress = false

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
                    //index building finished - we no longer need a background task
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

            // Process events that have been accumulated during indexing
            self.processEventsAfterIndexing() {
                // Set state to complete when finished
                self.state = .complete
                self.viewModel?.indexStatus = self.state.rawValue
                print("ENCRYPTEDSEARCH-STATE: complete 6")

                // Invalidate timer on same thread as it has been created
                DispatchQueue.main.async {
                    self.indexBuildingTimer?.invalidate()
                }

                // Update UI
                self.updateUIIndexingComplete()
            }
        } else if self.state == .paused {
            self.indexBuildingInProgress = false

            // Invalidate timer on same thread as it has been created
            DispatchQueue.main.async {
                self.indexBuildingTimer?.invalidate()
            }
        }
    }
    
    func pauseAndResumeIndexingByUser(isPause: Bool) -> Void {
        if isPause {
            self.numPauses += 1
            self.state = .paused
            self.viewModel?.indexStatus = self.state.rawValue
            print("ENCRYPTEDSEARCH-STATE: paused - by user")
        } else {
            self.state = .downloading
            self.viewModel?.indexStatus = self.state.rawValue
            print("ENCRYPTEDSEARCH-STATE: downloading - resume by user")
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.pauseAndResumeIndexing()
        }
    }
    
    func pauseAndResumeIndexingDueToInterruption(isPause: Bool, completionHandler: (() -> Void)? = nil){
        if isPause {
            self.numInterruptions += 1
            self.state = .paused
            self.viewModel?.indexStatus = self.state.rawValue
            print("ENCRYPTEDSEARCH-STATE: paused")
        } else {
            //check if any of the flags is set to true
            if self.pauseIndexingDueToLowBattery || self.pauseIndexingDueToNetworkConnectivityIssues || self.pauseIndexingDueToOverheating || self.pauseIndexingDueToLowStorage || self.pauseIndexingDueToWiFiNotDetected {
                self.state = .paused
                self.viewModel?.indexStatus = self.state.rawValue
                print("ENCRYPTEDSEARCH-STATE: paused")

                completionHandler?()
                return
            }
            self.state = .downloading
            self.viewModel?.indexStatus = self.state.rawValue
            print("ENCRYPTEDSEARCH-STATE: downloading")
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.pauseAndResumeIndexing(completionHandler: completionHandler)
        }
    }
    
    private func pauseAndResumeIndexing(completionHandler: (() -> Void)? = {}) {
        let uid: String? = self.updateCurrentUserIfNeeded()
        if let userID = uid {
            if self.state == .paused {  //pause indexing
                print("Pause indexing!")
                self.downloadPageQueue.cancelAllOperations()
                self.messageIndexingQueue.cancelAllOperations()
                self.indexBuildingInProgress = false

                self.cleanUpAfterIndexing()
                // In case of an interrupt - update UI
                if self.pauseIndexingDueToLowBattery || self.pauseIndexingDueToNetworkConnectivityIssues || self.pauseIndexingDueToOverheating || self.pauseIndexingDueToLowStorage || self.pauseIndexingDueToWiFiNotDetected {
                    self.updateUIWithIndexingStatus()
                }
            } else {    // Resume indexing
                print("Resume indexing...")
                self.indexBuildingInProgress = true
                // Clean up timer
                // Invalidate timer on same thread as it has been created
                DispatchQueue.main.async {
                    self.indexBuildingTimer?.invalidate()
                    self.indexBuildingTimer = nil
                    // Recreate timer
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

                self.downloadAndProcessPage(userID: userID){ [weak self] in
                    self?.checkIfIndexingIsComplete {
                        completionHandler?()
                    }
                }
            }
        } else {
            print("Error in pauseAndResume Indexing. User unknown!")
            completionHandler?()
        }
    }

    struct MessageAction {
        var action: NSFetchedResultsChangeType? = nil
        var message: Message? = nil
    }
    
    func updateSearchIndex(_ action: NSFetchedResultsChangeType, _ message: Message?) {
        if self.state == .downloading || self.state == .paused || self.state == .background || self.state == .backgroundStopped {
            let messageAction: MessageAction = MessageAction(action: action, message: message)
            self.eventsWhileIndexing!.append(messageAction)
        } else {
            let users: UsersManager = sharedServices.get(by: UsersManager.self)
            let uid: String? = users.firstUser?.userInfo.userId
            if let userID = uid {
                switch action {
                    case .delete:
                        self.updateMessageMetadataInSearchIndex(message, action)
                        if EncryptedSearchCacheService.shared.isCacheBuilt(userID: userID){ // update cache if existing
                            let _ = EncryptedSearchCacheService.shared.updateCachedMessage(userID: userID, message: message)
                        }
                    case .insert:
                        self.insertSingleMessageToSearchIndex(message)  // update search index db
                        if EncryptedSearchCacheService.shared.isCacheBuilt(userID: userID){ // update cache if existing
                            let _ = EncryptedSearchCacheService.shared.updateCachedMessage(userID: userID, message: message)
                        }
                    case .move:
                        self.updateMessageMetadataInSearchIndex(message, action)
                        if EncryptedSearchCacheService.shared.isCacheBuilt(userID: userID){ // update cache if existing
                            let _ = EncryptedSearchCacheService.shared.updateCachedMessage(userID: userID, message: message)
                        }
                    case .update:
                        self.updateMessageMetadataInSearchIndex(message, action)
                        if EncryptedSearchCacheService.shared.isCacheBuilt(userID: userID){ // update cache if existing
                            let _ = EncryptedSearchCacheService.shared.updateCachedMessage(userID: userID, message: message)
                        }
                    default:
                        return
                }
            } else {
                print("Error when updating search index: User unknown!")
            }
        }
    }
    
    func processEventsAfterIndexing(completionHandler: @escaping () -> Void) {
        if self.eventsWhileIndexing!.isEmpty {
            completionHandler()
        } else {
            // Set state to refresh
            self.state = .refresh
            self.viewModel?.indexStatus = self.state.rawValue
            print("ENCRYPTEDSEARCH-STATE: refresh")

            let messageAction: MessageAction = self.eventsWhileIndexing!.removeFirst()
            self.updateSearchIndex(messageAction.action!, messageAction.message)
            self.processEventsAfterIndexing() {
                print("All events processed that have been accumulated during indexing...")

                // Set state to complete when finished
                self.state = .complete
                self.viewModel?.indexStatus = self.state.rawValue
                print("ENCRYPTEDSEARCH-STATE: complete 7")

                // Update UI
                self.updateUIIndexingComplete()
            }
        }
    }
    
    func insertSingleMessageToSearchIndex(_ message: Message?) {
        guard let messageToInsert = message else {
            return
        }
        let users: UsersManager = sharedServices.get(by: UsersManager.self)
        let uid: String? = users.firstUser?.userInfo.userId
        if let userID = uid {
            //just insert a new message if the search index exists for the user - otherwise it needs to be build first
            if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: userID) {
                let esMessage:ESMessage? = self.convertMessageToESMessage(for: messageToInsert)
                self.fetchMessageDetailForMessage(userID: userID, message: esMessage!) { [weak self] (error, messageWithDetails) in
                    if error == nil {
                        self?.decryptAndExtractDataSingleMessage(for: messageWithDetails!, userID: userID) {
                            self?.processedMessages += 1
                            self?.lastMessageTimeIndexed = Int((messageWithDetails!.Time))
                            //print("Sucessfully inserted new message \(message!.messageID) in search index")
                        }
                    } else {
                        print("Error when fetching for message details...")
                    }
                }
            } else {
                print("No search index found for user: \(userID)")
            }
        } else {
            print("Error when inserting single message to search index. User unknown!")
        }
    }
    
    func deleteMessageFromSearchIndex(_ message: Message?) {
        guard let messageToDelete = message else {
            return
        }
        let users: UsersManager = sharedServices.get(by: UsersManager.self)
        let uid: String? = users.firstUser?.userInfo.userId
        if let userID = uid {
            //just delete a message if the search index exists for the user - otherwise it needs to be build first
            if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: userID) {
                _ = EncryptedSearchIndexService.shared.removeEntryFromSearchIndex(user: userID, message: messageToDelete.messageID)
            } else {
                print("No search index found for user: \(userID)")
            }
            
            if EncryptedSearchCacheService.shared.isCacheBuilt(userID: userID){ // delete message from cache if cache is built
                let _ = EncryptedSearchCacheService.shared.deleteCachedMessage(userID: userID, messageID: messageToDelete.messageID)
            }
            
        } else {
            print("Error when deleting message from search index. User unknown!")
        }
    }
    
    func deleteSearchIndex(){
        // Update state
        self.state = .disabled
        self.viewModel?.indexStatus = self.state.rawValue
        print("ENCRYPTEDSEARCH-STATE: disabled")
        
        // update user cached status
        userCachedStatus.isEncryptedSearchOn = false
        userCachedStatus.indexComplete = false

        let users: UsersManager = sharedServices.get(by: UsersManager.self)
        let uid: String? = users.firstUser?.userInfo.userId
        if let userID = uid {
            // Just delete the search index if it exists
            if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: userID) {
                let result: Bool = EncryptedSearchIndexService.shared.deleteSearchIndex(for: userID)

                // Update some variables
                self.totalMessages = 0
                self.lastMessageTimeIndexed = 0
                self.processedMessages = 0
                self.prevProcessedMessages = 0
                self.noNewMessagesFound = 0
                self.indexingStartTime = 0
                self.indexBuildingInProgress = false
                self.slowDownIndexBuilding = false
                self.eventsWhileIndexing = []
                
                self.pauseIndexingDueToNetworkConnectivityIssues = false
                self.pauseIndexingDueToWiFiNotDetected = false
                self.pauseIndexingDueToOverheating = false
                self.pauseIndexingDueToLowBattery = false
                self.pauseIndexingDueToLowStorage = false
                self.numPauses = 0
                self.numInterruptions = 0
                
                // Update viewmodel
                self.viewModel?.isEncryptedSearch = false
                self.viewModel?.currentProgress.value = 0
                self.viewModel?.estimatedTimeRemaining.value = nil

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

                if result {
                    print("Search index for user \(userID) sucessfully deleted!")
                }
            }
        } else {
            print("Error when deleting the search index. User unknown!")
        }
    }
    
    private func updateMessageMetadataInSearchIndex(_ message: Message?, _ action: NSFetchedResultsChangeType) {
        guard let messageToUpdate = message else {
            return
        }
        let users: UsersManager = sharedServices.get(by: UsersManager.self)
        let uid: String? = users.firstUser?.userInfo.userId
        if let userID = uid {
            if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: userID){
                self.deleteMessageFromSearchIndex(messageToUpdate)
                self.insertSingleMessageToSearchIndex(messageToUpdate)
            } else {
                print("No search index found for user: \(userID)")
            }
        } else {
            print("Error when updating the search index. User unknown!")
        }
    }
    
    private func updateCurrentUserIfNeeded() -> String? {
        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        let user: UserManager? = usersManager.firstUser
        let userID: String? = user?.userInfo.userId
        self.messageService = user?.messageService
        self.apiService = user?.apiService
        self.userDataSource = self.messageService?.userDataSource
        return userID
    }
    
    // Checks the total number of messages on the backend
    private func getTotalMessages(completionHandler: @escaping () -> Void) -> Void {
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
                    //429 - too many requests - retry after some time
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
                            //Retry-after header not present, return error
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
                            //everything went well - return messages
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
                if self.indexBuildingInProgress {
                    //recursion?
                    self.downloadAndProcessPage(userID: userID){
                        completionHandler()
                    }
                } else {
                    //index building stopped from outside - finish up current page and return
                    completionHandler()
                }
            }
        }
    }
    
    private func downloadPage(userID: String, completionHandler: @escaping () -> Void){
        //start a new thread to download page
        DispatchQueue.global(qos: .userInitiated).async {
            var op: Operation? = DownloadPageAsyncOperation(userID: userID)
            self.downloadPageQueue.addOperation(op!)
            self.downloadPageQueue.waitUntilAllOperationsAreFinished()
            //cleanup
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
    
    // TODO remove?
    /*private func parseMessageObjectFromResponse(for response: [String : Any]) -> Message? {
        var message: Message? = nil
        do {
            message = try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: response, in: (self.messageService?.coreDataService.operationContext)!) as? Message
            message!.messageStatus = 1
            message!.isDetailDownloaded = true
        } catch {
            print("Error when parsing message object: \(error)")
        }
        return message
    } */

    //TODO reset fetch controller managed object context?
    private func getMessage(_ messageID: String, completionHandler: @escaping (Message?) -> Void) -> Void {
        /*if self.messageService == nil {
            self.updateCurrentUserIfNeeded()    //get user, messageservice and apiservice
        }*/
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
                //print("Error when fetching the message from core data - message not found")
                completionHandler(nil)
            }
        } else {
            //print("Error with context when fetching message from core data")
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
            //body = try self.messageService?.decryptBodyIfNeeded(message: message)
            body = try self.decryptBodyIfNeeded(message: message)
            decryptionFailed = false
        } catch {
            print("Error when decrypting messages: \(error).")
        }
        
        let emailContent: String = EmailparserExtractData(body!, true)
        let encryptedContent: EncryptedsearchEncryptedMessageContent? = self.createEncryptedContent(message: message, cleanedBody: emailContent, userID: userID)
        
        //add message to search index db
        self.addMessageKewordsToSearchIndex(userID, message, encryptedContent, decryptionFailed)
        completionHandler()
    }
    
    func createEncryptedContent(message: ESMessage, cleanedBody: String, userID: String) -> EncryptedsearchEncryptedMessageContent? {
        //1. create decryptedMessageContent
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
        
        //2. encrypt content via gomobile
        let cipher: EncryptedsearchAESGCMCipher = self.getCipher(userID: userID)
        var ESEncryptedMessageContent: EncryptedsearchEncryptedMessageContent? = nil
        
        do {
            ESEncryptedMessageContent = try cipher.encrypt(decryptedMessageContent)
        } catch {
            print(error)
        }
        
        return ESEncryptedMessageContent
    }

    private func getCipher(userID: String) -> EncryptedsearchAESGCMCipher {
        if self.cipherForSearchIndex == nil {   //TODO we need to regenerate the cipher if there is a switch between users
            let key: Data? = self.retrieveSearchIndexKey(userID: userID)
            //TODO error when key is nil
            let cipher: EncryptedsearchAESGCMCipher = EncryptedsearchAESGCMCipher(key!)!
            self.cipherForSearchIndex = cipher
        }
        return self.cipherForSearchIndex!
    }
    
    private func generateSearchIndexKey(_ userID: String) -> Data? {
        let keylen: Int = 32
        var error: NSError?
        let bytes = CryptoRandomToken(keylen, &error)
        self.storeSearchIndexKey(bytes, userID: userID)
        return bytes
    }
    
    private func storeSearchIndexKey(_ key: Data?, userID: String) {
        var encData: Data? = nil
        
        /*if #available(iOS 13.0, *) {
            let key256 = CryptoKit.SymmetricKey(size: .bits256)
            encData = try! AES.GCM.seal(key!, using: key256).combined
        } else {
            // Fallback on earlier versions - do not encrypt key?
            encData = key
        }*/
        encData = key // disable encrypting key for testing purposes
        KeychainWrapper.keychain.set(encData!, forKey: "searchIndexKey_" + userID)
    }
    
    private func retrieveSearchIndexKey(userID: String) -> Data? {
        var key: Data? = KeychainWrapper.keychain.data(forKey: "searchIndexKey_" + userID)
        
        //Check if user already has an key
        if key != nil {
            var decryptedKey:Data? = nil
            /*if #available(iOS 13.0, *) {
                let box = try! AES.GCM.SealedBox(combined: key!)
                let key256 = CryptoKit.SymmetricKey(size: .bits256)
                decryptedKey = try! AES.GCM.open(box, using: key256)
            } else {
                // Fallback on earlier versions - do not decrypt key?
                decryptedKey = key
            }*/
            decryptedKey = key  //disable encrypting key for testing purposes
            
            return decryptedKey // if yes, return
        }
 
        // if no, generate a new key and then return
        key = self.generateSearchIndexKey(userID)
        return key
    }

    func addMessageKewordsToSearchIndex(_ userID: String, _ message: ESMessage, _ encryptedContent: EncryptedsearchEncryptedMessageContent?, _ decryptionFailed: Bool) -> Void {
        var hasBody: Bool = true
        if decryptionFailed {
            hasBody = false //TODO are there any other case where there is no body?
        }

        let location: Int = Int(Message.Location.allmail.rawValue)!
        let time: Int = Int(message.Time)
        let order: Int = message.Order

        let iv: Data = (encryptedContent?.iv)!.base64EncodedData()
        let ciphertext:Data = (encryptedContent?.ciphertext)!.base64EncodedData()
        let encryptedContentSize: Int = ciphertext.count

        let _: Int64? = EncryptedSearchIndexService.shared.addNewEntryToSearchIndex(for: userID, messageID: message.ID, time: time, labelIDs: message.LabelIDs, isStarred: message.Starred!, unread: (message.Unread != 0), location: location, order: order, hasBody: hasBody, decryptionFailed: decryptionFailed, encryptionIV: iv, encryptedContent: ciphertext, encryptedContentFile: "", encryptedContentSize: encryptedContentSize)
    }

    // Called to slow down indexing - so that a user can normally use the app
    func slowDownIndexing(){
        if self.state == .downloading || self.state == .background || self.state == .refresh {
            if self.indexBuildingInProgress && !self.slowDownIndexBuilding {
                self.messageIndexingQueue.maxConcurrentOperationCount = 10
                self.slowDownIndexBuilding = true
            }
        }
    }

    // speed up indexing again when in foreground
    func speedUpIndexing(){
        if self.state == .downloading || self.state == .background || self.state == .refresh {
            if self.indexBuildingInProgress && self.slowDownIndexBuilding {
                self.messageIndexingQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
                self.slowDownIndexBuilding = false
            }
        }
    }

    // MARK: - Search Functions
    #if !APP_EXTENSION
    func search(_ query: String, page: Int, searchViewModel: SearchViewModel, completion: ((NSError?, Int?) -> Void)?) {
        print("encrypted search on client side!")
        print("Query: ", query)
        print("Page: ", page)

        if query == "" {
            completion?(nil, nil) //There are no results for an empty search query
        }

        //update necessary variables needed
        let uid: String? = self.updateCurrentUserIfNeeded()
        if let userID = uid {
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
            let searcher: EncryptedsearchSimpleSearcher = self.getSearcher(query)
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
        } else {
            print("Error when searching. User unknown!")
        }
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

    private func getSearcher(_ query: String) -> EncryptedsearchSimpleSearcher {
        let contextSize: CLong = 100 // The max size of the content showed in the preview
        let keywords: EncryptedsearchStringList? = self.createEncryptedSearchStringList(query)   //split query into individual keywords
        return EncryptedsearchSimpleSearcher(keywords, contextSize: contextSize)!
    }

    private func createEncryptedSearchStringList(_ query: String) -> EncryptedsearchStringList {
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
                    self.getMessage(id) { message in
                        if message == nil {
                            self.fetchSingleMessageFromServer(byMessageID: id) { [weak self] (error) in
                                if error != nil {
                                    print("Error when fetching message from server: \(String(describing: error))")
                                    group.leave()
                                } else {
                                    self?.getMessage(id) { msg in
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

            //visualize intemediate results
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
            
            //visualize intemediate results
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
    public func continueIndexingInBackground() {
        self.speedUpIndexing()
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
        request.requiresNetworkConnectivity = true  //we need network connectivity when building the index
        //request.requiresExternalPower = true    //we don't neccesarily need it - however we get more execution time if we enable it

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Error when scheduling index building background task: \(error)")
        }
    }

    @available(iOS 13.0, *)
    private func bgProcessingTask(task: BGProcessingTask) {
        //Provide an expiration handler in case indexing is not finished in time
        task.expirationHandler = {
            //schedule a new background processing task if index building is not finished
            self.scheduleNewBGProcessingTask()

            self.state = .backgroundStopped
            self.viewModel?.indexStatus = self.state.rawValue
            print("ENCRYPTEDSEARCH-STATE: backgroundStopped")

            //slow down indexing again - will be speed up if user switches to ES screen
            self.slowDownIndexing()
        }

        //index is build in foreground - no need for a background task
        if self.state == .downloading {
            task.setTaskCompleted(success: true)
        } else {
            self.state = .background
            self.viewModel?.indexStatus = self.state.rawValue
            print("ENCRYPTEDSEARCH-STATE: background")

            // in the background we can index with full speed
            self.speedUpIndexing()

            //start indexing in background
            self.pauseAndResumeIndexingDueToInterruption(isPause: false) {
                //if indexing is finshed during background task - set to complete
                self.state = .complete
                self.viewModel?.indexStatus = self.state.rawValue
                print("ENCRYPTEDSEARCH-STATE: complete 8")
                
                // update user cached status
                userCachedStatus.indexComplete = true
                
                task.setTaskCompleted(success: true)
            }
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
        //Provide an expiration handler in case indexing is not finished in time
        task.expirationHandler = {
            //schedule a new background app refresh task
            self.scheduleNewAppRefreshTask()
            
            self.state = .backgroundStopped
            self.viewModel?.indexStatus = self.state.rawValue
            print("ENCRYPTEDSEARCH-STATE: backgroundStopped")
            
            //slow down indexing again - will be speed up if user switches to ES screen
            self.slowDownIndexing()
        }
        
        //index is build in foreground - no need for a background task
        if self.state == .downloading {
            task.setTaskCompleted(success: true)
        } else {
            self.state = .background
            self.viewModel?.indexStatus = self.state.rawValue
            print("ENCRYPTEDSEARCH-STATE: background")

            // in the background we can index with full speed
            self.speedUpIndexing()

            //start indexing in background
            self.pauseAndResumeIndexingDueToInterruption(isPause: false) {
                //if indexing is finshed during background task - set to complete
                self.state = .complete
                self.viewModel?.indexStatus = self.state.rawValue
                print("ENCRYPTEDSEARCH-STATE: complete 9")
                
                // update user cached status
                userCachedStatus.indexComplete = true
                
                task.setTaskCompleted(success: true)
            }
        }
    }

    // MARK: - Analytics/Metrics Functions
    enum Metrics {
        case index
        case search
    }
    
    private func sendIndexingMetrics(indexTime: Double, userID: String){
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
    
    private func sendMetrics(metric: Metrics, data: [String: Any], completion: @escaping CompletionBlock){
        var title: String = ""
        switch metric {
        case .index:
            title = "index"
        case .search:
            title = "search"
        }

        if metric == .search {
            let delay: Int = Int.random(in: 1...180) //add a random delay between 1 second and 3 minutes
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay)){
                self.apiService?.metrics(log: "encrypted_search", title: title, data: data, completion: completion)
            }
        } else {
            self.apiService?.metrics(log: "encrypted_search", title: title, data: data, completion: completion)
        }
    }

    // MARK: - Helper Functions
    /* private func sendNotification(text: String){
        let content = UNMutableNotificationContent()
        content.title = "Background Processing Task"
        content.subtitle = text
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    } */
    
    // Notification when app moves to BG
    /* @objc private func appMovedToBackground(){
        print("App moved to background")
        if self.indexBuildingInProgress {
            self.sendNotification(text: "Index building is in progress... Please tap to resume index building in foreground.")
        }
    } */
    
    private func checkIfEnoughStorage() {
        let remainingStorageSpace = self.getCurrentlyAvailableAppMemory()
        print("Current storage space: \(remainingStorageSpace)")
        if remainingStorageSpace < 100 {
            self.pauseIndexingDueToLowStorage = true
            self.pauseAndResumeIndexingDueToInterruption(isPause: true)
        }
    }

    private func estimateIndexingTime() -> (estimatedTime: String?, currentProgress: Int){
        var estimatedTime: Double = 0
        var currentProgress: Int = 0
        let currentTime: Double = CFAbsoluteTimeGetCurrent()
        //let minute: Double = 60_000.0

        if self.totalMessages != 0 && currentTime != self.indexingStartTime && self.processedMessages != self.prevProcessedMessages {
            let remainingMessages: Double = Double(self.totalMessages - self.processedMessages)
            let timeDifference: Double = currentTime-self.indexingStartTime
            let processedMessageDifference: Double = Double(self.processedMessages-self.prevProcessedMessages)
            //estimatedMinutes = Int(ceil(((timeDifference/processedMessageDifference)*remainingMessages)/minute))
            estimatedTime = ceil((timeDifference/processedMessageDifference)*remainingMessages)
            currentProgress = Int(ceil((Double(self.processedMessages)/Double(self.totalMessages))*100))
            self.prevProcessedMessages = self.processedMessages
        }

        return (self.timeToDate(time: estimatedTime), currentProgress)
    }

    @objc private func updateRemainingIndexingTime() {
        // Stop timer if indexing is finished or paused
        if self.state == .complete || self.state == .partial || self.state == .paused || self.state == .undetermined || self.state == .disabled {
            // Invalidate timer on same thread as it has been created
            DispatchQueue.main.async {
                self.indexBuildingTimer?.invalidate()
            }
        }

        if self.state == .downloading {
            DispatchQueue.global().async {
                let result = self.estimateIndexingTime()

                if self.isFirstIndexingTimeEstimate {
                    //let minute: Int = 60_000
                    //self.initialIndexingEstimate = //result.estimatedMinutes * minute
                    self.initialIndexingEstimate = 0    // TODO replace correctly
                    self.isFirstIndexingTimeEstimate = false
                }

                // Update UI
                self.viewModel?.currentProgress.value = result.currentProgress
                self.viewModel?.estimatedTimeRemaining.value = result.estimatedTime
                print("Remaining indexing time: \(String(describing: result.estimatedTime))")
                print("Current progress: \(result.currentProgress)")
                print("Indexing rate: \(self.messageIndexingQueue.maxConcurrentOperationCount)")
            }
        }
        
        //check if there is still enought storage left
        self.checkIfEnoughStorage()
        
        // print state for debugging
        print("ES-DEBUG: \(self.state)")
    }

    private func timeToDate(time: Double) -> String? {
        let date: Date = Date(timeIntervalSinceNow: TimeInterval(time))

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .full    // spells out units
        formatter.collapsesLargestUnit = true
        formatter.includesTimeRemainingPhrase = true    // adds remaining in the end
        formatter.zeroFormattingBehavior = .dropLeading // drops leading units that are zero
        
        let datecomp = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        return formatter.string(from: datecomp)
    }

    // Not used at the moment - use low power mode notification instead
    /*private func registerForBatteryLevelChangeNotifications() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(responseToBatteryLevel(_:)), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
    }*/
    
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
                    print("state: \(self.state)")
                    if self.state == .paused {
                        self.pauseAndResumeIndexingDueToInterruption(isPause: false)
                    }
                } else {
                    // Mobile data available - however user switched indexing on mobile data off
                    print("ES-NETWORK cellular - mobile data off")

                    // Update some state variables
                    self.pauseIndexingDueToWiFiNotDetected = true
                    self.pauseIndexingDueToNetworkConnectivityIssues = false

                    // If downloading - Pause indexing
                    print("state: \(self.state)")
                    if self.state == .downloading {
                        self.pauseAndResumeIndexingDueToInterruption(isPause: true)
                    }
                }
            } else {    // WiFi available
                print("ES-NETWORK wifi")

                // Update some state variables
                self.pauseIndexingDueToWiFiNotDetected = false
                self.pauseIndexingDueToNetworkConnectivityIssues = false

                // If indexing was paused - continue on wifi again
                print("state: \(self.state)")
                if self.state == .paused {
                    self.pauseAndResumeIndexingDueToInterruption(isPause: false)
                }
            }
        } else {
            print("ES-NETWORK No Internet available")

            // Update state variable
            self.pauseIndexingDueToNetworkConnectivityIssues = true
            self.pauseIndexingDueToWiFiNotDetected = true

            // Pause indexing
            print("state: \(self.state)")
            if self.state == .downloading {
                self.pauseAndResumeIndexingDueToInterruption(isPause: true)
            }
        }

        // Update UI
        self.updateUIWithIndexingStatus()
    }
    
    @available(iOS 12, *)
    func checkIfNetworkAvailable() -> Bool {
        // Check if network monitoring is enabled - otherwise enable it
        if self.networkMonitor == nil {
            self.registerForNetworkChangeNotifications()
        }

        // Check current network path
        if let networkPath = self.networkMonitor?.currentPath {
            self.responseToNetworkChanges(path: networkPath)
            return true
        }

        // Error - cannot determine current network state
        print("ES-NETWORK: Error when determining network status!")
        return false
    }

    /*@objc private func responseToNetworkChanges(_ notification: Notification) {
        if let rechability = notification.object as? Reachability {
            let networkStatus = rechability.connection
            switch networkStatus {
            case .unavailable:
                print("ES-NETWORK No Internet available")
                self.pauseIndexingDueToNetworkConnectivityIssues = true
                self.pauseAndResumeIndexingDueToInterruption(isPause: true)
                break
            case .wifi:
                print("ES-NETWORK wifi")
                // If indexing was paused because it was on mobile data - continue on wifi again
                if self.state == .paused && self.pauseIndexingDueToWiFiNotDetected {
                    self.pauseIndexingDueToWiFiNotDetected = false
                    self.pauseAndResumeIndexingDueToInterruption(isPause: false)
                    self.updateUIWithIndexingStatus()
                }
                // If indexing was paused because there was no internet connection - continue on wifi again
                if self.state == .paused && self.pauseIndexingDueToNetworkConnectivityIssues {
                    self.pauseIndexingDueToNetworkConnectivityIssues = false
                    self.pauseAndResumeIndexingDueToInterruption(isPause: false)
                    self.updateUIWithIndexingStatus()
                }
                break
            case .cellular:
                print("ES-NETWORK cellular")
                // If indexing with mobile data is enabled
                if userCachedStatus.downloadViaMobileData {
                    // If indexing was paused because it was on mobile data - and user changed setting continue indexing
                    if self.state == .paused && self.pauseIndexingDueToWiFiNotDetected {
                        self.pauseIndexingDueToWiFiNotDetected = false
                        self.pauseAndResumeIndexingDueToInterruption(isPause: false)
                        self.updateUIWithIndexingStatus()
                    }
                    // If indexing was paused because there was no internet connection - continue on wifi again
                    if self.state == .paused && self.pauseIndexingDueToNetworkConnectivityIssues {
                        self.pauseIndexingDueToNetworkConnectivityIssues = false
                        self.pauseAndResumeIndexingDueToInterruption(isPause: false)
                        self.updateUIWithIndexingStatus()
                    }
                } else {
                    if self.state == .downloading {
                        self.pauseIndexingDueToWiFiNotDetected = true
                        self.pauseAndResumeIndexingDueToInterruption(isPause: true)
                        self.updateUIWithIndexingStatus()
                    }
                }
                break
            default:
                print("ES-NETWORK default")
                break
            }
        }
    }*/
    
    @objc private func responseToLowPowerMode(_ notification: Notification) {
        if ProcessInfo.processInfo.isLowPowerModeEnabled && !self.pauseIndexingDueToLowBattery {
            // Low power mode is enabled - pause indexing
            self.pauseIndexingDueToLowBattery = true
            print("Pause indexing due to low battery!")
            self.pauseAndResumeIndexingDueToInterruption(isPause: true)
        } else if !ProcessInfo.processInfo.isLowPowerModeEnabled && self.pauseIndexingDueToLowBattery {
            // Low power mode is disabled - continue indexing
            self.pauseIndexingDueToLowBattery = false
            print("Resume indexing as battery is charged again!")
            self.pauseAndResumeIndexingDueToInterruption(isPause: false)
        }
    }
    
    // Not used at the moment - use low power mode notification instead
    /* @objc private func responseToBatteryLevel(_ notification: Notification) {
        //if battery is low (Android < 15%), (iOS < 20%) we pause indexing
        let batteryLevel: Float = UIDevice.current.batteryLevel
        if batteryLevel < 0.2 && !self.pauseIndexingDueToLowBattery {   //if battery is < 20% and indexing is not already paused - then pause
            print("Pause indexing due to low battery!")
            self.pauseAndResumeIndexingDueToInterruption(isPause: true)
        } else if batteryLevel >= 0.2 && self.pauseIndexingDueToLowBattery {    // if battery >= 20% and indexing is paused - then resume
            print("Resume indexing as battery is charged again!")
            self.pauseAndResumeIndexingDueToInterruption(isPause: false)
        }
    } */
    
    private func registerForTermalStateChangeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(responseToHeat(_:)), name: ProcessInfo.thermalStateDidChangeNotification, object: nil)
    }
    
    @objc private func responseToHeat(_ notification: Notification){
        let termalState = ProcessInfo.processInfo.thermalState
        switch termalState {
        case .nominal:
            print("Thermal state nomial. No further action required")
            if self.pauseIndexingDueToOverheating {
                self.pauseIndexingDueToOverheating = false
                self.pauseAndResumeIndexingDueToInterruption(isPause: false)    //resume indexing
            }
        case .fair:
            print("Thermal state fair. No further action required")
            if self.pauseIndexingDueToOverheating {
                self.pauseIndexingDueToOverheating = false
                self.pauseAndResumeIndexingDueToInterruption(isPause: false)    //resume indexing
            }
        case .serious:
            print("Thermal state serious. Reduce CPU usage.")
        case .critical:
            print("Thermal state critical. Stop indexing!")
            self.pauseIndexingDueToOverheating = true
            self.pauseAndResumeIndexingDueToInterruption(isPause: true)    //pause indexing
        @unknown default:
            print("Unknown temperature state. Do something?")
        }
    }
    
    //Code from here: https://stackoverflow.com/a/64738201
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
    
    private func updateIndexBuildingProgress(processedMessages: Int){
        //progress bar runs from 0 to 1 - normalize by totalMessages
        let updateStep: Float = Float(processedMessages)/Float(self.totalMessages)
        self.viewModel?.currentProgress.value = Int(updateStep)
    }
    
    private func updateUIWithIndexingStatus() {
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
    
    //This triggers the viewcontroller to reload the tableview when indexing is complete
    private func updateUIIndexingComplete() {
        self.viewModel?.isIndexingComplete.value = true
        #if !APP_EXTENSION
            self.searchViewModel?.encryptedSearchIndexingComplete = true
        #endif
    }
}
