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

struct ESSender: Codable {
    var Name: String = ""
    var Address: String = ""
}

public class ESMessage: Codable {
    //variables that are fetched with getMessage
    public var ID: String = ""
    public var Order: Int
    public var ConversationID: String
    public var Subject: String
    public var Unread: Int
    public var `Type`: Int    //messagetype
    public var SenderAddress: String //TODO
    public var SenderName: String   //TODO
    var Sender: ESSender
    //public var replyTo: String  //not existing
    //public var replyTos: String //TODO
    var ToList: [ESSender?] = []
    var CCList: [ESSender?] = []
    var BCCList: [ESSender?] = []
    public var Time: Double
    public var Size: Int
    public var IsEncrypted: Int
    public var ExpirationTime: Date?
    public var IsReplied: Int
    public var IsRepliedAll: Int
    public var IsForwarded: Int
    public var SpamScore: Int?
    public var AddressID: String?   //needed for decryption
    public var NumAttachments: Int
    public var Flags: Int
    public var LabelIDs: Set<String>
    public var ExternalID: String?
    //public var unsubscribeMethods: String?
    
    //variables that are fetched with getMessageDetails
    //public var attachments: Set<Any>
    public var Body: String?
    public var Header: String?
    public var MIMEType: String?
    //public var ParsedHeaders: String? //String or class?
    public var UserID: String?

    //local variables
    public var Starred: Bool? = false
    public var isDetailsDownloaded: Bool? = false
    //var tempAtts: [AttachmentInline]? = nil
    
    init(id: String, order: Int, conversationID: String, subject: String, unread: Int, type: Int, senderAddress: String, senderName: String, sender: ESSender, toList: [ESSender?], ccList: [ESSender?], bccList: [ESSender?], time: Double, size: Int, isEncrypted: Int, expirationTime: Date?, isReplied: Int, isRepliedAll: Int, isForwarded: Int, spamScore: Int?, addressID: String?, numAttachments: Int, flags: Int, labelIDs: Set<String>, externalID: String?, body: String?, header: String?, mimeType: String?, userID: String) {
        self.ID = id
        self.Order = order
        self.ConversationID = conversationID
        self.Subject = subject
        self.Unread = unread
        self.`Type` = type
        self.SenderAddress = senderAddress
        self.SenderName = senderName
        self.Sender = sender
        self.ToList = toList
        self.CCList = ccList
        self.BCCList = bccList
        self.Time = time
        self.Size = size
        self.IsEncrypted = isEncrypted
        self.ExpirationTime = expirationTime
        self.IsReplied = isReplied
        self.IsRepliedAll = isRepliedAll
        self.IsForwarded = isForwarded
        self.SpamScore = spamScore
        self.AddressID = addressID
        self.NumAttachments = numAttachments
        self.Flags = flags
        self.LabelIDs = labelIDs
        self.ExternalID = externalID
        self.Body = body
        self.Header = header
        self.MIMEType = mimeType
        self.UserID = userID
    }
    
    /// check if contains exclusive lable
    ///
    /// - Parameter label: Location
    /// - Returns: yes or no
    internal func contains(label: Message.Location) -> Bool {
        return self.contains(label: label.rawValue)
    }
    
    /// check if contains the lable
    ///
    /// - Parameter labelID: label id
    /// - Returns: yes or no
    internal func contains(label labelID : String) -> Bool {
        let labels = self.LabelIDs
        for l in labels {
            //TODO
            if let label = l as? Label, labelID == label.labelID {
                return true
            }
        }
        return false
    }
    
    /// check if message contains a draft label
    var draft : Bool {
        contains(label: Message.Location.draft) || contains(label: Message.HiddenLocation.draft.rawValue)
    }
    
    var flag : Message.Flag? {
        get {
            return Message.Flag(rawValue: self.Flags)
        }
        set {
            self.Flags = newValue!.rawValue
        }
    }
    
    //signed mime also external message
    var isExternal : Bool? {
        get {
            return !self.flag!.contains(.internal) && self.flag!.contains(.received)
        }
    }
    
    // 7  & 8
    var isE2E : Bool? {
        get {
            return self.flag!.contains(.e2e)
        }
    }
    
    var isPlainText : Bool {
        get {
            if let type = MIMEType, type.lowercased() == Message.MimeType.plainText {
                return true
            }
            return false
        }
    }
    
    var isMultipartMixed : Bool {
        get {
            if let type = MIMEType, type.lowercased() == Message.MimeType.mutipartMixed {
                return true
            }
            return false
        }
    }
    
    //case outPGPInline = 7
    var isPgpInline : Bool {
        get {
            if isE2E!, !isPgpMime! {
                return true
            }
            return false
        }
    }
    
    //case outPGPMime = 8       // out pgp mime
    var isPgpMime : Bool? {
        get {
            if let mt = self.MIMEType, mt.lowercased() == Message.MimeType.mutipartMixed, isExternal!, isE2E! {
                return true
            }
            return false
        }
    }
    
    //case outSignedPGPMime = 9 //PGP/MIME signed message
    var isSignedMime : Bool? {
        get {
            if let mt = self.MIMEType, mt.lowercased() == Message.MimeType.mutipartMixed, isExternal!, !isE2E! {
                return true
            }
            return false
        }
    }
    
    public func decryptBody(keys: [Key], passphrase: String) throws -> String? {
        var firstError: Error?
        var errorMessages: [String] = []
        
        for key in keys {
            do {
                return try self.Body!.decryptMessageWithSinglKey(key.privateKey, passphrase: passphrase)
            } catch let error {
                if firstError == nil {
                    firstError = error
                    errorMessages.append(error.localizedDescription)
                }
                //TODO temporary disable to have less output
                //PMLog.D(error.localizedDescription)
            }
        }
        
        let extra: [String: Any] = ["newSchema": false,
                                    "Ks count": keys.count,
                                    "Error message": errorMessages]
        
        if let error = firstError {
            Analytics.shared.error(message: .decryptedMessageBodyFailed,
                                   error: error,
                                   extra: extra)
            throw error
        }
        Analytics.shared.error(message: .decryptedMessageBodyFailed,
                               error: "No error from crypto library",
                               extra: extra)
        return nil
    }
    
    public func decryptBody(keys: [Key], userKeys: [Data], passphrase: String) throws -> String? {
        var firstError: Error?
        var errorMessages: [String] = []
        var newScheme: Int = 0
        var oldSchemaWithToken: Int = 0
        var oldSchema: Int = 0
        
        for key in keys {
            do {
                if let token = key.token, let signature = key.signature{
                    //have both means new schema. key is
                    newScheme += 1
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //TODO:: try to verify signature here Detached signature
                        // if failed return a warning
                        PMLog.D(signature)
                        //TODO
                        return try self.Body!.decryptMessageWithSinglKey(key.privateKey, passphrase: plaitToken)
                    }
                } else if let token = key.token { //old schema with token - subuser. key is embed singed
                    oldSchemaWithToken += 1
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //TODO:: try to verify signature here embeded signature
                        return try self.Body!.decryptMessageWithSinglKey(key.privateKey, passphrase: plaitToken)
                    }
                } else { //normal key old schema
                    oldSchema += 1
                    return try self.Body!.decryptMessage(binKeys: keys.binPrivKeysArray, passphrase: passphrase)
                }
            } catch let error {
                if firstError == nil {
                    firstError = error
                    errorMessages.append(error.localizedDescription)
                }
                //TODO temporary disable to have less output
                //PMLog.D(error.localizedDescription)
            }
        }
        return nil
    }
}

open class DownloadPageAsyncOperation: Operation {
    public enum State: String {
        case ready = "Ready"
        case executing = "Executing"
        case finished = "Finished"
        fileprivate var keyPath: String { return "is" + self.rawValue }
    }
    private var stateStore: State = .ready
    private let stateQueue = DispatchQueue(label: "Async State Queue", attributes: .concurrent)
    public var state: State {
        get {
            stateQueue.sync {
                return stateStore
            }
        }
        set {
            let oldValue = state
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
            stateQueue.sync(flags: .barrier) {
                stateStore = newValue
            }
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }
    
    public let userID: String
    
    init(userID: String) {
        self.userID = userID
    }
    
    public override var isAsynchronous: Bool {
        return true
    }
    
    public override var isExecuting: Bool {
        return state == .executing
    }
    
    public override var isFinished: Bool {
        return state == .finished
    }
    
    public override func start() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .ready
            main()
        }
    }
    
    public override func main() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .executing
        }
        
        EncryptedSearchService.shared.fetchMessages(userID: self.userID, byLabel: Message.Location.allmail.rawValue, time: EncryptedSearchService.shared.lastMessageTimeIndexed) { (error, messages) in
            if error == nil {
                EncryptedSearchService.shared.processPageOneByOne(forBatch: messages, userID: self.userID, completionHandler: {
                    EncryptedSearchService.shared.lastMessageTimeIndexed = Int((messages?.last?.Time)!)
                    self.finish()   //set operation to be finished
                })
            } else {
                print("Error while fetching messages: \(String(describing: error))")
                self.finish()   //set operation to be finished
            }
        }
    }
    
    public func finish() {
        state = .finished
    }
}

open class IndexSingleMessageAsyncOperation: Operation {
    public enum State: String {
        case ready = "Ready"
        case executing = "Executing"
        case finished = "Finished"
        fileprivate var keyPath: String { return "is" + self.rawValue }
    }
    private var stateStore: State = .ready
    private let stateQueue = DispatchQueue(label: "Async State Queue", attributes: .concurrent)
    public var state: State {
        get {
            stateQueue.sync {
                return stateStore
            }
        }
        set {
            let oldValue = state
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
            stateQueue.sync(flags: .barrier) {
                stateStore = newValue
            }
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }
    public let message: ESMessage
    public let userID: String
    
    init(_ message: ESMessage, _ userID: String) {
        self.message = message
        self.userID = userID
    }
    
    public override var isAsynchronous: Bool {
        return true
    }
    
    public override var isExecuting: Bool {
        return state == .executing
    }
    
    public override var isFinished: Bool {
        return state == .finished
    }
    
    public override func start() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .ready
            main()
        }
    }
    
    public override func main() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .executing
        }
        
        EncryptedSearchService.shared.getMessageDetailsForSingleMessage(for: self.message, userID: self.userID) { messageWithDetails in
            EncryptedSearchService.shared.decryptAndExtractDataSingleMessage(for: messageWithDetails!, userID: self.userID) { [weak self] in
                EncryptedSearchService.shared.processedMessages += 1
                self?.state = .finished
            }
        }
    }
    
    public func finish() {
        state = .finished
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
        
        self.internetStatusProvider = InternetConnectionStatusProvider()
        self.internetStatusProvider?.getConnectionStatuses(currentStatus: { status in
        })
        
        //enable temperature monitoring
        self.registerForTermalStateChangeNotifications()
        //enable battery level monitoring
        //self.registerForBatteryLevelChangeNotifications()
        self.registerForPowerStateChangeNotifications()
        
        self.determineEncryptedSearchState()
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
    internal var prevProcessedMessages: Int = 0 //used to calculate estimated time for indexing
    internal var viewModel: SettingsEncryptedSearchViewModel? = nil
    
    internal var searchIndex: Connection? = nil
    internal var cipherForSearchIndex: EncryptedsearchAESGCMCipher? = nil
    internal var lastSearchQuery: String = ""
    internal var cacheSearchResults: EncryptedsearchResultList? = nil
    internal var indexSearchResults: EncryptedsearchResultList? = nil
    internal var searchState: EncryptedsearchSearchState? = nil
    internal var indexBuildingInProgress: Bool = false
    internal var slowDownIndexBuilding: Bool = false
    internal var indexingStartTime: Double = 0
    internal var eventsWhileIndexing: [MessageAction]? = []
    internal lazy var indexBuildingTimer: Timer? = nil
    
    lazy var messageIndexingQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Message Indexing Queue"
        //queue.maxConcurrentOperationCount = 1
        return queue
    }()
    lazy var downloadPageQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Download Page Queue"
        queue.maxConcurrentOperationCount = 1   //download 1 page at a time
        return queue
    }()
    
    internal lazy var internetStatusProvider: InternetConnectionStatusProvider? = nil

    internal var pauseIndexingDueToNetworkConnectivityIssues: Bool = false
    internal var pauseIndexingDueToWiFiNotDetected: Bool = false
    internal var pauseIndexingDueToOverheating: Bool = false
    internal var pauseIndexingDueToLowBattery: Bool = false
    internal var pauseIndexingDueToLowStorage: Bool = false
    internal var numPauses: Int = 0
    internal var numInterruptions: Int = 0
    
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    let timeFormatter = DateComponentsFormatter()
    
    internal var startBackgroundTask: Double = 0.0
    internal var backgroundTaskCounter: Int = 0
    
    internal var fetchMessageCounter: Int = 0
    internal var isFirstSearch: Bool = true
    internal var isFirstIndexingTimeEstimate: Bool = true
    internal var initialIndexingEstimate: Int = 0
    internal var isRefreshed: Bool = false
}

extension EncryptedSearchService {
    func determineEncryptedSearchState(){
        //check if encrypted search is switched on in settings
        if !userCachedStatus.isEncryptedSearchOn {
            self.state = .disabled
            print("ENCRYPTEDSEARCH-STATE: disabled")
        } else {
            if self.pauseIndexingDueToLowStorage {
                self.state = .lowstorage
                print("ENCRYPTEDSEARCH-STATE: lowstorage")
                return
            }
            if self.pauseIndexingDueToOverheating || self.pauseIndexingDueToLowBattery || self.pauseIndexingDueToNetworkConnectivityIssues || self.pauseIndexingDueToWiFiNotDetected {   //TODO paused by user?
                self.state = .paused
                print("ENCRYPTEDSEARCH-STATE: paused")
                return
            }
            if self.indexBuildingInProgress {
                self.state = .downloading
                print("ENCRYPTEDSEARCH-STATE: downloading")
            } else {
                //check if search index exists and the number of messages in the search index
                let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
                let userID: String? = usersManager.firstUser?.userInfo.userId
                if userID == nil {
                    print("Error: userID unknown!")
                    self.state = .undetermined
                    print("ENCRYPTEDSEARCH-STATE: undetermined")
                    return
                }
                if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: userID!) {
                    self.getTotalMessages {
                        let numberOfEntriesInSearchIndex: Int = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID!)
                        if self.totalMessages == numberOfEntriesInSearchIndex {
                            self.state = .complete
                            print("ENCRYPTEDSEARCH-STATE: complete")
                        } else {
                            self.state = .partial
                            print("ENCRYPTEDSEARCH-STATE: partial")
                        }
                    }
                } else {
                    print("Error search index does not exist for user!")
                    self.state = .undetermined
                    print("ENCRYPTEDSEARCH-STATE: undetermined")
                }
            }
            //TODO refresh?
            //self.state = .refresh
        }
    }

    //function to build the search index needed for encrypted search
    func buildSearchIndex(_ viewModel: SettingsEncryptedSearchViewModel) -> Void {
        //determine actual state
        self.determineEncryptedSearchState()

        let networkStatus: NetworkStatus = self.internetStatusProvider!.currentStatus
        if !networkStatus.isConnected {
            print("Error when building the search index - no internet connection.")
            self.pauseIndexingDueToNetworkConnectivityIssues = true
            self.pauseAndResumeIndexingDueToInterruption(isPause: true)
            return
        }
        if !viewModel.downloadViaMobileData && !(networkStatus == NetworkStatus.ReachableViaWiFi) {
            print("Indexing with mobile data not enabled")
            self.pauseIndexingDueToWiFiNotDetected = true
            self.pauseAndResumeIndexingDueToInterruption(isPause: true)
            return
        }

        #if !APP_EXTENSION
            //enable background processing
            self.continueIndexingInBackground()   //pre ios-13 background task for 30 seconds

            if #available(iOS 13, *) {
                self.scheduleNewAppRefreshTask()
                self.scheduleNewBGProcessingTask()
            }
        #endif
        
        self.state = .downloading
        print("ENCRYPTEDSEARCH-STATE: downloading")
        
        //add a notification when app is put in background
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)

        self.indexBuildingInProgress = true
        self.viewModel = viewModel
        let uid: String? = self.updateCurrentUserIfNeeded()    //check that we have the correct user selected
        if let userID = uid {
            //check if search index db exists - and if not create it
            EncryptedSearchIndexService.shared.createSearchIndexDBIfNotExisting(for: userID)

            //set up timer to estimate time for index building every 2 seconds
            self.indexingStartTime = CFAbsoluteTimeGetCurrent()
            self.indexBuildingTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.updateRemainingIndexingTime), userInfo: nil, repeats: true)

            self.getTotalMessages() {
                print("Total messages: ", self.totalMessages)
                
                //check if search index needs updating
                if EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID) == self.totalMessages {
                    self.state = .complete
                    print("ENCRYPTEDSEARCH-STATE: complete")
                    self.cleanUpAfterIndexing()
                    return
                }

                //build search index completely new
                DispatchQueue.global(qos: .userInitiated).async {
                    self.downloadAndProcessPage(userID: userID){ [weak self] in
                        self?.checkIfIndexingIsComplete {
                            self?.cleanUpAfterIndexing()
                        }
                        return
                    }
                }
            }
        } else {
            print("User ID unknown!")
        }
    }
    
    func checkIfIndexingIsComplete(completionHandler: @escaping () -> Void) {
        self.getTotalMessages() {
            let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
            let userID: String = (usersManager.firstUser?.userInfo.userId)!
            if EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID) == self.totalMessages {
                self.state = .complete
                print("ENCRYPTEDSEARCH-STATE: complete")
                self.cleanUpAfterIndexing()
            }
            completionHandler()
        }
    }
    
    //called when indexing is complete
    func cleanUpAfterIndexing() {
        if self.state == .complete {
            let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
            let userID: String = (usersManager.firstUser?.userInfo.userId)!

            // set some status variables
            self.viewModel?.isEncryptedSearch = true
            self.viewModel?.currentProgress.value = 100
            self.viewModel?.estimatedTimeRemaining.value = 0
            self.indexBuildingInProgress = false

            // Invalidate timer
            self.indexBuildingTimer?.invalidate()

            // Stop background tasks
            #if !APP_EXTENSION
                if self.backgroundTask != .invalid {
                    //background processing not needed any longer - clean up
                    self.endBackgroundTask()
                }
                if #available(iOS 13, *) {
                    //index building finished - we no longer need a background task
                    self.cancelBGProcessingTask()
                    self.cancelBGAppRefreshTask()
                }
            #endif

            // Send indexing metrics to backend
            self.sendIndexingMetrics(indexTime: self.indexingStartTime - CFAbsoluteTimeGetCurrent(), userID: userID)

            // Compress sqlite database
            DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                EncryptedSearchIndexService.shared.compressSearchIndex(for: userID)
            }

            // Update UI
            self.updateUIIndexingComplete()
        }
    }
    
    func pauseAndResumeIndexingByUser(isPause: Bool, completionHandler: @escaping () -> Void = {}){
        if isPause {
            self.numPauses += 1
            self.state = .paused
            print("ENCRYPTEDSEARCH-STATE: paused")
        } else {
            self.state = .downloading
            print("ENCRYPTEDSEARCH-STATE: downloading")
        }
        self.pauseAndResumeIndexing(completionHandler: completionHandler)
    }
    
    func pauseAndResumeIndexingDueToInterruption(isPause: Bool, completionHandler: @escaping () -> Void = {}){
        if isPause {
            self.numInterruptions += 1
            self.state = .paused
            print("ENCRYPTEDSEARCH-STATE: paused")
        } else {
            //print("Resume indexing. Flags: overheating: \(self.pauseIndexingDueToOverheating), lowbattery: \(self.pauseIndexingDueToLowBattery), network: \(self.pauseIndexingDueToNetworkConnectivityIssues), wifi: \(self.pauseIndexingDueToWiFiNotDetected), storage: \(self.pauseIndexingDueToLowStorage)")
            //check if any of the flags is set to true
            if self.pauseIndexingDueToLowBattery || self.pauseIndexingDueToNetworkConnectivityIssues || self.pauseIndexingDueToOverheating || self.pauseIndexingDueToLowStorage || self.pauseIndexingDueToWiFiNotDetected {
                self.state = .paused
                print("ENCRYPTEDSEARCH-STATE: paused")

                completionHandler()
                return
            }
        }
        
        self.pauseAndResumeIndexing(completionHandler: completionHandler)
    }
    
    func pauseAndResumeIndexing(completionHandler: @escaping () -> Void = {}) {
        let uid: String? = self.updateCurrentUserIfNeeded()
        if let userID = uid {
            if self.state == .paused {  //pause indexing
                print("Pause indexing!")
                self.messageIndexingQueue.cancelAllOperations()
                self.indexBuildingInProgress = false

                self.updateUIWithIndexingStatus()
            } else {    //resume indexing
                print("Resume indexing...")
                self.indexBuildingInProgress = true
                self.state = .downloading
                print("ENCRYPTEDSEARCH-STATE: downloading")
                self.indexBuildingTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.updateRemainingIndexingTime), userInfo: nil, repeats: true)

                self.downloadAndProcessPage(userID: userID){
                    self.viewModel?.isEncryptedSearch = true
                    self.viewModel?.currentProgress.value = 100
                    self.viewModel?.estimatedTimeRemaining.value = 0
                    self.indexBuildingInProgress = false
                    completionHandler()
                }
            }
        } else {
            print("Error in pauseAndResume Indexing. User unknown!")
            completionHandler()
        }
    }
    
    func pauseIndexingDueToNetworkSwitch(){
        let networkStatus: NetworkStatus = self.internetStatusProvider!.currentStatus
        if !networkStatus.isConnected {
            print("Error no internet connection.")
            return
        }

        //if indexing is currently in progress
        //and the slider is off
        //and we are using mobile data
        //then pause indexing
        if self.indexBuildingInProgress && !self.viewModel!.downloadViaMobileData && (networkStatus != NetworkStatus.ReachableViaWiFi) {
            print("Pause indexing when using mobile data")
            self.pauseAndResumeIndexingDueToInterruption(isPause: true)
        }
    }
    
    struct MessageAction {
        var action: NSFetchedResultsChangeType? = nil
        var message: Message? = nil
        var indexPath: IndexPath? = nil
        var newIndexPath: IndexPath? = nil
    }
    
    func updateSearchIndex(_ action: NSFetchedResultsChangeType, _ message: Message?, _ indexPath: IndexPath?, _ newIndexPath: IndexPath?) {
        if self.indexBuildingInProgress {
            let messageAction: MessageAction = MessageAction(action: action, message: message, indexPath: indexPath, newIndexPath: newIndexPath)
            self.eventsWhileIndexing!.append(messageAction)
        } else {
            switch action {
                case .delete:
                    self.updateMessageMetadataInSearchIndex(message, action, indexPath, newIndexPath)
                case .insert:
                    self.insertSingleMessageToSearchIndex(message)
                case .move:
                    //TODO implement
                    break
                case .update:
                    //TODO implement
                    break
                default:
                    return
            }
        }
    }
    
    func processEventsAfterIndexing(completionHandler: @escaping () -> Void) {
        if self.eventsWhileIndexing!.isEmpty {
            completionHandler()
        } else {
            let messageAction: MessageAction = self.eventsWhileIndexing!.removeFirst()
            self.updateSearchIndex(messageAction.action!, messageAction.message, messageAction.indexPath, messageAction.newIndexPath)
            self.processEventsAfterIndexing {
                print("Events remainding to process: \(self.eventsWhileIndexing!.count)")
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
        } else {
            print("Error when deleting message from search index. User unknown!")
        }
    }
    
    func deleteSearchIndex(){
        let users: UsersManager = sharedServices.get(by: UsersManager.self)
        let uid: String? = users.firstUser?.userInfo.userId
        if let userID = uid {
            //just delete the search index if it exists
            if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: userID) {
                let result: Bool = EncryptedSearchIndexService.shared.deleteSearchIndex(for: userID)
                self.totalMessages = -1
                self.processedMessages = 0
                self.lastMessageTimeIndexed = 0
                self.prevProcessedMessages = 0
                self.indexingStartTime = 0
                self.indexBuildingInProgress = false
                self.indexBuildingTimer?.invalidate()   //stop timer to estimate remaining time for indexing
                
                //cancel background tasks
                if #available(iOS 13.0, *) {
                    self.cancelBGProcessingTask()
                    self.cancelBGAppRefreshTask()
                }
                
                //update state
                self.state = .disabled
                print("ENCRYPTEDSEARCH-STATE: disabled")
                
                //update viewmodel
                self.viewModel?.isEncryptedSearch = false
                self.viewModel?.currentProgress.value = 0
                self.viewModel?.estimatedTimeRemaining.value = 0
                
                if result {
                    print("Search index for user \(userID) sucessfully deleted!")
                }
            }
        } else {
            print("Error when deleting the search index. User unknown!")
        }
    }
    
    func updateMessageMetadataInSearchIndex(_ message: Message?, _ action: NSFetchedResultsChangeType, _ indexPath: IndexPath?, _ newIndexPath: IndexPath?) {
        guard let messageToUpdate = message else {
            return
        }
        let users: UsersManager = sharedServices.get(by: UsersManager.self)
        let uid: String? = users.firstUser?.userInfo.userId
        if let userID = uid {
            if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: userID){
                switch action {
                case .delete:
                    print("DELETE: message location: \(messageToUpdate.getLabelIDs())")
                    break
                case .move:
                    //TODO implement
                    break
                case .update:
                    //TODO implement
                    break
                default:
                    break
                }
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
    func getTotalMessages(completionHandler: @escaping () -> Void) -> Void {
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
    
    private func convertMessageToESMessage(for message: Message) -> ESMessage {
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
    
    public func fetchSingleMessageFromServer(byMessageID messageID: String, completionHandler: ((Error?) -> Void)?) -> Void {
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
        self.fetchMessageCounter += 1
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

    func downloadAndProcessPage(userID: String, completionHandler: @escaping () -> Void) -> Void {
        let group = DispatchGroup()
        group.enter()
        self.downloadPage(userID: userID) {
            print("Processed messages: \(self.processedMessages)")
            group.leave()
        }
        
        group.notify(queue: .main) {
            if self.processedMessages >= self.totalMessages {
                completionHandler()
            } else {
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
    
    func downloadPage(userID: String, completionHandler: @escaping () -> Void){
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
        //start a new thread to process the page
        DispatchQueue.global(qos: .userInitiated).async {
            for m in messages! {
                autoreleasepool {
                    var op: Operation? = IndexSingleMessageAsyncOperation(m, userID)
                    self.messageIndexingQueue.addOperation(op!)
                    op = nil    //clean up
                }
            }
            self.messageIndexingQueue.waitUntilAllOperationsAreFinished()
            //clean up
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
    
    private func parseMessageObjectFromResponse(for response: [String : Any]) -> Message? {
        var message: Message? = nil
        do {
            message = try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: response, in: (self.messageService?.coreDataService.operationContext)!) as? Message
            message!.messageStatus = 1
            message!.isDetailDownloaded = true
        } catch {
            print("Error when parsing message object: \(error)")
        }
        return message
    }

    //TODO reset fetch controller managed object context?
    func getMessage(_ messageID: String, completionHandler: @escaping (Message?) -> Void) -> Void {
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
    
    private func decryptBodyIfNeeded(message: ESMessage) throws -> String? {
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
        
        let _: Int64? = EncryptedSearchIndexService.shared.addNewEntryToSearchIndex(for: userID, messageID: message.ID, time: time, labelIDs: message.LabelIDs, isStarred: message.Starred!, unread: (message.Unread != 0), location: location, order: order, hasBody: hasBody, decryptionFailed: decryptionFailed, encryptionIV: iv, encryptedContent: ciphertext, encryptedContentFile: "")
    }

    //Encrypted Search
    #if !APP_EXTENSION
    func search(_ query: String, page: Int, searchViewModel: SearchViewModel, completion: ((NSError?) -> Void)?) {
        print("encrypted search on client side!")
        print("Query: ", query)
        print("Page: ", page)
        
        if query == "" {
            self.isFirstSearch = false
            completion!(nil) //There are no results for an empty search query
        }
        
        //update necessary variables needed
        let uid: String? = self.updateCurrentUserIfNeeded()
        if let userID = uid {
            var cleanedQuery: String = ""
            cleanedQuery = query    //cleaning is now done in es go code
            //normalize search query using NFKC
            //cleanedQuery = query.precomposedStringWithCompatibilityMapping
            //print("Query (normalized): ", cleanedQuery)
            
            //remove character distinctions such as case insensitivity, width insensitivity and diacritics
            //use system locale
            //cleanedQuery = query.folding(options: [.caseInsensitive, .widthInsensitive, .diacriticInsensitive], locale: nil)
            //print("Query (character distinctions removed): ", cleanedQuery)
            
            //If there is a new search query, then trigger new search
            let startSearch: Double = CFAbsoluteTimeGetCurrent()
            let searcher: EncryptedsearchSimpleSearcher = self.getSearcher(cleanedQuery)
            let cipher: EncryptedsearchAESGCMCipher = self.getCipher(userID: userID)
            let cache: EncryptedsearchCache? = self.getCache(cipher: cipher, userID: userID)
            self.searchState = EncryptedsearchSearchState()
            
            print("Test cache: \(cache!.getLength())")
                
            let numberOfResultsFoundByCachedSearch: Int = self.doCachedSearch(searcher: searcher, cache: cache!, searchState: &self.searchState, searchViewModel: searchViewModel)
            print("Results found by cache search: ", numberOfResultsFoundByCachedSearch)
                
            //Check if there are enough results from the cached search
            let searchResultPageSize: Int = 15
            var numberOfResultsFoundByIndexSearch: Int = 0
            if !self.searchState!.isComplete && numberOfResultsFoundByCachedSearch <= searchResultPageSize {
                numberOfResultsFoundByIndexSearch = self.doIndexSearch(searcher: searcher, cipher: cipher, searchState: &self.searchState, resultsFoundInCache: numberOfResultsFoundByCachedSearch, userID: userID)
            }
            print("Results found by index search: ", numberOfResultsFoundByIndexSearch)
            let endSearch: Double = CFAbsoluteTimeGetCurrent()
            print("Search finished. Time: \(endSearch-startSearch)")
                
            //send some search metrics
            self.sendSearchMetrics(searchTime: endSearch-startSearch, cache: cache, userID: userID)
        } else {
            print("Error when searching. User unknown!")
        }
    }
    #endif

    func extractSearchResults(_ searchResults: EncryptedsearchResultList, _ page: Int, completionHandler: @escaping ([Message]?) -> Void) -> Void {
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
    
    func getSearcher(_ query: String) -> EncryptedsearchSimpleSearcher {
        let contextSize: CLong = 50 // The max size of the content showed in the preview
        let keywords: EncryptedsearchStringList? = createEncryptedSearchStringList(query)   //split query into individual keywords

        let searcher: EncryptedsearchSimpleSearcher = EncryptedsearchSimpleSearcher(keywords, contextSize: contextSize)!
        return searcher
    }
    
    func getCache(cipher: EncryptedsearchAESGCMCipher, userID: String) -> EncryptedsearchCache {
        let dbParams: EncryptedsearchDBParams = EncryptedSearchIndexService.shared.getDBParams(userID)
        let cache: EncryptedsearchCache? = EncryptedSearchCacheService.shared.buildCacheForUser(userId: userID, dbParams: dbParams, cipher: cipher)
        return cache!
    }
    
    func createEncryptedSearchStringList(_ query: String) -> EncryptedsearchStringList {
        let result: EncryptedsearchStringList? = EncryptedsearchStringList()
        let searchQueryArray: [String] = query.components(separatedBy: " ")
        searchQueryArray.forEach { q in
            result?.add(q)
        }
        return result!
    }
    
    func doIndexSearch(searcher: EncryptedsearchSimpleSearcher, cipher: EncryptedsearchAESGCMCipher, searchState: inout EncryptedsearchSearchState?, resultsFoundInCache:Int, userID: String) -> Int {
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
            do {
                self.indexSearchResults = EncryptedsearchResultList()
                self.indexSearchResults = try index.searchNewBatch(fromDB: searcher, cipher: cipher, state: searchState, batchSize: batchSize)
                resultsFound += self.indexSearchResults!.length()
            } catch {
                print("Error while searching... ", error)
            }
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
    
    #if !APP_EXTENSION
    func doCachedSearch(searcher: EncryptedsearchSimpleSearcher, cache: EncryptedsearchCache, searchState: inout EncryptedsearchSearchState?, searchViewModel: SearchViewModel) -> Int {
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
            
            //visualize intemediate results
            self.publishIntermediateResults(searchResults: newResults, searchViewModel: searchViewModel)
            
            let endCacheSearch: Double = CFAbsoluteTimeGetCurrent()
            print("Cache batch \(batchCount) search: \(endCacheSearch-startCacheSearch) seconds, batchSize: \(batchSize)")
            batchCount += 1
        }
        return found
    }
    #endif
    
    func getIndex(userID: String) -> EncryptedsearchIndex {
        let dbParams: EncryptedsearchDBParams = EncryptedSearchIndexService.shared.getDBParams(userID)
        let index: EncryptedsearchIndex = EncryptedsearchIndex(dbParams)!
        return index
    }
    
    #if !APP_EXTENSION
    private func publishIntermediateResults(searchResults: EncryptedsearchResultList?, searchViewModel: SearchViewModel){
        //TODO do I need the page here?
        self.extractSearchResults(searchResults!, 0) { messageBatch in
            let messages: [Message.ObjectIDContainer]? = messageBatch!.map(ObjectBox.init)
            searchViewModel.displayIntermediateSearchResults(messageBoxes: messages)
        }
    }
    #endif
    
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
    func getCurrentlyAvailableAppMemory() -> Double {
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
    
    func updateIndexBuildingProgress(processedMessages: Int){
        //progress bar runs from 0 to 1 - normalize by totalMessages
        let updateStep: Float = Float(processedMessages)/Float(self.totalMessages)
        self.viewModel?.currentProgress.value = Int(updateStep)
    }
    
    @available(iOSApplicationExtension, unavailable, message: "This method is NS_EXTENSION_UNAVAILABLE")
    func updateUIWithProgressBarStatus(){
        DispatchQueue.main.async {
            switch UIApplication.shared.applicationState {
            case .active:
                self.updateIndexBuildingProgress(processedMessages: self.processedMessages)
            case .background:
                print("Background time remaining = \(self.timeFormatter.string(from: UIApplication.shared.backgroundTimeRemaining)!)")
            case .inactive:
                break
            @unknown default:
                print("Unknown state. What to do?")
            }
        }
    }
    
    func updateUIWithIndexingStatus() {
        if self.pauseIndexingDueToNetworkConnectivityIssues {
            self.viewModel?.interruptStatus.value = LocalString._encrypted_search_download_paused_no_connectivity
            self.viewModel?.interruptAdvice.value = LocalString._encrypted_search_download_paused_no_connectivity_status
        }
        if self.pauseIndexingDueToWiFiNotDetected {
            self.viewModel?.interruptStatus.value = LocalString._encrypted_search_download_paused_no_wifi
            self.viewModel?.interruptAdvice.value = LocalString._encrypted_search_download_paused_no_wifi_status
        }
        if self.pauseIndexingDueToLowBattery {
            self.viewModel?.interruptStatus.value = LocalString._encrypted_search_download_paused_low_battery
            self.viewModel?.interruptAdvice.value = LocalString._encrypted_search_download_paused_low_battery_status
        }
        if self.pauseIndexingDueToLowStorage {
            self.viewModel?.interruptStatus.value = LocalString._encrypted_search_download_paused_low_storage
            self.viewModel?.interruptAdvice.value = LocalString._encrypted_search_download_paused_low_storage_status
        }
    }
    
    //This triggers the viewcontroller to reload the tableview when indexing is complete
    internal func updateUIIndexingComplete() {
        self.viewModel?.isIndexingComplete.value = true
    }
    
    private func registerForBatteryLevelChangeNotifications() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(responseToBatteryLevel(_:)), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
    }
    
    private func registerForPowerStateChangeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(responseToLowPowerMode(_:)), name: NSNotification.Name.NSProcessInfoPowerStateDidChange, object: nil)
    }
    
    @objc private func responseToLowPowerMode(_ notification: Notification) {
        if ProcessInfo.processInfo.isLowPowerModeEnabled && !self.pauseIndexingDueToLowBattery {
            // Low power mode is enabled - pause indexing
            print("Pause indexing due to low battery!")
            self.pauseAndResumeIndexingDueToInterruption(isPause: true)
        } else if !ProcessInfo.processInfo.isLowPowerModeEnabled && self.pauseIndexingDueToLowBattery {
            // Low power mode is disabled - continue indexing
            print("Resume indexing as battery is charged again!")
            self.pauseAndResumeIndexingDueToInterruption(isPause: false)
        }
    }
    
    @objc private func responseToBatteryLevel(_ notification: Notification) {
        //if battery is low (Android < 15%), (iOS < 20%) we pause indexing
        let batteryLevel: Float = UIDevice.current.batteryLevel
        if batteryLevel < 0.2 && !self.pauseIndexingDueToLowBattery {   //if battery is < 20% and indexing is not already paused - then pause
            print("Pause indexing due to low battery!")
            self.pauseAndResumeIndexingDueToInterruption(isPause: true)
        } else if batteryLevel >= 0.2 && self.pauseIndexingDueToLowBattery {    // if battery >= 20% and indexing is paused - then resume
            print("Resume indexing as battery is charged again!")
            self.pauseAndResumeIndexingDueToInterruption(isPause: false)
        }
    }
    
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
    
    private func checkIfEnoughStorage() {
        let remainingStorageSpace = self.getCurrentlyAvailableAppMemory()
        print("Current storage space: \(remainingStorageSpace)")
        if remainingStorageSpace < 100 {
            self.pauseIndexingDueToLowStorage = true
            self.pauseAndResumeIndexingDueToInterruption(isPause: true)
        }
    }
    
    func estimateIndexingTime() -> (estimatedMinutes: Int, currentProgress: Int){
        var estimatedMinutes: Int = 0
        var currentProgress: Int = 0
        let currentTime: Double = CFAbsoluteTimeGetCurrent()
        let minute: Double = 60_000.0

        if self.totalMessages != 0 && currentTime != self.indexingStartTime && self.processedMessages != self.prevProcessedMessages {
            let remainingMessages: Double = Double(self.totalMessages - self.processedMessages)
            let timeDifference: Double = currentTime-self.indexingStartTime
            let processedMessageDifference: Double = Double(self.processedMessages-self.prevProcessedMessages)
            estimatedMinutes = Int(ceil(((timeDifference/processedMessageDifference)*remainingMessages)/minute))
            currentProgress = Int(ceil((Double(self.processedMessages)/Double(self.totalMessages))*100))
            self.prevProcessedMessages = self.processedMessages
        }
        return (estimatedMinutes, currentProgress)
    }
    
    @objc func updateRemainingIndexingTime() {
        let elapsedTime = self.indexingStartTime - CFAbsoluteTimeGetCurrent()
        if self.indexBuildingInProgress && self.processedMessages != self.prevProcessedMessages {
            DispatchQueue.global().async {
                let result = self.estimateIndexingTime()
                
                if self.isFirstIndexingTimeEstimate {
                    let minute: Int = 60_000
                    self.initialIndexingEstimate = result.estimatedMinutes * minute
                    self.isFirstIndexingTimeEstimate = false
                }
                
                //update viewModel
                self.viewModel?.currentProgress.value = result.currentProgress
                self.viewModel?.estimatedTimeRemaining.value = result.estimatedMinutes
                print("Remaining indexing time: \(result.estimatedMinutes)")
                print("Current progress: \(result.currentProgress)")
                print("Indexing rate: \(self.messageIndexingQueue.maxConcurrentOperationCount)")
            }
        }
        
        //check if there is still enought storage left
        self.checkIfEnoughStorage()
    }
    
    func sendNotification(text: String){
        let content = UNMutableNotificationContent()
        content.title = "Background Processing Task"
        content.subtitle = text
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    @objc func appMovedToBackground(){
        print("App moved to background")
        if self.indexBuildingInProgress {
            self.sendNotification(text: "Index building is in progress... Please tap to resume index building in foreground.")
        }
    }
    
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
                                               "searchTime"         : searchTime]
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
                //TODO disabled in the meantime to not spam production
                //self.apiService?.metrics(log: "encrypted_search", title: title, data: data, completion: completion)
            }
        } else {
            //TODO disabled in the meantime to not spam production
            //self.apiService?.metrics(log: "encrypted_search", title: title, data: data, completion: completion)
        }
    }
    
    // Called to slow down indexing - so that a user can normally use the app
    func slowDownIndexing(){
        print("ES: Slow down indexing...")
        if self.indexBuildingInProgress && !self.slowDownIndexBuilding {
            self.messageIndexingQueue.maxConcurrentOperationCount = 10
            self.slowDownIndexBuilding = true
        }
    }
    
    // speed up indexing again when in foreground
    func speedUpIndexing(){
        print("ES: Speed up indexing...")
        if self.indexBuildingInProgress && self.slowDownIndexBuilding {
            self.messageIndexingQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
            self.slowDownIndexBuilding = false
        }
    }
    
    // MARK: - Background Tasks
    //pre-ios 13 background tasks
    @available(iOSApplicationExtension, unavailable, message: "This method is NS_EXTENSION_UNAVAILABLE")
    private func continueIndexingInBackground() {
        self.state = .background
        print("ENCRYPTEDSEARCH-STATE: background")
        self.backgroundTask = UIApplication.shared.beginBackgroundTask(){ [weak self] in
            self?.endBackgroundTask()
        }
    }

    //pre-ios 13 background tasks
    @available(iOSApplicationExtension, unavailable, message: "This method is NS_EXTENSION_UNAVAILABLE")
    private func endBackgroundTask() {
        if self.state != .complete {
            print("ENCRYPTEDSEARCH-STATE: backgroundStopped")
            self.state = .backgroundStopped
            self.pauseAndResumeIndexingDueToInterruption(isPause: true)
        }
        UIApplication.shared.endBackgroundTask(self.backgroundTask)
        self.backgroundTask = .invalid
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
            print("ENCRYPTEDSEARCH-STATE: backgroundStopped")

            //send notification - debugging - TODO remove
            self.sendNotification(text: "BGPROCESSING-TASK stop indexing in BG")
        }

        //index is build in foreground - no need for a background task
        if self.state == .downloading {
            task.setTaskCompleted(success: true)
        } else {
            self.state = .background
            print("ENCRYPTEDSEARCH-STATE: background")

            //send a notification - debugging - TODO remove
            self.sendNotification(text: "BGPROCESSING-TASK start indexing in BG")

            //start indexing in background
            self.pauseAndResumeIndexingDueToInterruption(isPause: false) {
                //if indexing is finshed during background task - set to complete
                self.state = .complete
                print("ENCRYPTEDSEARCH-STATE: complete")
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
    func cancelBGAppRefreshTask() {
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
            print("ENCRYPTEDSEARCH-STATE: backgroundStopped")
            
            //send notification - debugging - TODO remove
            self.sendNotification(text: "BGAPPREFRESH-TASK stop indexing in BG")
        }
        
        //index is build in foreground - no need for a background task
        if self.state == .downloading {
            task.setTaskCompleted(success: true)
        } else {
            self.state = .background
            print("ENCRYPTEDSEARCH-STATE: background")

            //send a notification - debugging - TODO remove
            self.sendNotification(text: "BGAPPREFRESH-TASK start indexing in BG")

            //start indexing in background
            self.pauseAndResumeIndexingDueToInterruption(isPause: false) {
                //if indexing is finshed during background task - set to complete
                self.state = .complete
                print("ENCRYPTEDSEARCH-STATE: complete")
                task.setTaskCompleted(success: true)
            }
        }
    }
}
