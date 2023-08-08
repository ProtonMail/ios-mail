// Generated using Sourcery 1.9.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import CoreData
import LocalAuthentication
import ProtonCore_Crypto
import ProtonCore_Environment
import ProtonCore_Keymaker
import ProtonCore_PaymentsUI
import ProtonCore_Services
import ProtonCore_TestingToolkit

import class PromiseKit.Promise
import class ProtonCore_DataModel.UserInfo

@testable import ProtonMail

class MockAppRatingStatusProvider: AppRatingStatusProvider {
    @FuncStub(MockAppRatingStatusProvider.isAppRatingEnabled, initialReturn: Bool()) var isAppRatingEnabledStub
    func isAppRatingEnabled() -> Bool {
        isAppRatingEnabledStub()
    }

    @FuncStub(MockAppRatingStatusProvider.setIsAppRatingEnabled) var setIsAppRatingEnabledStub
    func setIsAppRatingEnabled(_ value: Bool) {
        setIsAppRatingEnabledStub(value)
    }

    @FuncStub(MockAppRatingStatusProvider.hasAppRatingBeenShownInCurrentVersion, initialReturn: Bool()) var hasAppRatingBeenShownInCurrentVersionStub
    func hasAppRatingBeenShownInCurrentVersion() -> Bool {
        hasAppRatingBeenShownInCurrentVersionStub()
    }

    @FuncStub(MockAppRatingStatusProvider.setAppRatingAsShownInCurrentVersion) var setAppRatingAsShownInCurrentVersionStub
    func setAppRatingAsShownInCurrentVersion() {
        setAppRatingAsShownInCurrentVersionStub()
    }

}

class MockAppRatingWrapper: AppRatingWrapper {
    @FuncStub(MockAppRatingWrapper.requestAppRating) var requestAppRatingStub
    func requestAppRating() {
        requestAppRatingStub()
    }

}

class MockBackendConfigurationCacheProtocol: BackendConfigurationCacheProtocol {
    @FuncStub(MockBackendConfigurationCacheProtocol.readEnvironment, initialReturn: nil) var readEnvironmentStub
    func readEnvironment() -> Environment? {
        readEnvironmentStub()
    }

    @FuncStub(MockBackendConfigurationCacheProtocol.write) var writeStub
    func write(environment: Environment) {
        writeStub(environment)
    }

}

class MockBlockedSenderCacheUpdaterDelegate: BlockedSenderCacheUpdaterDelegate {
    @FuncStub(MockBlockedSenderCacheUpdaterDelegate.blockedSenderCacheUpdater) var blockedSenderCacheUpdaterStub
    func blockedSenderCacheUpdater(_ blockedSenderCacheUpdater: BlockedSenderCacheUpdater, didEnter newState: BlockedSenderCacheUpdater.State) {
        blockedSenderCacheUpdaterStub(blockedSenderCacheUpdater, newState)
    }

}

class MockBlockedSenderFetchStatusProviderProtocol: BlockedSenderFetchStatusProviderProtocol {
    @FuncStub(MockBlockedSenderFetchStatusProviderProtocol.checkIfBlockedSendersAreFetched, initialReturn: Bool()) var checkIfBlockedSendersAreFetchedStub
    func checkIfBlockedSendersAreFetched(userID: UserID) -> Bool {
        checkIfBlockedSendersAreFetchedStub(userID)
    }

    @FuncStub(MockBlockedSenderFetchStatusProviderProtocol.markBlockedSendersAsFetched) var markBlockedSendersAsFetchedStub
    func markBlockedSendersAsFetched(userID: UserID) {
        markBlockedSendersAsFetchedStub(userID)
    }

}

class MockBundleType: BundleType {
    @PropertyStub(\MockBundleType.preferredLocalizations, initialGet: [String]()) var preferredLocalizationsStub
    var preferredLocalizations: [String] {
        preferredLocalizationsStub()
    }

    @FuncStub(MockBundleType.setLanguage) var setLanguageStub
    func setLanguage(with code: String, isLanguageRTL: Bool) {
        setLanguageStub(code, isLanguageRTL)
    }

}

class MockCacheServiceProtocol: CacheServiceProtocol {
    @FuncStub(MockCacheServiceProtocol.addNewLabel) var addNewLabelStub
    func addNewLabel(serverResponse: [String: Any], objectID: String?, completion: (() -> Void)?) {
        addNewLabelStub(serverResponse, objectID, completion)
    }

    @FuncStub(MockCacheServiceProtocol.updateLabel) var updateLabelStub
    func updateLabel(serverReponse: [String: Any], completion: (() -> Void)?) {
        updateLabelStub(serverReponse, completion)
    }

    @FuncStub(MockCacheServiceProtocol.deleteLabels) var deleteLabelsStub
    func deleteLabels(objectIDs: [NSManagedObjectID], completion: (() -> Void)?) {
        deleteLabelsStub(objectIDs, completion)
    }

    @FuncStub(MockCacheServiceProtocol.updateContactDetail) var updateContactDetailStub
    func updateContactDetail(serverResponse: [String: Any], completion: ((ContactEntity?, NSError?) -> Void)?) {
        updateContactDetailStub(serverResponse, completion)
    }

    @ThrowingFuncStub(MockCacheServiceProtocol.parseMessagesResponse) var parseMessagesResponseStub
    func parseMessagesResponse(labelID: LabelID, isUnread: Bool, response: [String: Any], idsOfMessagesBeingSent: [String]) throws {
        try parseMessagesResponseStub(labelID, isUnread, response, idsOfMessagesBeingSent)
    }

    @FuncStub(MockCacheServiceProtocol.updateCounterSync) var updateCounterSyncStub
    func updateCounterSync(markUnRead: Bool, on labelIDs: [LabelID]) {
        updateCounterSyncStub(markUnRead, labelIDs)
    }

    @FuncStub(MockCacheServiceProtocol.updateExpirationOffset) var updateExpirationOffsetStub
    func updateExpirationOffset(of messageObjectID: NSManagedObjectID, expirationTime: TimeInterval, pwd: String, pwdHint: String, completion: (() -> Void)?) {
        updateExpirationOffsetStub(messageObjectID, expirationTime, pwd, pwdHint, completion)
    }

}

class MockCachedUserDataProvider: CachedUserDataProvider {
    @FuncStub(MockCachedUserDataProvider.set) var setStub
    func set(disconnectedUsers: [UsersManager.DisconnectedUserHandle]) {
        setStub(disconnectedUsers)
    }

    @FuncStub(MockCachedUserDataProvider.fetchDisconnectedUsers, initialReturn: [UsersManager.DisconnectedUserHandle]()) var fetchDisconnectedUsersStub
    func fetchDisconnectedUsers() -> [UsersManager.DisconnectedUserHandle] {
        fetchDisconnectedUsersStub()
    }

}

class MockContactCacheStatusProtocol: ContactCacheStatusProtocol {
    @PropertyStub(\MockContactCacheStatusProtocol.contactsCached, initialGet: Int()) var contactsCachedStub
    var contactsCached: Int {
        get {
            contactsCachedStub()
        }
        set {
            contactsCachedStub(newValue)
        }
    }

}

class MockContactGroupsProviderProtocol: ContactGroupsProviderProtocol {
    @FuncStub(MockContactGroupsProviderProtocol.getAllContactGroupVOs, initialReturn: [ContactGroupVO]()) var getAllContactGroupVOsStub
    func getAllContactGroupVOs() -> [ContactGroupVO] {
        getAllContactGroupVOsStub()
    }

}

class MockConversationCoordinatorProtocol: ConversationCoordinatorProtocol {
    @PropertyStub(\MockConversationCoordinatorProtocol.pendingActionAfterDismissal, initialGet: nil) var pendingActionAfterDismissalStub
    var pendingActionAfterDismissal: (() -> Void)? {
        get {
            pendingActionAfterDismissalStub()
        }
        set {
            pendingActionAfterDismissalStub(newValue)
        }
    }

    @FuncStub(MockConversationCoordinatorProtocol.handle) var handleStub
    func handle(navigationAction: ConversationNavigationAction) {
        handleStub(navigationAction)
    }

}

class MockConversationProvider: ConversationProvider {
    @FuncStub(MockConversationProvider.fetchConversationCounts) var fetchConversationCountsStub
    func fetchConversationCounts(addressID: String?, completion: ((Result<Void, Error>) -> Void)?) {
        fetchConversationCountsStub(addressID, completion)
    }

    @FuncStub(MockConversationProvider.fetchConversations) var fetchConversationsStub
    func fetchConversations(for labelID: LabelID, before timestamp: Int, unreadOnly: Bool, shouldReset: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        fetchConversationsStub(labelID, timestamp, unreadOnly, shouldReset, completion)
    }

    @FuncStub(MockConversationProvider.fetchConversation) var fetchConversationStub
    func fetchConversation(with conversationID: ConversationID, includeBodyOf messageID: MessageID?, callOrigin: String?, completion: @escaping (Result<Conversation, Error>) -> Void) {
        fetchConversationStub(conversationID, messageID, callOrigin, completion)
    }

    @FuncStub(MockConversationProvider.deleteConversations) var deleteConversationsStub
    func deleteConversations(with conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        deleteConversationsStub(conversationIDs, labelID, completion)
    }

    @FuncStub(MockConversationProvider.markAsRead) var markAsReadStub
    func markAsRead(conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        markAsReadStub(conversationIDs, labelID, completion)
    }

    @FuncStub(MockConversationProvider.markAsUnread) var markAsUnreadStub
    func markAsUnread(conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        markAsUnreadStub(conversationIDs, labelID, completion)
    }

    @FuncStub(MockConversationProvider.label) var labelStub
    func label(conversationIDs: [ConversationID], as labelID: LabelID, isSwipeAction: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        labelStub(conversationIDs, labelID, isSwipeAction, completion)
    }

    @FuncStub(MockConversationProvider.unlabel) var unlabelStub
    func unlabel(conversationIDs: [ConversationID], as labelID: LabelID, isSwipeAction: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        unlabelStub(conversationIDs, labelID, isSwipeAction, completion)
    }

    @FuncStub(MockConversationProvider.move) var moveStub
    func move(conversationIDs: [ConversationID], from previousFolderLabel: LabelID, to nextFolderLabel: LabelID, isSwipeAction: Bool, callOrigin: String?, completion: ((Result<Void, Error>) -> Void)?) {
        moveStub(conversationIDs, previousFolderLabel, nextFolderLabel, isSwipeAction, callOrigin, completion)
    }

    @FuncStub(MockConversationProvider.fetchLocalConversations, initialReturn: [Conversation]()) var fetchLocalConversationsStub
    func fetchLocalConversations(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Conversation] {
        fetchLocalConversationsStub(selected, context)
    }

    @FuncStub(MockConversationProvider.findConversationIDsToApplyLabels, initialReturn: [ConversationID]()) var findConversationIDsToApplyLabelsStub
    func findConversationIDsToApplyLabels(conversations: [ConversationEntity], labelID: LabelID) -> [ConversationID] {
        findConversationIDsToApplyLabelsStub(conversations, labelID)
    }

    @FuncStub(MockConversationProvider.findConversationIDSToRemoveLabels, initialReturn: [ConversationID]()) var findConversationIDSToRemoveLabelsStub
    func findConversationIDSToRemoveLabels(conversations: [ConversationEntity], labelID: LabelID) -> [ConversationID] {
        findConversationIDSToRemoveLabelsStub(conversations, labelID)
    }

}

class MockConversationStateProviderProtocol: ConversationStateProviderProtocol {
    @PropertyStub(\MockConversationStateProviderProtocol.viewMode, initialGet: .conversation) var viewModeStub
    var viewMode: ViewMode {
        get {
            viewModeStub()
        }
        set {
            viewModeStub(newValue)
        }
    }

    @FuncStub(MockConversationStateProviderProtocol.add) var addStub
    func add(delegate: ConversationStateServiceDelegate) {
        addStub(delegate)
    }

}

class MockCopyMessageUseCase: CopyMessageUseCase {
    @ThrowingFuncStub(MockCopyMessageUseCase.execute, initialReturn: .crash) var executeStub
    func execute(parameters: CopyMessage.Parameters) throws -> CopyOutput {
        try executeStub(parameters)
    }

}

class MockDownloadedMessagesRouterProtocol: DownloadedMessagesRouterProtocol {
    @FuncStub(MockDownloadedMessagesRouterProtocol.closeView) var closeViewStub
    func closeView() {
        closeViewStub()
    }

}

class MockDownloadedMessagesUIProtocol: DownloadedMessagesUIProtocol {
    @FuncStub(MockDownloadedMessagesUIProtocol.reloadData) var reloadDataStub
    func reloadData() {
        reloadDataStub()
    }

}

class MockEncryptedSearchDeviceCache: EncryptedSearchDeviceCache {
    @PropertyStub(\MockEncryptedSearchDeviceCache.storageLimit, initialGet: Measurement<UnitInformationStorage>()) var storageLimitStub
    var storageLimit: Measurement<UnitInformationStorage> {
        get {
            storageLimitStub()
        }
        set {
            storageLimitStub(newValue)
        }
    }

    @PropertyStub(\MockEncryptedSearchDeviceCache.pauseIndexingDueToNetworkIssues, initialGet: Bool()) var pauseIndexingDueToNetworkIssuesStub
    var pauseIndexingDueToNetworkIssues: Bool {
        get {
            pauseIndexingDueToNetworkIssuesStub()
        }
        set {
            pauseIndexingDueToNetworkIssuesStub(newValue)
        }
    }

    @PropertyStub(\MockEncryptedSearchDeviceCache.pauseIndexingDueToWifiNotDetected, initialGet: Bool()) var pauseIndexingDueToWifiNotDetectedStub
    var pauseIndexingDueToWifiNotDetected: Bool {
        get {
            pauseIndexingDueToWifiNotDetectedStub()
        }
        set {
            pauseIndexingDueToWifiNotDetectedStub(newValue)
        }
    }

    @PropertyStub(\MockEncryptedSearchDeviceCache.pauseIndexingDueToOverHeating, initialGet: Bool()) var pauseIndexingDueToOverHeatingStub
    var pauseIndexingDueToOverHeating: Bool {
        get {
            pauseIndexingDueToOverHeatingStub()
        }
        set {
            pauseIndexingDueToOverHeatingStub(newValue)
        }
    }

    @PropertyStub(\MockEncryptedSearchDeviceCache.pauseIndexingDueToLowBattery, initialGet: Bool()) var pauseIndexingDueToLowBatteryStub
    var pauseIndexingDueToLowBattery: Bool {
        get {
            pauseIndexingDueToLowBatteryStub()
        }
        set {
            pauseIndexingDueToLowBatteryStub(newValue)
        }
    }

    @PropertyStub(\MockEncryptedSearchDeviceCache.interruptStatus, initialGet: nil) var interruptStatusStub
    var interruptStatus: String? {
        get {
            interruptStatusStub()
        }
        set {
            interruptStatusStub(newValue)
        }
    }

    @PropertyStub(\MockEncryptedSearchDeviceCache.interruptAdvice, initialGet: nil) var interruptAdviceStub
    var interruptAdvice: String? {
        get {
            interruptAdviceStub()
        }
        set {
            interruptAdviceStub(newValue)
        }
    }

}

class MockEncryptedSearchServiceProtocol: EncryptedSearchServiceProtocol {
    @FuncStub(MockEncryptedSearchServiceProtocol.setBuildSearchIndexDelegate) var setBuildSearchIndexDelegateStub
    func setBuildSearchIndexDelegate(for userID: UserID, delegate: BuildSearchIndexDelegate?) {
        setBuildSearchIndexDelegateStub(userID, delegate)
    }

    @FuncStub(MockEncryptedSearchServiceProtocol.indexBuildingState, initialReturn: EncryptedSearchIndexState()) var indexBuildingStateStub
    func indexBuildingState(for userID: UserID) -> EncryptedSearchIndexState {
        indexBuildingStateStub(userID)
    }

    @FuncStub(MockEncryptedSearchServiceProtocol.indexBuildingEstimatedProgress, initialReturn: nil) var indexBuildingEstimatedProgressStub
    func indexBuildingEstimatedProgress(for userID: UserID) -> BuildSearchIndexEstimatedProgress? {
        indexBuildingEstimatedProgressStub(userID)
    }

    @FuncStub(MockEncryptedSearchServiceProtocol.isIndexBuildingComplete, initialReturn: Bool()) var isIndexBuildingCompleteStub
    func isIndexBuildingComplete(for userID: UserID) -> Bool {
        isIndexBuildingCompleteStub(userID)
    }

    @FuncStub(MockEncryptedSearchServiceProtocol.startBuildingIndex) var startBuildingIndexStub
    func startBuildingIndex(for userID: UserID) {
        startBuildingIndexStub(userID)
    }

    @FuncStub(MockEncryptedSearchServiceProtocol.pauseBuildingIndex) var pauseBuildingIndexStub
    func pauseBuildingIndex(for userID: UserID) {
        pauseBuildingIndexStub(userID)
    }

    @FuncStub(MockEncryptedSearchServiceProtocol.resumeBuildingIndex) var resumeBuildingIndexStub
    func resumeBuildingIndex(for userID: UserID) {
        resumeBuildingIndexStub(userID)
    }

    @FuncStub(MockEncryptedSearchServiceProtocol.stopBuildingIndex) var stopBuildingIndexStub
    func stopBuildingIndex(for userID: UserID) {
        stopBuildingIndexStub(userID)
    }

    @FuncStub(MockEncryptedSearchServiceProtocol.didChangeDownloadViaMobileData) var didChangeDownloadViaMobileDataStub
    func didChangeDownloadViaMobileData(for userID: UserID) {
        didChangeDownloadViaMobileDataStub(userID)
    }

    @FuncStub(MockEncryptedSearchServiceProtocol.indexSize, initialReturn: nil) var indexSizeStub
    func indexSize(for userID: UserID) -> Measurement<UnitInformationStorage>? {
        indexSizeStub(userID)
    }

    @FuncStub(MockEncryptedSearchServiceProtocol.oldesMessageTime, initialReturn: nil) var oldesMessageTimeStub
    func oldesMessageTime(for userID: UserID) -> Int? {
        oldesMessageTimeStub(userID)
    }

    @FuncStub(MockEncryptedSearchServiceProtocol.search) var searchStub
    func search(userID: UserID, query: String, page: UInt, completion: @escaping (Result<EncryptedSearchService.SearchResult, Error>) -> Void) {
        searchStub(userID, query, page, completion)
    }

}

class MockEncryptedSearchStateProvider: EncryptedSearchStateProvider {
    @FuncStub(MockEncryptedSearchStateProvider.indexBuildingState, initialReturn: EncryptedSearchIndexState()) var indexBuildingStateStub
    func indexBuildingState(for userID: UserID) -> EncryptedSearchIndexState {
        indexBuildingStateStub(userID)
    }

}

class MockEncryptedSearchUserCache: EncryptedSearchUserCache {
    @FuncStub(MockEncryptedSearchUserCache.isEncryptedSearchOn, initialReturn: Bool()) var isEncryptedSearchOnStub
    func isEncryptedSearchOn(of userID: UserID) -> Bool {
        isEncryptedSearchOnStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.setIsEncryptedSearchOn) var setIsEncryptedSearchOnStub
    func setIsEncryptedSearchOn(of userID: UserID, value: Bool) {
        setIsEncryptedSearchOnStub(userID, value)
    }

    @FuncStub(MockEncryptedSearchUserCache.canDownloadViaMobileData, initialReturn: Bool()) var canDownloadViaMobileDataStub
    func canDownloadViaMobileData(of userID: UserID) -> Bool {
        canDownloadViaMobileDataStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.setCanDownloadViaMobileData) var setCanDownloadViaMobileDataStub
    func setCanDownloadViaMobileData(of userID: UserID, value: Bool) {
        setCanDownloadViaMobileDataStub(userID, value)
    }

    @FuncStub(MockEncryptedSearchUserCache.isAppFreshInstalled, initialReturn: Bool()) var isAppFreshInstalledStub
    func isAppFreshInstalled(of userID: UserID) -> Bool {
        isAppFreshInstalledStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.setIsAppFreshInstalled) var setIsAppFreshInstalledStub
    func setIsAppFreshInstalled(of userID: UserID, value: Bool) {
        setIsAppFreshInstalledStub(userID, value)
    }

    @FuncStub(MockEncryptedSearchUserCache.totalMessages, initialReturn: Int()) var totalMessagesStub
    func totalMessages(of userID: UserID) -> Int {
        totalMessagesStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.setTotalMessages) var setTotalMessagesStub
    func setTotalMessages(of userID: UserID, value: Int) {
        setTotalMessagesStub(userID, value)
    }

    @FuncStub(MockEncryptedSearchUserCache.oldestIndexedMessageTime, initialReturn: Int()) var oldestIndexedMessageTimeStub
    func oldestIndexedMessageTime(of userID: UserID) -> Int {
        oldestIndexedMessageTimeStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.setOldestIndexedMessageTime) var setOldestIndexedMessageTimeStub
    func setOldestIndexedMessageTime(of userID: UserID, value: Int) {
        setOldestIndexedMessageTimeStub(userID, value)
    }

    @FuncStub(MockEncryptedSearchUserCache.lastIndexedMessageID, initialReturn: nil) var lastIndexedMessageIDStub
    func lastIndexedMessageID(of userID: UserID) -> MessageID? {
        lastIndexedMessageIDStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.setLastIndexedMessageID) var setLastIndexedMessageIDStub
    func setLastIndexedMessageID(of userID: UserID, value: MessageID) {
        setLastIndexedMessageIDStub(userID, value)
    }

    @FuncStub(MockEncryptedSearchUserCache.processedMessagesCount, initialReturn: Int()) var processedMessagesCountStub
    func processedMessagesCount(of userID: UserID) -> Int {
        processedMessagesCountStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.setProcessedMessagesCount) var setProcessedMessagesCountStub
    func setProcessedMessagesCount(of userID: UserID, value: Int) {
        setProcessedMessagesCountStub(userID, value)
    }

    @FuncStub(MockEncryptedSearchUserCache.previousProcessedMessagesCount, initialReturn: Int()) var previousProcessedMessagesCountStub
    func previousProcessedMessagesCount(of userID: UserID) -> Int {
        previousProcessedMessagesCountStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.setPreviousProcessedMessagesCount) var setPreviousProcessedMessagesCountStub
    func setPreviousProcessedMessagesCount(of userID: UserID, value: Int) {
        setPreviousProcessedMessagesCountStub(userID, value)
    }

    @FuncStub(MockEncryptedSearchUserCache.indexingPausedByUser, initialReturn: Bool()) var indexingPausedByUserStub
    func indexingPausedByUser(of userID: UserID) -> Bool {
        indexingPausedByUserStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.setIndexingPausedByUser) var setIndexingPausedByUserStub
    func setIndexingPausedByUser(of userID: UserID, value: Bool) {
        setIndexingPausedByUserStub(userID, value)
    }

    @FuncStub(MockEncryptedSearchUserCache.numberOfPauses, initialReturn: Int()) var numberOfPausesStub
    func numberOfPauses(of userID: UserID) -> Int {
        numberOfPausesStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.setNumberOfPauses) var setNumberOfPausesStub
    func setNumberOfPauses(of userID: UserID, value: Int) {
        setNumberOfPausesStub(userID, value)
    }

    @FuncStub(MockEncryptedSearchUserCache.numberOfInterruptions, initialReturn: Int()) var numberOfInterruptionsStub
    func numberOfInterruptions(of userID: UserID) -> Int {
        numberOfInterruptionsStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.setNumberOfInterruptions) var setNumberOfInterruptionsStub
    func setNumberOfInterruptions(of userID: UserID, value: Int) {
        setNumberOfInterruptionsStub(userID, value)
    }

    @FuncStub(MockEncryptedSearchUserCache.initialIndexingTimeEstimated, initialReturn: Bool()) var initialIndexingTimeEstimatedStub
    func initialIndexingTimeEstimated(of userID: UserID) -> Bool {
        initialIndexingTimeEstimatedStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.setInitialIndexingTimeEstimated) var setInitialIndexingTimeEstimatedStub
    func setInitialIndexingTimeEstimated(of userID: UserID, value: Bool) {
        setInitialIndexingTimeEstimatedStub(userID, value)
    }

    @FuncStub(MockEncryptedSearchUserCache.initialIndexingEstimationTime, initialReturn: Int()) var initialIndexingEstimationTimeStub
    func initialIndexingEstimationTime(of userID: UserID) -> Int {
        initialIndexingEstimationTimeStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.setInitialIndexingEstimationTime) var setInitialIndexingEstimationTimeStub
    func setInitialIndexingEstimationTime(of userID: UserID, value: Int) {
        setInitialIndexingEstimationTimeStub(userID, value)
    }

    @FuncStub(MockEncryptedSearchUserCache.indexStartTime, initialReturn: Double()) var indexStartTimeStub
    func indexStartTime(of userID: UserID) -> Double {
        indexStartTimeStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.setIndexStartTime) var setIndexStartTimeStub
    func setIndexStartTime(of userID: UserID, value: Double) {
        setIndexStartTimeStub(userID, value)
    }

    @FuncStub(MockEncryptedSearchUserCache.isExternalRefreshed, initialReturn: Bool()) var isExternalRefreshedStub
    func isExternalRefreshed(of userID: UserID) -> Bool {
        isExternalRefreshedStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.setIsExternalRefreshed) var setIsExternalRefreshedStub
    func setIsExternalRefreshed(of userID: UserID, value: Bool) {
        setIsExternalRefreshedStub(userID, value)
    }

    @FuncStub(MockEncryptedSearchUserCache.logout) var logoutStub
    func logout(of userID: UserID) {
        logoutStub(userID)
    }

    @FuncStub(MockEncryptedSearchUserCache.cleanGlobal) var cleanGlobalStub
    func cleanGlobal() {
        cleanGlobalStub()
    }

}

class MockFeatureFlagsDownloadServiceProtocol: FeatureFlagsDownloadServiceProtocol {
    @FuncStub(MockFeatureFlagsDownloadServiceProtocol.updateFeatureFlag) var updateFeatureFlagStub
    func updateFeatureFlag(_ key: FeatureFlagKey, value: Any, completion: @escaping (Error?) -> Void) {
        updateFeatureFlagStub(key, value, completion)
    }

}

class MockFeatureFlagsSubscribeProtocol: FeatureFlagsSubscribeProtocol {
    @FuncStub(MockFeatureFlagsSubscribeProtocol.handleNewFeatureFlags) var handleNewFeatureFlagsStub
    func handleNewFeatureFlags(_ featureFlags: [String: Any]) {
        handleNewFeatureFlagsStub(featureFlags)
    }

}

class MockImageProxyDelegate: ImageProxyDelegate {
    @FuncStub(MockImageProxyDelegate.imageProxy) var imageProxyStub
    func imageProxy(_ imageProxy: ImageProxy, output: ImageProxyOutput) {
        imageProxyStub(imageProxy, output)
    }

}

class MockIncomingDefaultServiceProtocol: IncomingDefaultServiceProtocol {
    @FuncStub(MockIncomingDefaultServiceProtocol.fetchAll) var fetchAllStub
    func fetchAll(location: IncomingDefaultsAPI.Location, completion: @escaping (Error?) -> Void) {
        fetchAllStub(location, completion)
    }

    @ThrowingFuncStub(MockIncomingDefaultServiceProtocol.listLocal, initialReturn: [IncomingDefaultEntity]()) var listLocalStub
    func listLocal(query: IncomingDefaultService.Query) throws -> [IncomingDefaultEntity] {
        try listLocalStub(query)
    }

    @ThrowingFuncStub(MockIncomingDefaultServiceProtocol.save) var saveStub
    func save(dto: IncomingDefaultDTO) throws {
        try saveStub(dto)
    }

    @ThrowingFuncStub(MockIncomingDefaultServiceProtocol.performLocalUpdate) var performLocalUpdateStub
    func performLocalUpdate(emailAddress: String, newLocation: IncomingDefaultsAPI.Location) throws {
        try performLocalUpdateStub(emailAddress, newLocation)
    }

    @FuncStub(MockIncomingDefaultServiceProtocol.performRemoteUpdate) var performRemoteUpdateStub
    func performRemoteUpdate(emailAddress: String, newLocation: IncomingDefaultsAPI.Location, completion: @escaping (Error?) -> Void) {
        performRemoteUpdateStub(emailAddress, newLocation, completion)
    }

    @ThrowingFuncStub(MockIncomingDefaultServiceProtocol.softDelete) var softDeleteStub
    func softDelete(query: IncomingDefaultService.Query) throws {
        try softDeleteStub(query)
    }

    @ThrowingFuncStub(MockIncomingDefaultServiceProtocol.hardDelete) var hardDeleteStub
    func hardDelete(query: IncomingDefaultService.Query?, includeSoftDeleted: Bool) throws {
        try hardDeleteStub(query, includeSoftDeleted)
    }

    @FuncStub(MockIncomingDefaultServiceProtocol.performRemoteDeletion) var performRemoteDeletionStub
    func performRemoteDeletion(emailAddress: String, completion: @escaping (Error?) -> Void) {
        performRemoteDeletionStub(emailAddress, completion)
    }

}

class MockInternetConnectionStatusProviderProtocol: InternetConnectionStatusProviderProtocol {
    @PropertyStub(\MockInternetConnectionStatusProviderProtocol.currentStatus, initialGet: .connected) var currentStatusStub
    var currentStatus: ConnectionStatus {
        currentStatusStub()
    }

    @FuncStub(MockInternetConnectionStatusProviderProtocol.registerConnectionStatus) var registerConnectionStatusStub
    func registerConnectionStatus(observerID: UUID, fireAfterRegister: Bool, callback: @escaping (ConnectionStatus) -> Void) {
        registerConnectionStatusStub(observerID, fireAfterRegister, callback)
    }

    @FuncStub(MockInternetConnectionStatusProviderProtocol.unregisterObserver) var unregisterObserverStub
    func unregisterObserver(observerID: UUID) {
        unregisterObserverStub(observerID)
    }

}

class MockLAContextProtocol: LAContextProtocol {
    @FuncStub(MockLAContextProtocol.canEvaluatePolicy, initialReturn: Bool()) var canEvaluatePolicyStub
    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        canEvaluatePolicyStub(policy, error)
    }

}

class MockLabelManagerRouterProtocol: LabelManagerRouterProtocol {
    @FuncStub(MockLabelManagerRouterProtocol.navigateToLabelEdit) var navigateToLabelEditStub
    func navigateToLabelEdit(editMode: LabelEditMode, labels: [MenuLabel], type: PMLabelType, userInfo: UserInfo, labelService: LabelsDataService) {
        navigateToLabelEditStub(editMode, labels, type, userInfo, labelService)
    }

}

class MockLabelManagerUIProtocol: LabelManagerUIProtocol {
    @FuncStub(MockLabelManagerUIProtocol.viewModeDidChange) var viewModeDidChangeStub
    func viewModeDidChange(mode: LabelManagerViewModel.ViewMode) {
        viewModeDidChangeStub(mode)
    }

    @FuncStub(MockLabelManagerUIProtocol.showLoadingHUD) var showLoadingHUDStub
    func showLoadingHUD() {
        showLoadingHUDStub()
    }

    @FuncStub(MockLabelManagerUIProtocol.hideLoadingHUD) var hideLoadingHUDStub
    func hideLoadingHUD() {
        hideLoadingHUDStub()
    }

    @FuncStub(MockLabelManagerUIProtocol.reloadData) var reloadDataStub
    func reloadData() {
        reloadDataStub()
    }

    @FuncStub(MockLabelManagerUIProtocol.reload) var reloadStub
    func reload(section: Int) {
        reloadStub(section)
    }

    @FuncStub(MockLabelManagerUIProtocol.showToast) var showToastStub
    func showToast(message: String) {
        showToastStub(message)
    }

    @FuncStub(MockLabelManagerUIProtocol.showAlertMaxItemsReached) var showAlertMaxItemsReachedStub
    func showAlertMaxItemsReached() {
        showAlertMaxItemsReachedStub()
    }

    @FuncStub(MockLabelManagerUIProtocol.showNoInternetConnectionToast) var showNoInternetConnectionToastStub
    func showNoInternetConnectionToast() {
        showNoInternetConnectionToastStub()
    }

}

class MockLabelProviderProtocol: LabelProviderProtocol {
    @FuncStub(MockLabelProviderProtocol.makePublisher, initialReturn: .crash) var makePublisherStub
    func makePublisher() -> LabelPublisherProtocol {
        makePublisherStub()
    }

    @FuncStub(MockLabelProviderProtocol.getCustomFolders, initialReturn: [LabelEntity]()) var getCustomFoldersStub
    func getCustomFolders() -> [LabelEntity] {
        getCustomFoldersStub()
    }

    @FuncStub(MockLabelProviderProtocol.fetchV4Labels) var fetchV4LabelsStub
    func fetchV4Labels(completion: ((Swift.Result<Void, NSError>) -> Void)?) {
        fetchV4LabelsStub(completion)
    }

}

class MockLabelPublisherProtocol: LabelPublisherProtocol {
    @PropertyStub(\MockLabelPublisherProtocol.delegate, initialGet: nil) var delegateStub
    var delegate: LabelListenerProtocol? {
        get {
            delegateStub()
        }
        set {
            delegateStub(newValue)
        }
    }

    @FuncStub(MockLabelPublisherProtocol.fetchLabels) var fetchLabelsStub
    func fetchLabels(labelType: LabelFetchType) {
        fetchLabelsStub(labelType)
    }

}

class MockLastUpdatedStoreProtocol: LastUpdatedStoreProtocol {
    @FuncStub(MockLastUpdatedStoreProtocol.cleanUp, initialReturn: Promise<Void>()) var cleanUpStub
    func cleanUp(userId: UserID) -> Promise<Void> {
        cleanUpStub(userId)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.updateEventID) var updateEventIDStub
    func updateEventID(by userID: UserID, eventID: String) {
        updateEventIDStub(userID, eventID)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.lastEventID, initialReturn: String()) var lastEventIDStub
    func lastEventID(userID: UserID) -> String {
        lastEventIDStub(userID)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.lastEventUpdateTime, initialReturn: nil) var lastEventUpdateTimeStub
    func lastEventUpdateTime(userID: UserID) -> Date? {
        lastEventUpdateTimeStub(userID)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.lastUpdate, initialReturn: nil) var lastUpdateStub
    func lastUpdate(by labelID: LabelID, userID: UserID, type: ViewMode) -> LabelCountEntity? {
        lastUpdateStub(labelID, userID, type)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.unreadCount, initialReturn: Int()) var unreadCountStub
    func unreadCount(by labelID: LabelID, userID: UserID, type: ViewMode) -> Int {
        unreadCountStub(labelID, userID, type)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.updateUnreadCount) var updateUnreadCountStub
    func updateUnreadCount(by labelID: LabelID, userID: UserID, unread: Int, total: Int?, type: ViewMode, shouldSave: Bool) {
        updateUnreadCountStub(labelID, userID, unread, total, type, shouldSave)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.removeUpdateTime) var removeUpdateTimeStub
    func removeUpdateTime(by userID: UserID, type: ViewMode) {
        removeUpdateTimeStub(userID, type)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.resetCounter) var resetCounterStub
    func resetCounter(labelID: LabelID, userID: UserID, type: ViewMode?) {
        resetCounterStub(labelID, userID, type)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.removeUpdateTimeExceptUnread) var removeUpdateTimeExceptUnreadStub
    func removeUpdateTimeExceptUnread(by userID: UserID) {
        removeUpdateTimeExceptUnreadStub(userID)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.getUnreadCounts) var getUnreadCountsStub
    func getUnreadCounts(by labelIDs: [LabelID], userID: UserID, type: ViewMode, completion: @escaping ([String: Int]) -> Void) {
        getUnreadCountsStub(labelIDs, userID, type, completion)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.updateLastUpdatedTime) var updateLastUpdatedTimeStub
    func updateLastUpdatedTime(labelID: LabelID, isUnread: Bool, startTime: Date, endTime: Date?, msgCount: Int, userID: UserID, type: ViewMode) {
        updateLastUpdatedTimeStub(labelID, isUnread, startTime, endTime, msgCount, userID, type)
    }

}

class MockLockCacheStatus: LockCacheStatus {
    @PropertyStub(\MockLockCacheStatus.isPinCodeEnabled, initialGet: Bool()) var isPinCodeEnabledStub
    var isPinCodeEnabled: Bool {
        isPinCodeEnabledStub()
    }

    @PropertyStub(\MockLockCacheStatus.isTouchIDEnabled, initialGet: Bool()) var isTouchIDEnabledStub
    var isTouchIDEnabled: Bool {
        isTouchIDEnabledStub()
    }

    @PropertyStub(\MockLockCacheStatus.isAppKeyEnabled, initialGet: Bool()) var isAppKeyEnabledStub
    var isAppKeyEnabled: Bool {
        isAppKeyEnabledStub()
    }

    @PropertyStub(\MockLockCacheStatus.isAppLockedAndAppKeyDisabled, initialGet: Bool()) var isAppLockedAndAppKeyDisabledStub
    var isAppLockedAndAppKeyDisabled: Bool {
        isAppLockedAndAppKeyDisabledStub()
    }

    @PropertyStub(\MockLockCacheStatus.isAppLockedAndAppKeyEnabled, initialGet: Bool()) var isAppLockedAndAppKeyEnabledStub
    var isAppLockedAndAppKeyEnabled: Bool {
        isAppLockedAndAppKeyEnabledStub()
    }

}

class MockLockPreferences: LockPreferences {
    @FuncStub(MockLockPreferences.setKeymakerRandomkey) var setKeymakerRandomkeyStub
    func setKeymakerRandomkey(key: String?) {
        setKeymakerRandomkeyStub(key)
    }

    @FuncStub(MockLockPreferences.setLockTime) var setLockTimeStub
    func setLockTime(value: AutolockTimeout) {
        setLockTimeStub(value)
    }

}

class MockMailSettingsHandler: MailSettingsHandler {
    @PropertyStub(\MockMailSettingsHandler.mailSettings, initialGet: MailSettings()) var mailSettingsStub
    var mailSettings: MailSettings {
        get {
            mailSettingsStub()
        }
        set {
            mailSettingsStub(newValue)
        }
    }

    @PropertyStub(\MockMailSettingsHandler.userInfo, initialGet: UserInfo()) var userInfoStub
    var userInfo: UserInfo {
        userInfoStub()
    }

}

class MockMailboxCoordinatorProtocol: MailboxCoordinatorProtocol {
    @PropertyStub(\MockMailboxCoordinatorProtocol.pendingActionAfterDismissal, initialGet: nil) var pendingActionAfterDismissalStub
    var pendingActionAfterDismissal: (() -> Void)? {
        get {
            pendingActionAfterDismissalStub()
        }
        set {
            pendingActionAfterDismissalStub(newValue)
        }
    }

    @PropertyStub(\MockMailboxCoordinatorProtocol.conversationCoordinator, initialGet: nil) var conversationCoordinatorStub
    var conversationCoordinator: ConversationCoordinator? {
        conversationCoordinatorStub()
    }

    @PropertyStub(\MockMailboxCoordinatorProtocol.singleMessageCoordinator, initialGet: nil) var singleMessageCoordinatorStub
    var singleMessageCoordinator: SingleMessageCoordinator? {
        singleMessageCoordinatorStub()
    }

    @FuncStub(MockMailboxCoordinatorProtocol.go) var goStub
    func go(to dest: MailboxCoordinator.Destination, sender: Any?) {
        goStub(dest, sender)
    }

    @FuncStub(MockMailboxCoordinatorProtocol.presentToolbarCustomizationView) var presentToolbarCustomizationViewStub
    func presentToolbarCustomizationView(allActions: [MessageViewActionSheetAction], currentActions: [MessageViewActionSheetAction]) {
        presentToolbarCustomizationViewStub(allActions, currentActions)
    }

}

class MockMarkLegitimateActionHandler: MarkLegitimateActionHandler {
    @FuncStub(MockMarkLegitimateActionHandler.markAsLegitimate) var markAsLegitimateStub
    func markAsLegitimate(messageId: MessageID) {
        markAsLegitimateStub(messageId)
    }

}

class MockMobileSignatureCacheProtocol: MobileSignatureCacheProtocol {
    @FuncStub(MockMobileSignatureCacheProtocol.getMobileSignatureSwitchStatus, initialReturn: nil) var getMobileSignatureSwitchStatusStub
    func getMobileSignatureSwitchStatus(by uid: String) -> Bool? {
        getMobileSignatureSwitchStatusStub(uid)
    }

    @FuncStub(MockMobileSignatureCacheProtocol.setMobileSignatureSwitchStatus) var setMobileSignatureSwitchStatusStub
    func setMobileSignatureSwitchStatus(uid: String, value: Bool) {
        setMobileSignatureSwitchStatusStub(uid, value)
    }

    @FuncStub(MockMobileSignatureCacheProtocol.removeMobileSignatureSwitchStatus) var removeMobileSignatureSwitchStatusStub
    func removeMobileSignatureSwitchStatus(uid: String) {
        removeMobileSignatureSwitchStatusStub(uid)
    }

    @FuncStub(MockMobileSignatureCacheProtocol.getEncryptedMobileSignature, initialReturn: nil) var getEncryptedMobileSignatureStub
    func getEncryptedMobileSignature(userID: String) -> Data? {
        getEncryptedMobileSignatureStub(userID)
    }

    @FuncStub(MockMobileSignatureCacheProtocol.setEncryptedMobileSignature) var setEncryptedMobileSignatureStub
    func setEncryptedMobileSignature(userID: String, signatureData: Data) {
        setEncryptedMobileSignatureStub(userID, signatureData)
    }

    @FuncStub(MockMobileSignatureCacheProtocol.removeEncryptedMobileSignature) var removeEncryptedMobileSignatureStub
    func removeEncryptedMobileSignature(userID: String) {
        removeEncryptedMobileSignatureStub(userID)
    }

}

class MockNewMessageBodyViewModelDelegate: NewMessageBodyViewModelDelegate {
    @FuncStub(MockNewMessageBodyViewModelDelegate.reloadWebView) var reloadWebViewStub
    func reloadWebView(forceRecreate: Bool) {
        reloadWebViewStub(forceRecreate)
    }

    @FuncStub(MockNewMessageBodyViewModelDelegate.showReloadError) var showReloadErrorStub
    func showReloadError() {
        showReloadErrorStub()
    }

}

class MockNextMessageAfterMoveStatusProvider: NextMessageAfterMoveStatusProvider {
    @PropertyStub(\MockNextMessageAfterMoveStatusProvider.shouldMoveToNextMessageAfterMove, initialGet: Bool()) var shouldMoveToNextMessageAfterMoveStub
    var shouldMoveToNextMessageAfterMove: Bool {
        get {
            shouldMoveToNextMessageAfterMoveStub()
        }
        set {
            shouldMoveToNextMessageAfterMoveStub(newValue)
        }
    }

}

class MockPMPersistentQueueProtocol: PMPersistentQueueProtocol {
    @PropertyStub(\MockPMPersistentQueueProtocol.count, initialGet: Int()) var countStub
    var count: Int {
        countStub()
    }

    @FuncStub(MockPMPersistentQueueProtocol.queueArray, initialReturn: [Any]()) var queueArrayStub
    func queueArray() -> [Any] {
        queueArrayStub()
    }

    @FuncStub(MockPMPersistentQueueProtocol.add, initialReturn: UUID()) var addStub
    func add(_ uuid: UUID, object: NSCoding) -> UUID {
        addStub(uuid, object)
    }

    @FuncStub(MockPMPersistentQueueProtocol.insert, initialReturn: UUID()) var insertStub
    func insert(uuid: UUID, object: NSCoding, index: Int) -> UUID {
        insertStub(uuid, object, index)
    }

    @FuncStub(MockPMPersistentQueueProtocol.update) var updateStub
    func update(uuid: UUID, object: NSCoding) {
        updateStub(uuid, object)
    }

    @FuncStub(MockPMPersistentQueueProtocol.clearAll) var clearAllStub
    func clearAll() {
        clearAllStub()
    }

    @FuncStub(MockPMPersistentQueueProtocol.next, initialReturn: nil) var nextStub
    func next() -> (elementID: UUID, object: Any)? {
        nextStub()
    }

    @FuncStub(MockPMPersistentQueueProtocol.remove, initialReturn: Bool()) var removeStub
    func remove(_ elementID: UUID) -> Bool {
        removeStub(elementID)
    }

}

class MockPagesViewUIProtocol: PagesViewUIProtocol {
    @FuncStub(MockPagesViewUIProtocol.dismiss) var dismissStub
    func dismiss() {
        dismissStub()
    }

    @FuncStub(MockPagesViewUIProtocol.getCurrentObjectID, initialReturn: nil) var getCurrentObjectIDStub
    func getCurrentObjectID() -> ObjectID? {
        getCurrentObjectIDStub()
    }

    @FuncStub(MockPagesViewUIProtocol.handlePageViewNavigationDirection) var handlePageViewNavigationDirectionStub
    func handlePageViewNavigationDirection(action: PagesSwipeAction, shouldReload: Bool) {
        handlePageViewNavigationDirectionStub(action, shouldReload)
    }

}

class MockPaymentsUIProtocol: PaymentsUIProtocol {
    @FuncStub(MockPaymentsUIProtocol.showCurrentPlan) var showCurrentPlanStub
    func showCurrentPlan(presentationType: PaymentsUIPresentationType, backendFetch: Bool, completionHandler: @escaping (PaymentsUIResultReason) -> Void) {
        showCurrentPlanStub(presentationType, backendFetch, completionHandler)
    }

}

class MockPinFailedCountCache: PinFailedCountCache {
    @PropertyStub(\MockPinFailedCountCache.pinFailedCount, initialGet: Int()) var pinFailedCountStub
    var pinFailedCount: Int {
        get {
            pinFailedCountStub()
        }
        set {
            pinFailedCountStub(newValue)
        }
    }

}

class MockQueueHandlerRegister: QueueHandlerRegister {
    @FuncStub(MockQueueHandlerRegister.registerHandler) var registerHandlerStub
    func registerHandler(_ handler: QueueHandler) {
        registerHandlerStub(handler)
    }

    @FuncStub(MockQueueHandlerRegister.unregisterHandler) var unregisterHandlerStub
    func unregisterHandler(for userID: UserID) {
        unregisterHandlerStub(userID)
    }

}

class MockQueueManagerProtocol: QueueManagerProtocol {
    @FuncStub(MockQueueManagerProtocol.addTask) var addTaskStub
    func addTask(_ task: QueueManager.Task, autoExecute: Bool, completion: ((Bool) -> Void)?) {
        addTaskStub(task, autoExecute, completion)
    }

    @FuncStub(MockQueueManagerProtocol.addBlock) var addBlockStub
    func addBlock(_ block: @escaping () -> Void) {
        addBlockStub(block)
    }

    @FuncStub(MockQueueManagerProtocol.queue) var queueStub
    func queue(_ readBlock: @escaping () -> Void) {
        queueStub(readBlock)
    }

}

class MockReceiptActionHandler: ReceiptActionHandler {
    @FuncStub(MockReceiptActionHandler.sendReceipt) var sendReceiptStub
    func sendReceipt(messageID: MessageID) {
        sendReceiptStub(messageID)
    }

}

class MockReferralPromptProvider: ReferralPromptProvider {
    @FuncStub(MockReferralPromptProvider.isReferralPromptEnabled, initialReturn: Bool()) var isReferralPromptEnabledStub
    func isReferralPromptEnabled(userID: UserID) -> Bool {
        isReferralPromptEnabledStub(userID)
    }

    @FuncStub(MockReferralPromptProvider.setIsReferralPromptEnabled) var setIsReferralPromptEnabledStub
    func setIsReferralPromptEnabled(enabled: Bool, userID: UserID) {
        setIsReferralPromptEnabledStub(enabled, userID)
    }

}

class MockRefetchAllBlockedSendersUseCase: RefetchAllBlockedSendersUseCase {
    @FuncStub(MockRefetchAllBlockedSendersUseCase.execute) var executeStub
    func execute(completion: @escaping (Error?) -> Void) {
        executeStub(completion)
    }

}

class MockScheduledSendHelperDelegate: ScheduledSendHelperDelegate {
    @FuncStub(MockScheduledSendHelperDelegate.actionSheetWillAppear) var actionSheetWillAppearStub
    func actionSheetWillAppear() {
        actionSheetWillAppearStub()
    }

    @FuncStub(MockScheduledSendHelperDelegate.actionSheetWillDisappear) var actionSheetWillDisappearStub
    func actionSheetWillDisappear() {
        actionSheetWillDisappearStub()
    }

    @FuncStub(MockScheduledSendHelperDelegate.scheduledTimeIsSet) var scheduledTimeIsSetStub
    func scheduledTimeIsSet(date: Date?) {
        scheduledTimeIsSetStub(date)
    }

    @FuncStub(MockScheduledSendHelperDelegate.showSendInTheFutureAlert) var showSendInTheFutureAlertStub
    func showSendInTheFutureAlert() {
        showSendInTheFutureAlertStub()
    }

    @FuncStub(MockScheduledSendHelperDelegate.isItAPaidUser, initialReturn: Bool()) var isItAPaidUserStub
    func isItAPaidUser() -> Bool {
        isItAPaidUserStub()
    }

    @FuncStub(MockScheduledSendHelperDelegate.showScheduleSendPromotionView) var showScheduleSendPromotionViewStub
    func showScheduleSendPromotionView() {
        showScheduleSendPromotionViewStub()
    }

}

class MockSendRefactorStatusProvider: SendRefactorStatusProvider {
    @FuncStub(MockSendRefactorStatusProvider.isSendRefactorEnabled, initialReturn: Bool()) var isSendRefactorEnabledStub
    func isSendRefactorEnabled(userID: UserID) -> Bool {
        isSendRefactorEnabledStub(userID)
    }

    @FuncStub(MockSendRefactorStatusProvider.setIsSendRefactorEnabled) var setIsSendRefactorEnabledStub
    func setIsSendRefactorEnabled(userID: UserID, value: Bool) {
        setIsSendRefactorEnabledStub(userID, value)
    }

}

class MockSenderImageStatusProvider: SenderImageStatusProvider {
    @FuncStub(MockSenderImageStatusProvider.isSenderImageEnabled, initialReturn: Bool()) var isSenderImageEnabledStub
    func isSenderImageEnabled(userID: UserID) -> Bool {
        isSenderImageEnabledStub(userID)
    }

    @FuncStub(MockSenderImageStatusProvider.setIsSenderImageEnable) var setIsSenderImageEnableStub
    func setIsSenderImageEnable(enable: Bool, userID: UserID) {
        setIsSenderImageEnableStub(enable, userID)
    }

}

class MockSettingsAccountCoordinatorProtocol: SettingsAccountCoordinatorProtocol {
    @FuncStub(MockSettingsAccountCoordinatorProtocol.go) var goStub
    func go(to dest: SettingsAccountCoordinator.Destination) {
        goStub(dest)
    }

}

class MockSettingsEncryptedSearchRouterProtocol: SettingsEncryptedSearchRouterProtocol {
    @FuncStub(MockSettingsEncryptedSearchRouterProtocol.navigateToDownloadedMessages) var navigateToDownloadedMessagesStub
    func navigateToDownloadedMessages(userID: UserID, state: EncryptedSearchIndexState) {
        navigateToDownloadedMessagesStub(userID, state)
    }

}

class MockSettingsEncryptedSearchUIProtocol: SettingsEncryptedSearchUIProtocol {
    @FuncStub(MockSettingsEncryptedSearchUIProtocol.reloadData) var reloadDataStub
    func reloadData() {
        reloadDataStub()
    }

    @FuncStub(MockSettingsEncryptedSearchUIProtocol.updateDownloadState) var updateDownloadStateStub
    func updateDownloadState(state: EncryptedSearchIndexState) {
        updateDownloadStateStub(state)
    }

    @FuncStub(MockSettingsEncryptedSearchUIProtocol.updateDownloadProgress) var updateDownloadProgressStub
    func updateDownloadProgress(progress: EncryptedSearchDownloadProgress) {
        updateDownloadProgressStub(progress)
    }

}

class MockSettingsLockRouterProtocol: SettingsLockRouterProtocol {
    @FuncStub(MockSettingsLockRouterProtocol.go) var goStub
    func go(to dest: SettingsLockRouterDestination) {
        goStub(dest)
    }

}

class MockSettingsLockUIProtocol: SettingsLockUIProtocol {
    @FuncStub(MockSettingsLockUIProtocol.reloadData) var reloadDataStub
    func reloadData() {
        reloadDataStub()
    }

}

class MockSideMenuProtocol: SideMenuProtocol {
    @PropertyStub(\MockSideMenuProtocol.menuViewController, initialGet: nil) var menuViewControllerStub
    var menuViewController: UIViewController! {
        get {
            menuViewControllerStub()
        }
        set {
            menuViewControllerStub(newValue)
        }
    }

    @FuncStub(MockSideMenuProtocol.hideMenu) var hideMenuStub
    func hideMenu(animated: Bool, completion: ((Bool) -> Void)?) {
        hideMenuStub(animated, completion)
    }

    @FuncStub(MockSideMenuProtocol.revealMenu) var revealMenuStub
    func revealMenu(animated: Bool, completion: ((Bool) -> Void)?) {
        revealMenuStub(animated, completion)
    }

    @FuncStub(MockSideMenuProtocol.setContentViewController) var setContentViewControllerStub
    func setContentViewController(to viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        setContentViewControllerStub(viewController, animated, completion)
    }

}

class MockSwipeActionInfo: SwipeActionInfo {
    @PropertyStub(\MockSwipeActionInfo.swipeLeft, initialGet: Int()) var swipeLeftStub
    var swipeLeft: Int {
        swipeLeftStub()
    }

    @PropertyStub(\MockSwipeActionInfo.swipeRight, initialGet: Int()) var swipeRightStub
    var swipeRight: Int {
        swipeRightStub()
    }

}

class MockToolbarCustomizationInfoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider {
    @PropertyStub(\MockToolbarCustomizationInfoBubbleViewStatusProvider.shouldHideToolbarCustomizeInfoBubbleView, initialGet: Bool()) var shouldHideToolbarCustomizeInfoBubbleViewStub
    var shouldHideToolbarCustomizeInfoBubbleView: Bool {
        get {
            shouldHideToolbarCustomizeInfoBubbleViewStub()
        }
        set {
            shouldHideToolbarCustomizeInfoBubbleViewStub(newValue)
        }
    }

}

class MockUnlockManagerDelegate: UnlockManagerDelegate {
    @FuncStub(MockUnlockManagerDelegate.cleanAll) var cleanAllStub
    func cleanAll(completion: @escaping () -> Void) {
        cleanAllStub(completion)
    }

    @FuncStub(MockUnlockManagerDelegate.isUserStored, initialReturn: Bool()) var isUserStoredStub
    func isUserStored() -> Bool {
        isUserStoredStub()
    }

    @FuncStub(MockUnlockManagerDelegate.isMailboxPasswordStored, initialReturn: Bool()) var isMailboxPasswordStoredStub
    func isMailboxPasswordStored(forUser uid: String?) -> Bool {
        isMailboxPasswordStoredStub(uid)
    }

    @FuncStub(MockUnlockManagerDelegate.setupCoreData) var setupCoreDataStub
    func setupCoreData() {
        setupCoreDataStub()
    }

    @FuncStub(MockUnlockManagerDelegate.loadUserDataAfterUnlock) var loadUserDataAfterUnlockStub
    func loadUserDataAfterUnlock() {
        loadUserDataAfterUnlockStub()
    }

}

class MockUnsubscribeActionHandler: UnsubscribeActionHandler {
    @FuncStub(MockUnsubscribeActionHandler.oneClickUnsubscribe) var oneClickUnsubscribeStub
    func oneClickUnsubscribe(messageId: MessageID) {
        oneClickUnsubscribeStub(messageId)
    }

    @FuncStub(MockUnsubscribeActionHandler.markAsUnsubscribed) var markAsUnsubscribedStub
    func markAsUnsubscribed(messageId: MessageID, finish: @escaping () -> Void) {
        markAsUnsubscribedStub(messageId, finish)
    }

}

class MockUpdateSwipeActionDuringLoginUseCase: UpdateSwipeActionDuringLoginUseCase {
    @FuncStub(MockUpdateSwipeActionDuringLoginUseCase.execute) var executeStub
    func execute(activeUserInfo: UserInfo, newUserInfo: UserInfo, newUserApiService: APIService, completion: (() -> Void)?) {
        executeStub(activeUserInfo, newUserInfo, newUserApiService, completion)
    }

}

class MockUserFeedbackServiceProtocol: UserFeedbackServiceProtocol {
    @FuncStub(MockUserFeedbackServiceProtocol.send) var sendStub
    func send(_ feedback: UserFeedback, handler: @escaping (UserFeedbackServiceError?) -> Void) {
        sendStub(feedback, handler)
    }

}

class MockUserIntroductionProgressProvider: UserIntroductionProgressProvider {
    @FuncStub(MockUserIntroductionProgressProvider.shouldShowSpotlight, initialReturn: Bool()) var shouldShowSpotlightStub
    func shouldShowSpotlight(for feature: SpotlightableFeatureKey, toUserWith userID: UserID) -> Bool {
        shouldShowSpotlightStub(feature, userID)
    }

    @FuncStub(MockUserIntroductionProgressProvider.markSpotlight) var markSpotlightStub
    func markSpotlight(for feature: SpotlightableFeatureKey, asSeen seen: Bool, byUserWith userID: UserID) {
        markSpotlightStub(feature, seen, userID)
    }

}

class MockViewModeUpdater: ViewModeUpdater {
    @FuncStub(MockViewModeUpdater.update) var updateStub
    func update(viewMode: ViewMode, completion: ((Swift.Result<ViewMode?, Error>) -> Void)?) {
        updateStub(viewMode, completion)
    }

}

