// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import BackgroundTasks
import CoreData
import LocalAuthentication
import Network
import ProtonCoreCrypto
import ProtonCoreEnvironment
import ProtonCoreFeatureFlags
import ProtonCoreKeymaker
import ProtonCorePaymentsUI
import ProtonCoreServices
import ProtonCoreTestingToolkitUnitTestsCore
import ProtonInboxRSVP
import UIKit

import class ProtonCoreDataModel.Address
import class ProtonCoreDataModel.UserInfo

@testable import ProtonMail

class MockAnswerInvitation: AnswerInvitation {
    @ThrowingFuncStub(MockAnswerInvitation.execute) var executeStub
    func execute(parameters: AnswerInvitationWrapper.Parameters) throws {
        try executeStub(parameters)
    }

}

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

class MockAppTelemetry: AppTelemetry {
    @FuncStub(MockAppTelemetry.configure) var configureStub
    func configure(telemetry: Bool, reportCrashes: Bool) {
        configureStub(telemetry, reportCrashes)
    }

    @FuncStub(MockAppTelemetry.assignUser) var assignUserStub
    func assignUser(userID: UserID?) {
        assignUserStub(userID)
    }

}

class MockAutoDeleteSpamAndTrashDaysProvider: AutoDeleteSpamAndTrashDaysProvider {
    @PropertyStub(\MockAutoDeleteSpamAndTrashDaysProvider.isAutoDeleteEnabled, initialGet: Bool()) var isAutoDeleteEnabledStub
    var isAutoDeleteEnabled: Bool {
        get {
            isAutoDeleteEnabledStub()
        }
        set {
            isAutoDeleteEnabledStub(newValue)
        }
    }

}

class MockBGTaskSchedulerProtocol: BGTaskSchedulerProtocol {
    @ThrowingFuncStub(MockBGTaskSchedulerProtocol.submit) var submitStub
    func submit(_ taskRequest: BGTaskRequest) throws {
        try submitStub(taskRequest)
    }

    @FuncStub(MockBGTaskSchedulerProtocol.register, initialReturn: Bool()) var registerStub
    func register(forTaskWithIdentifier identifier: String, using queue: DispatchQueue?, launchHandler: @escaping (BGTask) -> Void) -> Bool {
        registerStub(identifier, queue, launchHandler)
    }

}

class MockBackendConfigurationCacheProtocol: BackendConfigurationCacheProtocol {
    @FuncStub(MockBackendConfigurationCacheProtocol.readEnvironment, initialReturn: nil) var readEnvironmentStub
    func readEnvironment() -> Environment? {
        readEnvironmentStub()
    }

}

class MockBiometricStatusProvider: BiometricStatusProvider {
    @PropertyStub(\MockBiometricStatusProvider.biometricType, initialGet: .none) var biometricTypeStub
    var biometricType: BiometricType {
        biometricTypeStub()
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
    func markBlockedSendersAsFetched(_ fetched: Bool, userID: UserID) {
        markBlockedSendersAsFetchedStub(fetched, userID)
    }

}

class MockBundleType: BundleType {
    @PropertyStub(\MockBundleType.preferredLocalizations, initialGet: [String]()) var preferredLocalizationsStub
    var preferredLocalizations: [String] {
        preferredLocalizationsStub()
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

    @ThrowingFuncStub(MockCacheServiceProtocol.updateContactDetail, initialReturn: .crash) var updateContactDetailStub
    func updateContactDetail(serverResponse: [String: Any]) throws -> ContactEntity {
        try updateContactDetailStub(serverResponse)
    }

    @ThrowingFuncStub(MockCacheServiceProtocol.parseMessagesResponse) var parseMessagesResponseStub
    func parseMessagesResponse(labelID: LabelID, isUnread: Bool, response: [String: Any], idsOfMessagesBeingSent: [String]) throws {
        try parseMessagesResponseStub(labelID, isUnread, response, idsOfMessagesBeingSent)
    }

    @FuncStub(MockCacheServiceProtocol.updateExpirationOffset) var updateExpirationOffsetStub
    func updateExpirationOffset(of messageObjectID: NSManagedObjectID, expirationTime: TimeInterval, pwd: String, pwdHint: String, completion: (() -> Void)?) {
        updateExpirationOffsetStub(messageObjectID, expirationTime, pwd, pwdHint, completion)
    }

}

class MockCachedUserDataProvider: CachedUserDataProvider {
    @ThrowingFuncStub(MockCachedUserDataProvider.set) var setStub
    func set(disconnectedUsers: [UsersManager.DisconnectedUserHandle]) throws {
        try setStub(disconnectedUsers)
    }

    @ThrowingFuncStub(MockCachedUserDataProvider.fetchDisconnectedUsers, initialReturn: [UsersManager.DisconnectedUserHandle]()) var fetchDisconnectedUsersStub
    func fetchDisconnectedUsers() throws -> [UsersManager.DisconnectedUserHandle] {
        try fetchDisconnectedUsersStub()
    }

}

class MockComposeUIProtocol: ComposeUIProtocol {
    @FuncStub(MockComposeUIProtocol.changeInvalidSenderAddress) var changeInvalidSenderAddressStub
    func changeInvalidSenderAddress(to newAddress: Address) {
        changeInvalidSenderAddressStub(newAddress)
    }

    @FuncStub(MockComposeUIProtocol.updateSenderAddressesList) var updateSenderAddressesListStub
    func updateSenderAddressesList() {
        updateSenderAddressesListStub()
    }

    @FuncStub(MockComposeUIProtocol.show) var showStub
    func show(error: String) {
        showStub(error)
    }

}

class MockConnectionMonitor: ConnectionMonitor {
    @PropertyStub(\MockConnectionMonitor.currentPathProtocol, initialGet: nil) var currentPathProtocolStub
    var currentPathProtocol: NWPathProtocol? {
        currentPathProtocolStub()
    }

    @PropertyStub(\MockConnectionMonitor.pathUpdateClosure, initialGet: nil) var pathUpdateClosureStub
    var pathUpdateClosure: ((_ newPath: NWPathProtocol) -> Void)? {
        get {
            pathUpdateClosureStub()
        }
        set {
            pathUpdateClosureStub(newValue)
        }
    }

    @FuncStub(MockConnectionMonitor.start) var startStub
    func start(queue: DispatchQueue) {
        startStub(queue)
    }

    @FuncStub(MockConnectionMonitor.cancel) var cancelStub
    func cancel() {
        cancelStub()
    }

}

class MockConnectionStatusReceiver: ConnectionStatusReceiver {
    @FuncStub(MockConnectionStatusReceiver.connectionStatusHasChanged) var connectionStatusHasChangedStub
    func connectionStatusHasChanged(newStatus: ConnectionStatus) {
        connectionStatusHasChangedStub(newStatus)
    }

}

class MockContactDataServiceProtocol: ContactDataServiceProtocol {
    @FuncStub(MockContactDataServiceProtocol.queueUpdate) var queueUpdateStub
    func queueUpdate(objectID: NSManagedObjectID, cardDatas: [CardData], newName: String, emails: [ContactEditEmail], completion: ContactUpdateComplete?) {
        queueUpdateStub(objectID, cardDatas, newName, emails, completion)
    }

    @FuncStub(MockContactDataServiceProtocol.queueAddContact, initialReturn: nil) var queueAddContactStub
    func queueAddContact(cardDatas: [CardData], name: String, emails: [ContactEditEmail], importedFromDevice: Bool) -> NSError? {
        queueAddContactStub(cardDatas, name, emails, importedFromDevice)
    }

    @FuncStub(MockContactDataServiceProtocol.queueDelete) var queueDeleteStub
    func queueDelete(objectID: NSManagedObjectID, completion: ContactDeleteComplete?) {
        queueDeleteStub(objectID, completion)
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
    func fetchConversations(for labelID: LabelID, before timestamp: Int, unreadOnly: Bool, shouldReset: Bool, completion: (@Sendable (Result<Void, Error>) -> Void)?) {
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
    func label(conversationIDs: [ConversationID], as labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        labelStub(conversationIDs, labelID, completion)
    }

    @FuncStub(MockConversationProvider.unlabel) var unlabelStub
    func unlabel(conversationIDs: [ConversationID], as labelID: LabelID, completion: (@Sendable (Result<Void, Error>) -> Void)?) {
        unlabelStub(conversationIDs, labelID, completion)
    }

    @FuncStub(MockConversationProvider.move) var moveStub
    func move(conversationIDs: [ConversationID], from previousFolderLabel: LabelID, to nextFolderLabel: LabelID, callOrigin: String?, completion: (@Sendable (Result<Void, Error>) -> Void)?) {
        moveStub(conversationIDs, previousFolderLabel, nextFolderLabel, callOrigin, completion)
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

class MockDeviceContactsProvider: DeviceContactsProvider {
    @ThrowingFuncStub(MockDeviceContactsProvider.fetchAllContactIdentifiers, initialReturn: .crash) var fetchAllContactIdentifiersStub
    func fetchAllContactIdentifiers() throws -> (historyToken: Data, identifiers: [DeviceContactIdentifier]) {
        try fetchAllContactIdentifiersStub()
    }

    @ThrowingFuncStub(MockDeviceContactsProvider.fetchEventsContactIdentifiers, initialReturn: .crash) var fetchEventsContactIdentifiersStub
    func fetchEventsContactIdentifiers(historyToken: Data) throws -> (historyToken: Data, identifiers: [DeviceContactIdentifier]) {
        try fetchEventsContactIdentifiersStub(historyToken)
    }

    @ThrowingFuncStub(MockDeviceContactsProvider.fetchContactBatch, initialReturn: [DeviceContact]()) var fetchContactBatchStub
    func fetchContactBatch(with identifiers: [String]) throws -> [DeviceContact] {
        try fetchContactBatchStub(identifiers)
    }

}

class MockDeviceRegistrationUseCase: DeviceRegistrationUseCase {
    @FuncStub(MockDeviceRegistrationUseCase.execute, initialReturn: [DeviceRegistrationResult]()) var executeStub
    func execute(sessionIDs: [String], deviceToken: String, publicKey: String) -> [DeviceRegistrationResult] {
        executeStub(sessionIDs, deviceToken, publicKey)
    }

}

class MockExtractBasicEventInfo: ExtractBasicEventInfo {
    @ThrowingFuncStub(MockExtractBasicEventInfo.execute, initialReturn: .crash) var executeStub
    func execute(icsData: Data) throws -> BasicEventInfo {
        try executeStub(icsData)
    }

}

class MockFailedPushDecryptionMarker: FailedPushDecryptionMarker {
    @FuncStub(MockFailedPushDecryptionMarker.markPushNotificationDecryptionFailure) var markPushNotificationDecryptionFailureStub
    func markPushNotificationDecryptionFailure() {
        markPushNotificationDecryptionFailureStub()
    }

}

class MockFailedPushDecryptionProvider: FailedPushDecryptionProvider {
    @PropertyStub(\MockFailedPushDecryptionProvider.hadPushNotificationDecryptionFailed, initialGet: Bool()) var hadPushNotificationDecryptionFailedStub
    var hadPushNotificationDecryptionFailed: Bool {
        hadPushNotificationDecryptionFailedStub()
    }

    @FuncStub(MockFailedPushDecryptionProvider.clearPushNotificationDecryptionFailure) var clearPushNotificationDecryptionFailureStub
    func clearPushNotificationDecryptionFailure() {
        clearPushNotificationDecryptionFailureStub()
    }

}

class MockFeatureFlagCache: FeatureFlagCache {
    @FuncStub(MockFeatureFlagCache.storeFeatureFlags) var storeFeatureFlagsStub
    func storeFeatureFlags(_ flags: SupportedFeatureFlags, for userID: UserID) {
        storeFeatureFlagsStub(flags, userID)
    }

    @FuncStub(MockFeatureFlagCache.featureFlags, initialReturn: .crash) var featureFlagsStub
    func featureFlags(for userID: UserID) -> SupportedFeatureFlags {
        featureFlagsStub(userID)
    }

}

class MockFeatureFlagProvider: FeatureFlagProvider {
    @FuncStub(MockFeatureFlagProvider.isEnabled, initialReturn: Bool()) var isEnabledStub
    func isEnabled(_ featureFlag: MailFeatureFlag) -> Bool {
        isEnabledStub(featureFlag)
    }

    @FuncStub(MockFeatureFlagProvider.getFlag, initialReturn: nil) var getFlagStub
    func getFlag(_ featureFlag: MailFeatureFlag) -> ProtonCoreFeatureFlags.FeatureFlag? {
        getFlagStub(featureFlag)
    }

}

class MockFeatureFlagsDownloadServiceProtocol: FeatureFlagsDownloadServiceProtocol {
    @FuncStub(MockFeatureFlagsDownloadServiceProtocol.updateFeatureFlag) var updateFeatureFlagStub
    func updateFeatureFlag(_ key: FeatureFlagKey, value: Any, completion: @escaping (Error?) -> Void) {
        updateFeatureFlagStub(key, value, completion)
    }

}

class MockFetchAttachmentMetadataUseCase: FetchAttachmentMetadataUseCase {
    @ThrowingFuncStub(MockFetchAttachmentMetadataUseCase.execution, initialReturn: .crash) var executionStub
    func execution(params: FetchAttachmentMetadata.Params) throws -> AttachmentMetadata {
        try executionStub(params)
    }

}

class MockFetchEmailAddressesPublicKeyUseCase: FetchEmailAddressesPublicKeyUseCase {
    @ThrowingFuncStub(MockFetchEmailAddressesPublicKeyUseCase.execute, initialReturn: .crash) var executeStub
    func execute(email: String) throws -> KeysResponse {
        try executeStub(email)
    }

}

class MockFetchEventDetails: FetchEventDetails {
    @ThrowingFuncStub(MockFetchEventDetails.execute, initialReturn: .crash) var executeStub
    func execute(basicEventInfo: BasicEventInfo) throws -> (EventDetails, AnsweringContext?) {
        try executeStub(basicEventInfo)
    }

}

class MockImageProxyCacheProtocol: ImageProxyCacheProtocol {
    @ThrowingFuncStub(MockImageProxyCacheProtocol.remoteImage, initialReturn: nil) var remoteImageStub
    func remoteImage(forURL remoteURL: SafeRemoteURL) throws -> RemoteImage? {
        try remoteImageStub(remoteURL)
    }

    @ThrowingFuncStub(MockImageProxyCacheProtocol.setRemoteImage) var setRemoteImageStub
    func setRemoteImage(_ remoteImage: RemoteImage, forURL remoteURL: SafeRemoteURL) throws {
        try setRemoteImageStub(remoteImage, remoteURL)
    }

    @FuncStub(MockImageProxyCacheProtocol.removeRemoteImage) var removeRemoteImageStub
    func removeRemoteImage(forURL remoteURL: SafeRemoteURL) {
        removeRemoteImageStub(remoteURL)
    }

    @FuncStub(MockImageProxyCacheProtocol.purge) var purgeStub
    func purge() {
        purgeStub()
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
    @PropertyStub(\MockInternetConnectionStatusProviderProtocol.status, initialGet: .initialize) var statusStub
    var status: ConnectionStatus {
        statusStub()
    }

    @FuncStub(MockInternetConnectionStatusProviderProtocol.apiCallIsSucceeded) var apiCallIsSucceededStub
    func apiCallIsSucceeded() {
        apiCallIsSucceededStub()
    }

    @FuncStub(MockInternetConnectionStatusProviderProtocol.register) var registerStub
    func register(receiver: ConnectionStatusReceiver, fireWhenRegister: Bool) {
        registerStub(receiver, fireWhenRegister)
    }

    @FuncStub(MockInternetConnectionStatusProviderProtocol.unRegister) var unRegisterStub
    func unRegister(receiver: ConnectionStatusReceiver) {
        unRegisterStub(receiver)
    }

    @FuncStub(MockInternetConnectionStatusProviderProtocol.updateNewStatusToAll) var updateNewStatusToAllStub
    func updateNewStatusToAll(_ newStatus: ConnectionStatus) {
        updateNewStatusToAllStub(newStatus)
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

    @FuncStub(MockLabelManagerRouterProtocol.presentUpsellPage) var presentUpsellPageStub
    func presentUpsellPage(labelType: PMLabelType) {
        presentUpsellPageStub(labelType)
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
    func fetchV4Labels(completion: (@Sendable (Swift.Result<Void, Error>) -> Void)?) {
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
    @FuncStub(MockLastUpdatedStoreProtocol.cleanUp) var cleanUpStub
    func cleanUp(userId: UserID) {
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

    @ThrowingFuncStub(MockLastUpdatedStoreProtocol.batchUpdateUnreadCounts) var batchUpdateUnreadCountsStub
    func batchUpdateUnreadCounts(counts: [CountData], userID: UserID, type: ViewMode) throws {
        try batchUpdateUnreadCountsStub(counts, userID, type)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.removeUpdateTime) var removeUpdateTimeStub
    func removeUpdateTime(by userID: UserID) {
        removeUpdateTimeStub(userID)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.resetCounter) var resetCounterStub
    func resetCounter(labelID: LabelID, userID: UserID) {
        resetCounterStub(labelID, userID)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.removeUpdateTimeExceptUnread) var removeUpdateTimeExceptUnreadStub
    func removeUpdateTimeExceptUnread(by userID: UserID) {
        removeUpdateTimeExceptUnreadStub(userID)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.getUnreadCounts, initialReturn: [String: Int]()) var getUnreadCountsStub
    func getUnreadCounts(by labelIDs: [LabelID], userID: UserID, type: ViewMode) -> [String: Int] {
        getUnreadCountsStub(labelIDs, userID, type)
    }

    @FuncStub(MockLastUpdatedStoreProtocol.updateLastUpdatedTime) var updateLastUpdatedTimeStub
    func updateLastUpdatedTime(labelID: LabelID, isUnread: Bool, startTime: Date, endTime: Date?, msgCount: Int, userID: UserID, type: ViewMode) {
        updateLastUpdatedTimeStub(labelID, isUnread, startTime, endTime, msgCount, userID, type)
    }

}

class MockLaunchService: LaunchService {
    @ThrowingFuncStub(MockLaunchService.start) var startStub
    func start() throws {
        try startStub()
    }

    @FuncStub(MockLaunchService.loadUserDataAfterUnlock) var loadUserDataAfterUnlockStub
    func loadUserDataAfterUnlock() {
        loadUserDataAfterUnlockStub()
    }

}

class MockLocalMessageDataServiceProtocol: LocalMessageDataServiceProtocol {
    @FuncStub(MockLocalMessageDataServiceProtocol.cleanMessage) var cleanMessageStub
    func cleanMessage(removeAllDraft: Bool, cleanBadgeAndNotifications: Bool) {
        cleanMessageStub(removeAllDraft, cleanBadgeAndNotifications)
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

    @PropertyStub(\MockLockCacheStatus.isAppLockedAndAppKeyEnabled, initialGet: Bool()) var isAppLockedAndAppKeyEnabledStub
    var isAppLockedAndAppKeyEnabled: Bool {
        isAppLockedAndAppKeyEnabledStub()
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

class MockMenuCoordinatorProtocol: MenuCoordinatorProtocol {
    @FuncStub(MockMenuCoordinatorProtocol.go) var goStub
    func go(to labelInfo: MenuLabel, deepLink: DeepLink?) {
        goStub(labelInfo, deepLink)
    }

    @FuncStub(MockMenuCoordinatorProtocol.closeMenu) var closeMenuStub
    func closeMenu() {
        closeMenuStub()
    }

    @FuncStub(MockMenuCoordinatorProtocol.lockTheScreen) var lockTheScreenStub
    func lockTheScreen() {
        lockTheScreenStub()
    }

    @FuncStub(MockMenuCoordinatorProtocol.update) var updateStub
    func update(menuWidth: CGFloat) {
        updateStub(menuWidth)
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

class MockNWPathProtocol: NWPathProtocol {
    @PropertyStub(\MockNWPathProtocol.pathStatus, initialGet: nil) var pathStatusStub
    var pathStatus: NWPath.Status? {
        pathStatusStub()
    }

    @PropertyStub(\MockNWPathProtocol.isPossiblyConnectedThroughVPN, initialGet: Bool()) var isPossiblyConnectedThroughVPNStub
    var isPossiblyConnectedThroughVPN: Bool {
        isPossiblyConnectedThroughVPNStub()
    }

    @FuncStub(MockNWPathProtocol.usesInterfaceType, initialReturn: Bool()) var usesInterfaceTypeStub
    func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool {
        usesInterfaceTypeStub(type)
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

class MockNotificationHandler: NotificationHandler {
    @FuncStub(MockNotificationHandler.add) var addStub
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
        addStub(request, completionHandler)
    }

    @FuncStub(MockNotificationHandler.removePendingNotificationRequests) var removePendingNotificationRequestsStub
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removePendingNotificationRequestsStub(identifiers)
    }

    @FuncStub(MockNotificationHandler.getPendingNotificationRequests) var getPendingNotificationRequestsStub
    func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void) {
        getPendingNotificationRequestsStub(completionHandler)
    }

    @FuncStub(MockNotificationHandler.getDeliveredNotifications) var getDeliveredNotificationsStub
    func getDeliveredNotifications(completionHandler: @escaping ([UNNotification]) -> Void) {
        getDeliveredNotificationsStub(completionHandler)
    }

    @FuncStub(MockNotificationHandler.removeDeliveredNotifications) var removeDeliveredNotificationsStub
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removeDeliveredNotificationsStub(identifiers)
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

class MockPinCodeProtection: PinCodeProtection {
    @FuncStub(MockPinCodeProtection.activate, initialReturn: Bool()) var activateStub
    func activate(with newPinCode: String) -> Bool {
        activateStub(newPinCode)
    }

    @FuncStub(MockPinCodeProtection.deactivate) var deactivateStub
    func deactivate() {
        deactivateStub()
    }

}

class MockPinCodeSetupRouterProtocol: PinCodeSetupRouterProtocol {
    @FuncStub(MockPinCodeSetupRouterProtocol.go) var goStub
    func go(to step: PinCodeSetupRouter.PinCodeSetUpStep, existingVM: PinCodeSetupViewModel) {
        goStub(step, existingVM)
    }

}

class MockPushDecryptionKeysProvider: PushDecryptionKeysProvider {
    @PropertyStub(\MockPushDecryptionKeysProvider.pushNotificationsDecryptionKeys, initialGet: [DecryptionKey]()) var pushNotificationsDecryptionKeysStub
    var pushNotificationsDecryptionKeys: [DecryptionKey] {
        pushNotificationsDecryptionKeysStub()
    }

}

class MockPushEncryptionManagerProtocol: PushEncryptionManagerProtocol {
    @FuncStub(MockPushEncryptionManagerProtocol.registerDeviceForNotifications) var registerDeviceForNotificationsStub
    func registerDeviceForNotifications(deviceToken: String) {
        registerDeviceForNotificationsStub(deviceToken)
    }

    @FuncStub(MockPushEncryptionManagerProtocol.registerDeviceAfterNewAccountSignIn) var registerDeviceAfterNewAccountSignInStub
    func registerDeviceAfterNewAccountSignIn() {
        registerDeviceAfterNewAccountSignInStub()
    }

    @FuncStub(MockPushEncryptionManagerProtocol.deleteAllCachedData) var deleteAllCachedDataStub
    func deleteAllCachedData() {
        deleteAllCachedDataStub()
    }

}

class MockQueueHandlerRegister: QueueHandlerRegister {
    @FuncStub(MockQueueHandlerRegister.registerHandler) var registerHandlerStub
    func registerHandler(_ handler: QueueHandler) {
        registerHandlerStub(handler)
    }

    @FuncStub(MockQueueHandlerRegister.unregisterHandler) var unregisterHandlerStub
    func unregisterHandler(for userID: UserID, completion: (() -> Void)?) {
        unregisterHandlerStub(userID, completion)
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

class MockRefetchAllBlockedSendersUseCase: RefetchAllBlockedSendersUseCase {
    @FuncStub(MockRefetchAllBlockedSendersUseCase.execute) var executeStub
    func execute(completion: @escaping (Error?) -> Void) {
        executeStub(completion)
    }

}

class MockResumeAfterUnlock: ResumeAfterUnlock {
    @FuncStub(MockResumeAfterUnlock.resume) var resumeStub
    func resume() {
        resumeStub()
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

class MockSettingsAccountCoordinatorProtocol: SettingsAccountCoordinatorProtocol {
    @FuncStub(MockSettingsAccountCoordinatorProtocol.go) var goStub
    func go(to dest: SettingsAccountCoordinator.Destination) {
        goStub(dest)
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

class MockSetupCoreDataService: SetupCoreDataService {
    @ThrowingFuncStub(MockSetupCoreDataService.setup) var setupStub
    func setup() throws {
        try setupStub()
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

class MockTelemetryServiceProtocol: TelemetryServiceProtocol {
    @FuncStub(MockTelemetryServiceProtocol.sendEvent) var sendEventStub
    func sendEvent(_ event: TelemetryEvent) {
        sendEventStub(event)
    }

}

class MockURLOpener: URLOpener {
    @FuncStub(MockURLOpener.canOpenURL, initialReturn: Bool()) var canOpenURLStub
    func canOpenURL(_ url: URL) -> Bool {
        canOpenURLStub(url)
    }

    @FuncStub(MockURLOpener.open) var openStub
    func open(_ url: URL) {
        openStub(url)
    }

}

class MockURLSessionProtocol: URLSessionProtocol {
    @ThrowingFuncStub(MockURLSessionProtocol.data, initialReturn: .crash) var dataStub
    func data(for request: URLRequest) throws -> (Data, URLResponse) {
        try dataStub(request)
    }

}

class MockUndoActionManagerProtocol: UndoActionManagerProtocol {
    @FuncStub(MockUndoActionManagerProtocol.addUndoToken) var addUndoTokenStub
    func addUndoToken(_ token: UndoTokenData, undoActionType: UndoAction?) {
        addUndoTokenStub(token, undoActionType)
    }

    @FuncStub(MockUndoActionManagerProtocol.addUndoTokens) var addUndoTokensStub
    func addUndoTokens(_ tokens: [String], undoActionType: UndoAction?) {
        addUndoTokensStub(tokens, undoActionType)
    }

    @FuncStub(MockUndoActionManagerProtocol.showUndoSendBanner) var showUndoSendBannerStub
    func showUndoSendBanner(for messageID: MessageID) {
        showUndoSendBannerStub(messageID)
    }

    @FuncStub(MockUndoActionManagerProtocol.register) var registerStub
    func register(handler: UndoActionHandlerBase) {
        registerStub(handler)
    }

    @FuncStub(MockUndoActionManagerProtocol.requestUndoAction) var requestUndoActionStub
    func requestUndoAction(undoTokens: [String], completion: ((Bool) -> Void)?) {
        requestUndoActionStub(undoTokens, completion)
    }

    @FuncStub(MockUndoActionManagerProtocol.calculateUndoActionBy, initialReturn: nil) var calculateUndoActionByStub
    func calculateUndoActionBy(labelID: LabelID) -> UndoAction? {
        calculateUndoActionByStub(labelID)
    }

    @FuncStub(MockUndoActionManagerProtocol.addTitleWithAction) var addTitleWithActionStub
    func addTitleWithAction(title: String, action: UndoAction) {
        addTitleWithActionStub(title, action)
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

    @FuncStub(MockUnlockManagerDelegate.isMailboxPasswordStoredForActiveUser, initialReturn: Bool()) var isMailboxPasswordStoredForActiveUserStub
    func isMailboxPasswordStoredForActiveUser() -> Bool {
        isMailboxPasswordStoredForActiveUserStub()
    }

    @ThrowingFuncStub(MockUnlockManagerDelegate.setupCoreData) var setupCoreDataStub
    func setupCoreData() throws {
        try setupCoreDataStub()
    }

    @FuncStub(MockUnlockManagerDelegate.loadUserDataAfterUnlock) var loadUserDataAfterUnlockStub
    func loadUserDataAfterUnlock() {
        loadUserDataAfterUnlockStub()
    }

}

class MockUnlockProvider: UnlockProvider {
    @FuncStub(MockUnlockProvider.isUnlocked, initialReturn: Bool()) var isUnlockedStub
    func isUnlocked() -> Bool {
        isUnlockedStub()
    }

}

class MockUnlockService: UnlockService {
    @FuncStub(MockUnlockService.start, initialReturn: .crash) var startStub
    func start() -> AppAccess {
        startStub()
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

class MockUserNotificationCenterProtocol: UserNotificationCenterProtocol {
    @FuncStub(MockUserNotificationCenterProtocol.authorizationStatus, initialReturn: .crash) var authorizationStatusStub
    func authorizationStatus() -> UNAuthorizationStatus {
        authorizationStatusStub()
    }

    @FuncStub(MockUserNotificationCenterProtocol.removeDeliveredNotifications) var removeDeliveredNotificationsStub
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removeDeliveredNotificationsStub(identifiers)
    }

}

class MockUsersManagerProtocol: UsersManagerProtocol {
    @PropertyStub(\MockUsersManagerProtocol.users, initialGet: [UserManager]()) var usersStub
    var users: [UserManager] {
        usersStub()
    }

    @FuncStub(MockUsersManagerProtocol.hasUsers, initialReturn: Bool()) var hasUsersStub
    func hasUsers() -> Bool {
        hasUsersStub()
    }

}

class MockViewModeUpdater: ViewModeUpdater {
    @FuncStub(MockViewModeUpdater.update) var updateStub
    func update(viewMode: ViewMode, completion: ((Swift.Result<ViewMode?, Error>) -> Void)?) {
        updateStub(viewMode, completion)
    }

}

