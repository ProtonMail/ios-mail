// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// periphery:ignore:all

import ProtonCoreFeatureFlags
import ProtonCoreKeymaker
import ProtonCoreServices

protocol HasAppAccessResolver {
    var appAccessResolver: AppAccessResolver { get }
}

extension GlobalContainer: HasAppAccessResolver {
    var appAccessResolver: AppAccessResolver {
        appAccessResolverFactory()
    }
}

extension UserContainer: HasAppAccessResolver {
    var appAccessResolver: AppAccessResolver {
        globalContainer.appAccessResolver
    }
}

protocol HasAppRatingStatusProvider {
    var appRatingStatusProvider: AppRatingStatusProvider { get }
}

extension GlobalContainer: HasAppRatingStatusProvider {
    var appRatingStatusProvider: AppRatingStatusProvider {
        appRatingStatusProviderFactory()
    }
}

extension UserContainer: HasAppRatingStatusProvider {
    var appRatingStatusProvider: AppRatingStatusProvider {
        globalContainer.appRatingStatusProvider
    }
}

protocol HasCachedUserDataProvider {
    var cachedUserDataProvider: CachedUserDataProvider { get }
}

extension GlobalContainer: HasCachedUserDataProvider {
    var cachedUserDataProvider: CachedUserDataProvider {
        cachedUserDataProviderFactory()
    }
}

extension UserContainer: HasCachedUserDataProvider {
    var cachedUserDataProvider: CachedUserDataProvider {
        globalContainer.cachedUserDataProvider
    }
}

protocol HasCoreDataContextProviderProtocol {
    var contextProvider: CoreDataContextProviderProtocol { get }
}

extension GlobalContainer: HasCoreDataContextProviderProtocol {
    var contextProvider: CoreDataContextProviderProtocol {
        contextProviderFactory()
    }
}

extension UserContainer: HasCoreDataContextProviderProtocol {
    var contextProvider: CoreDataContextProviderProtocol {
        globalContainer.contextProvider
    }
}

protocol HasFeatureFlagCache {
    var featureFlagCache: FeatureFlagCache { get }
}

extension GlobalContainer: HasFeatureFlagCache {
    var featureFlagCache: FeatureFlagCache {
        featureFlagCacheFactory()
    }
}

extension UserContainer: HasFeatureFlagCache {
    var featureFlagCache: FeatureFlagCache {
        globalContainer.featureFlagCache
    }
}

protocol HasInternetConnectionStatusProviderProtocol {
    var internetConnectionStatusProvider: InternetConnectionStatusProviderProtocol { get }
}

extension GlobalContainer: HasInternetConnectionStatusProviderProtocol {
    var internetConnectionStatusProvider: InternetConnectionStatusProviderProtocol {
        internetConnectionStatusProviderFactory()
    }
}

extension UserContainer: HasInternetConnectionStatusProviderProtocol {
    var internetConnectionStatusProvider: InternetConnectionStatusProviderProtocol {
        globalContainer.internetConnectionStatusProvider
    }
}

protocol HasKeychain {
    var keychain: Keychain { get }
}

extension GlobalContainer: HasKeychain {
    var keychain: Keychain {
        keychainFactory()
    }
}

extension UserContainer: HasKeychain {
    var keychain: Keychain {
        globalContainer.keychain
    }
}

protocol HasKeyMakerProtocol {
    var keyMaker: KeyMakerProtocol { get }
}

extension GlobalContainer: HasKeyMakerProtocol {
    var keyMaker: KeyMakerProtocol {
        keyMakerFactory()
    }
}

extension UserContainer: HasKeyMakerProtocol {
    var keyMaker: KeyMakerProtocol {
        globalContainer.keyMaker
    }
}

protocol HasLastUpdatedStoreProtocol {
    var lastUpdatedStore: LastUpdatedStoreProtocol { get }
}

extension GlobalContainer: HasLastUpdatedStoreProtocol {
    var lastUpdatedStore: LastUpdatedStoreProtocol {
        lastUpdatedStoreFactory()
    }
}

extension UserContainer: HasLastUpdatedStoreProtocol {
    var lastUpdatedStore: LastUpdatedStoreProtocol {
        globalContainer.lastUpdatedStore
    }
}

protocol HasLockCacheStatus {
    var lockCacheStatus: LockCacheStatus { get }
}

extension GlobalContainer: HasLockCacheStatus {
    var lockCacheStatus: LockCacheStatus {
        lockCacheStatusFactory()
    }
}

extension UserContainer: HasLockCacheStatus {
    var lockCacheStatus: LockCacheStatus {
        globalContainer.lockCacheStatus
    }
}

protocol HasLockPreventor {
    var lockPreventor: LockPreventor { get }
}

extension GlobalContainer: HasLockPreventor {
    var lockPreventor: LockPreventor {
        lockPreventorFactory()
    }
}

extension UserContainer: HasLockPreventor {
    var lockPreventor: LockPreventor {
        globalContainer.lockPreventor
    }
}

protocol HasLaunchService {
    var launchService: LaunchService { get }
}

extension GlobalContainer: HasLaunchService {
    var launchService: LaunchService {
        launchServiceFactory()
    }
}

extension UserContainer: HasLaunchService {
    var launchService: LaunchService {
        globalContainer.launchService
    }
}

protocol HasMailEventsPeriodicScheduler {
    var mailEventsPeriodicScheduler: MailEventsPeriodicScheduler { get }
}

extension GlobalContainer: HasMailEventsPeriodicScheduler {
    var mailEventsPeriodicScheduler: MailEventsPeriodicScheduler {
        mailEventsPeriodicSchedulerFactory()
    }
}

extension UserContainer: HasMailEventsPeriodicScheduler {
    var mailEventsPeriodicScheduler: MailEventsPeriodicScheduler {
        globalContainer.mailEventsPeriodicScheduler
    }
}

protocol HasNotificationCenter {
    var notificationCenter: NotificationCenter { get }
}

extension GlobalContainer: HasNotificationCenter {
    var notificationCenter: NotificationCenter {
        notificationCenterFactory()
    }
}

extension UserContainer: HasNotificationCenter {
    var notificationCenter: NotificationCenter {
        globalContainer.notificationCenter
    }
}

protocol HasPinCodeProtection {
    var pinCodeProtection: PinCodeProtection { get }
}

extension GlobalContainer: HasPinCodeProtection {
    var pinCodeProtection: PinCodeProtection {
        pinCodeProtectionFactory()
    }
}

extension UserContainer: HasPinCodeProtection {
    var pinCodeProtection: PinCodeProtection {
        globalContainer.pinCodeProtection
    }
}

protocol HasPinCodeVerifier {
    var pinCodeVerifier: PinCodeVerifier { get }
}

extension GlobalContainer: HasPinCodeVerifier {
    var pinCodeVerifier: PinCodeVerifier {
        pinCodeVerifierFactory()
    }
}

extension UserContainer: HasPinCodeVerifier {
    var pinCodeVerifier: PinCodeVerifier {
        globalContainer.pinCodeVerifier
    }
}

protocol HasPushUpdater {
    var pushUpdater: PushUpdater { get }
}

extension GlobalContainer: HasPushUpdater {
    var pushUpdater: PushUpdater {
        pushUpdaterFactory()
    }
}

extension UserContainer: HasPushUpdater {
    var pushUpdater: PushUpdater {
        globalContainer.pushUpdater
    }
}

protocol HasQueueManager {
    var queueManager: QueueManager { get }
}

extension GlobalContainer: HasQueueManager {
    var queueManager: QueueManager {
        queueManagerFactory()
    }
}

extension UserContainer: HasQueueManager {
    var queueManager: QueueManager {
        globalContainer.queueManager
    }
}

protocol HasResumeAfterUnlock {
    var resumeAfterUnlock: ResumeAfterUnlock { get }
}

extension GlobalContainer: HasResumeAfterUnlock {
    var resumeAfterUnlock: ResumeAfterUnlock {
        resumeAfterUnlockFactory()
    }
}

extension UserContainer: HasResumeAfterUnlock {
    var resumeAfterUnlock: ResumeAfterUnlock {
        globalContainer.resumeAfterUnlock
    }
}

protocol HasSetupCoreDataService {
    var setupCoreDataService: SetupCoreDataService { get }
}

extension GlobalContainer: HasSetupCoreDataService {
    var setupCoreDataService: SetupCoreDataService {
        setupCoreDataServiceFactory()
    }
}

extension UserContainer: HasSetupCoreDataService {
    var setupCoreDataService: SetupCoreDataService {
        globalContainer.setupCoreDataService
    }
}

protocol HasUnlockManager {
    var unlockManager: UnlockManager { get }
}

extension GlobalContainer: HasUnlockManager {
    var unlockManager: UnlockManager {
        unlockManagerFactory()
    }
}

extension UserContainer: HasUnlockManager {
    var unlockManager: UnlockManager {
        globalContainer.unlockManager
    }
}

protocol HasUnlockService {
    var unlockService: UnlockService { get }
}

extension GlobalContainer: HasUnlockService {
    var unlockService: UnlockService {
        unlockServiceFactory()
    }
}

extension UserContainer: HasUnlockService {
    var unlockService: UnlockService {
        globalContainer.unlockService
    }
}

protocol HasUserDefaults {
    var userDefaults: UserDefaults { get }
}

extension GlobalContainer: HasUserDefaults {
    var userDefaults: UserDefaults {
        userDefaultsFactory()
    }
}

extension UserContainer: HasUserDefaults {
    var userDefaults: UserDefaults {
        globalContainer.userDefaults
    }
}

protocol HasUsersManager {
    var usersManager: UsersManager { get }
}

extension GlobalContainer: HasUsersManager {
    var usersManager: UsersManager {
        usersManagerFactory()
    }
}

extension UserContainer: HasUsersManager {
    var usersManager: UsersManager {
        globalContainer.usersManager
    }
}

protocol HasUserCachedStatus {
    var userCachedStatus: UserCachedStatus { get }
}

extension GlobalContainer: HasUserCachedStatus {
    var userCachedStatus: UserCachedStatus {
        userCachedStatusFactory()
    }
}

extension UserContainer: HasUserCachedStatus {
    var userCachedStatus: UserCachedStatus {
        globalContainer.userCachedStatus
    }
}

protocol HasUserIntroductionProgressProvider {
    var userIntroductionProgressProvider: UserIntroductionProgressProvider { get }
}

extension GlobalContainer: HasUserIntroductionProgressProvider {
    var userIntroductionProgressProvider: UserIntroductionProgressProvider {
        userIntroductionProgressProviderFactory()
    }
}

extension UserContainer: HasUserIntroductionProgressProvider {
    var userIntroductionProgressProvider: UserIntroductionProgressProvider {
        globalContainer.userIntroductionProgressProvider
    }
}

protocol HasFeatureFlagsRepository {
    var featureFlagsRepository: FeatureFlagsRepository { get }
}

extension GlobalContainer: HasFeatureFlagsRepository {
    var featureFlagsRepository: FeatureFlagsRepository {
        featureFlagsRepositoryFactory()
    }
}

extension UserContainer: HasFeatureFlagsRepository {
    var featureFlagsRepository: FeatureFlagsRepository {
        globalContainer.featureFlagsRepository
    }
}

protocol HasAPIService {
    var apiService: APIService { get }
}

extension UserContainer: HasAPIService {
    var apiService: APIService {
        apiServiceFactory()
    }
}

protocol HasAutoImportContactsFeature {
    var autoImportContactsFeature: AutoImportContactsFeature { get }
}

extension UserContainer: HasAutoImportContactsFeature {
    var autoImportContactsFeature: AutoImportContactsFeature {
        autoImportContactsFeatureFactory()
    }
}

protocol HasCacheService {
    var cacheService: CacheService { get }
}

extension UserContainer: HasCacheService {
    var cacheService: CacheService {
        cacheServiceFactory()
    }
}

protocol HasContactsSyncQueueProtocol {
    var contactSyncQueue: ContactsSyncQueueProtocol { get }
}

extension UserContainer: HasContactsSyncQueueProtocol {
    var contactSyncQueue: ContactsSyncQueueProtocol {
        contactSyncQueueFactory()
    }
}

protocol HasComposerViewFactory {
    var composerViewFactory: ComposerViewFactory { get }
}

extension UserContainer: HasComposerViewFactory {
    var composerViewFactory: ComposerViewFactory {
        composerViewFactoryFactory()
    }
}

protocol HasContactDataService {
    var contactService: ContactDataService { get }
}

extension UserContainer: HasContactDataService {
    var contactService: ContactDataService {
        contactServiceFactory()
    }
}

protocol HasContactGroupsDataService {
    var contactGroupService: ContactGroupsDataService { get }
}

extension UserContainer: HasContactGroupsDataService {
    var contactGroupService: ContactGroupsDataService {
        contactGroupServiceFactory()
    }
}

protocol HasConversationDataServiceProxy {
    var conversationService: ConversationDataServiceProxy { get }
}

extension UserContainer: HasConversationDataServiceProxy {
    var conversationService: ConversationDataServiceProxy {
        conversationServiceFactory()
    }
}

protocol HasConversationStateService {
    var conversationStateService: ConversationStateService { get }
}

extension UserContainer: HasConversationStateService {
    var conversationStateService: ConversationStateService {
        conversationStateServiceFactory()
    }
}

protocol HasEventProcessor {
    var eventProcessor: EventProcessor { get }
}

extension UserContainer: HasEventProcessor {
    var eventProcessor: EventProcessor {
        eventProcessorFactory()
    }
}

protocol HasEventsFetching {
    var eventsService: EventsFetching { get }
}

extension UserContainer: HasEventsFetching {
    var eventsService: EventsFetching {
        eventsServiceFactory()
    }
}

protocol HasFeatureFlagsDownloadService {
    var featureFlagsDownloadService: FeatureFlagsDownloadService { get }
}

extension UserContainer: HasFeatureFlagsDownloadService {
    var featureFlagsDownloadService: FeatureFlagsDownloadService {
        featureFlagsDownloadServiceFactory()
    }
}

protocol HasFeatureFlagProvider {
    var featureFlagProvider: FeatureFlagProvider { get }
}

extension UserContainer: HasFeatureFlagProvider {
    var featureFlagProvider: FeatureFlagProvider {
        featureFlagProviderFactory()
    }
}

protocol HasFetchAndVerifyContactsUseCase {
    var fetchAndVerifyContacts: FetchAndVerifyContactsUseCase { get }
}

extension UserContainer: HasFetchAndVerifyContactsUseCase {
    var fetchAndVerifyContacts: FetchAndVerifyContactsUseCase {
        fetchAndVerifyContactsFactory()
    }
}

protocol HasFetchAttachmentUseCase {
    var fetchAttachment: FetchAttachmentUseCase { get }
}

extension UserContainer: HasFetchAttachmentUseCase {
    var fetchAttachment: FetchAttachmentUseCase {
        fetchAttachmentFactory()
    }
}

protocol HasFetchAttachmentMetadataUseCase {
    var fetchAttachmentMetadata: FetchAttachmentMetadataUseCase { get }
}

extension UserContainer: HasFetchAttachmentMetadataUseCase {
    var fetchAttachmentMetadata: FetchAttachmentMetadataUseCase {
        fetchAttachmentMetadataFactory()
    }
}

protocol HasFetchEmailAddressesPublicKey {
    var fetchEmailAddressesPublicKey: FetchEmailAddressesPublicKey { get }
}

extension UserContainer: HasFetchEmailAddressesPublicKey {
    var fetchEmailAddressesPublicKey: FetchEmailAddressesPublicKey {
        fetchEmailAddressesPublicKeyFactory()
    }
}

protocol HasFetchMessageDetailUseCase {
    var fetchMessageDetail: FetchMessageDetailUseCase { get }
}

extension UserContainer: HasFetchMessageDetailUseCase {
    var fetchMessageDetail: FetchMessageDetailUseCase {
        fetchMessageDetailFactory()
    }
}

protocol HasFetchMessageMetaData {
    var fetchMessageMetaData: FetchMessageMetaData { get }
}

extension UserContainer: HasFetchMessageMetaData {
    var fetchMessageMetaData: FetchMessageMetaData {
        fetchMessageMetaDataFactory()
    }
}

protocol HasImageProxy {
    var imageProxy: ImageProxy { get }
}

extension UserContainer: HasImageProxy {
    var imageProxy: ImageProxy {
        imageProxyFactory()
    }
}

protocol HasIncomingDefaultService {
    var incomingDefaultService: IncomingDefaultService { get }
}

extension UserContainer: HasIncomingDefaultService {
    var incomingDefaultService: IncomingDefaultService {
        incomingDefaultServiceFactory()
    }
}

protocol HasLabelsDataService {
    var labelService: LabelsDataService { get }
}

extension UserContainer: HasLabelsDataService {
    var labelService: LabelsDataService {
        labelServiceFactory()
    }
}

protocol HasLocalNotificationService {
    var localNotificationService: LocalNotificationService { get }
}

extension UserContainer: HasLocalNotificationService {
    var localNotificationService: LocalNotificationService {
        localNotificationServiceFactory()
    }
}

protocol HasMessageDataService {
    var messageService: MessageDataService { get }
}

extension UserContainer: HasMessageDataService {
    var messageService: MessageDataService {
        messageServiceFactory()
    }
}

protocol HasQueueHandler {
    var queueHandler: QueueHandler { get }
}

extension UserContainer: HasQueueHandler {
    var queueHandler: QueueHandler {
        queueHandlerFactory()
    }
}

protocol HasTelemetryServiceProtocol {
    var telemetryService: TelemetryServiceProtocol { get }
}

extension UserContainer: HasTelemetryServiceProtocol {
    var telemetryService: TelemetryServiceProtocol {
        telemetryServiceFactory()
    }
}

protocol HasUndoActionManagerProtocol {
    var undoActionManager: UndoActionManagerProtocol { get }
}

extension UserContainer: HasUndoActionManagerProtocol {
    var undoActionManager: UndoActionManagerProtocol {
        undoActionManagerFactory()
    }
}

protocol HasUserDataService {
    var userService: UserDataService { get }
}

extension UserContainer: HasUserDataService {
    var userService: UserDataService {
        userServiceFactory()
    }
}

protocol HasUserManager {
    var user: UserManager { get }
}

extension UserContainer: HasUserManager {
    var user: UserManager {
        userFactory()
    }
}

