// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import ProtonCore_Payments

protocol HasAddressBookService {
    var addressBookService: AddressBookService { get }
}

extension GlobalContainer: HasAddressBookService {
    var addressBookService: AddressBookService {
        addressBookServiceFactory()
    }
}

extension UserContainer: HasAddressBookService {
    var addressBookService: AddressBookService {
        globalContainer.addressBookService
    }
}

protocol HasBackgroundTaskHelper {
    var backgroundTaskHelper: BackgroundTaskHelper { get }
}

extension GlobalContainer: HasBackgroundTaskHelper {
    var backgroundTaskHelper: BackgroundTaskHelper {
        backgroundTaskHelperFactory()
    }
}

extension UserContainer: HasBackgroundTaskHelper {
    var backgroundTaskHelper: BackgroundTaskHelper {
        globalContainer.backgroundTaskHelper
    }
}

protocol HasBiometricStatusProvider {
    var biometricStatusProvider: BiometricStatusProvider { get }
}

extension GlobalContainer: HasBiometricStatusProvider {
    var biometricStatusProvider: BiometricStatusProvider {
        biometricStatusProviderFactory()
    }
}

extension UserContainer: HasBiometricStatusProvider {
    var biometricStatusProvider: BiometricStatusProvider {
        globalContainer.biometricStatusProvider
    }
}

protocol HasCleanCache {
    var cleanCache: CleanCache { get }
}

extension GlobalContainer: HasCleanCache {
    var cleanCache: CleanCache {
        cleanCacheFactory()
    }
}

extension UserContainer: HasCleanCache {
    var cleanCache: CleanCache {
        globalContainer.cleanCache
    }
}

protocol HasDarkModeCacheProtocol {
    var darkModeCache: DarkModeCacheProtocol { get }
}

extension GlobalContainer: HasDarkModeCacheProtocol {
    var darkModeCache: DarkModeCacheProtocol {
        darkModeCacheFactory()
    }
}

extension UserContainer: HasDarkModeCacheProtocol {
    var darkModeCache: DarkModeCacheProtocol {
        globalContainer.darkModeCache
    }
}

protocol HasPushNotificationService {
    var pushService: PushNotificationService { get }
}

extension GlobalContainer: HasPushNotificationService {
    var pushService: PushNotificationService {
        pushServiceFactory()
    }
}

extension UserContainer: HasPushNotificationService {
    var pushService: PushNotificationService {
        globalContainer.pushService
    }
}

protocol HasSaveSwipeActionSettingForUsersUseCase {
    var saveSwipeActionSetting: SaveSwipeActionSettingForUsersUseCase { get }
}

extension GlobalContainer: HasSaveSwipeActionSettingForUsersUseCase {
    var saveSwipeActionSetting: SaveSwipeActionSettingForUsersUseCase {
        saveSwipeActionSettingFactory()
    }
}

extension UserContainer: HasSaveSwipeActionSettingForUsersUseCase {
    var saveSwipeActionSetting: SaveSwipeActionSettingForUsersUseCase {
        globalContainer.saveSwipeActionSetting
    }
}

protocol HasSignInManager {
    var signInManager: SignInManager { get }
}

extension GlobalContainer: HasSignInManager {
    var signInManager: SignInManager {
        signInManagerFactory()
    }
}

extension UserContainer: HasSignInManager {
    var signInManager: SignInManager {
        globalContainer.signInManager
    }
}

protocol HasStoreKitManagerImpl {
    var storeKitManager: StoreKitManagerImpl { get }
}

extension GlobalContainer: HasStoreKitManagerImpl {
    var storeKitManager: StoreKitManagerImpl {
        storeKitManagerFactory()
    }
}

extension UserContainer: HasStoreKitManagerImpl {
    var storeKitManager: StoreKitManagerImpl {
        globalContainer.storeKitManager
    }
}

protocol HasSwipeActionCacheProtocol {
    var swipeActionCache: SwipeActionCacheProtocol { get }
}

extension GlobalContainer: HasSwipeActionCacheProtocol {
    var swipeActionCache: SwipeActionCacheProtocol {
        swipeActionCacheFactory()
    }
}

extension UserContainer: HasSwipeActionCacheProtocol {
    var swipeActionCache: SwipeActionCacheProtocol {
        globalContainer.swipeActionCache
    }
}

protocol HasToolbarCustomizationInfoBubbleViewStatusProvider {
    var toolbarCustomizationInfoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider { get }
}

extension GlobalContainer: HasToolbarCustomizationInfoBubbleViewStatusProvider {
    var toolbarCustomizationInfoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider {
        toolbarCustomizationInfoBubbleViewStatusProviderFactory()
    }
}

extension UserContainer: HasToolbarCustomizationInfoBubbleViewStatusProvider {
    var toolbarCustomizationInfoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider {
        globalContainer.toolbarCustomizationInfoBubbleViewStatusProvider
    }
}

protocol HasAppRatingService {
    var appRatingService: AppRatingService { get }
}

extension UserContainer: HasAppRatingService {
    var appRatingService: AppRatingService {
        appRatingServiceFactory()
    }
}

protocol HasBlockedSenderCacheUpdater {
    var blockedSenderCacheUpdater: BlockedSenderCacheUpdater { get }
}

extension UserContainer: HasBlockedSenderCacheUpdater {
    var blockedSenderCacheUpdater: BlockedSenderCacheUpdater {
        blockedSenderCacheUpdaterFactory()
    }
}

protocol HasBlockedSendersPublisher {
    var blockedSendersPublisher: BlockedSendersPublisher { get }
}

extension UserContainer: HasBlockedSendersPublisher {
    var blockedSendersPublisher: BlockedSendersPublisher {
        blockedSendersPublisherFactory()
    }
}

protocol HasBugReportService {
    var reportService: BugReportService { get }
}

extension UserContainer: HasBugReportService {
    var reportService: BugReportService {
        reportServiceFactory()
    }
}

protocol HasContactViewsFactory {
    var contactViewsFactory: ContactViewsFactory { get }
}

extension UserContainer: HasContactViewsFactory {
    var contactViewsFactory: ContactViewsFactory {
        contactViewsFactoryFactory()
    }
}

protocol HasFetchSenderImage {
    var fetchSenderImage: FetchSenderImage { get }
}

extension UserContainer: HasFetchSenderImage {
    var fetchSenderImage: FetchSenderImage {
        fetchSenderImageFactory()
    }
}

protocol HasSearchUseCase {
    var messageSearch: SearchUseCase { get }
}

extension UserContainer: HasSearchUseCase {
    var messageSearch: SearchUseCase {
        messageSearchFactory()
    }
}

protocol HasNextMessageAfterMoveStatusProvider {
    var nextMessageAfterMoveStatusProvider: NextMessageAfterMoveStatusProvider { get }
}

extension UserContainer: HasNextMessageAfterMoveStatusProvider {
    var nextMessageAfterMoveStatusProvider: NextMessageAfterMoveStatusProvider {
        nextMessageAfterMoveStatusProviderFactory()
    }
}

protocol HasPayments {
    var payments: Payments { get }
}

extension UserContainer: HasPayments {
    var payments: Payments {
        paymentsFactory()
    }
}

protocol HasPaymentsUIFactory {
    var paymentsUIFactory: PaymentsUIFactory { get }
}

extension UserContainer: HasPaymentsUIFactory {
    var paymentsUIFactory: PaymentsUIFactory {
        paymentsUIFactoryFactory()
    }
}

protocol HasSettingsViewsFactory {
    var settingsViewsFactory: SettingsViewsFactory { get }
}

extension UserContainer: HasSettingsViewsFactory {
    var settingsViewsFactory: SettingsViewsFactory {
        settingsViewsFactoryFactory()
    }
}

protocol HasSaveToolbarActionSettings {
    var saveToolbarActionSettings: SaveToolbarActionSettings { get }
}

extension UserContainer: HasSaveToolbarActionSettings {
    var saveToolbarActionSettings: SaveToolbarActionSettings {
        saveToolbarActionSettingsFactory()
    }
}

protocol HasSendBugReport {
    var sendBugReport: SendBugReport { get }
}

extension UserContainer: HasSendBugReport {
    var sendBugReport: SendBugReport {
        sendBugReportFactory()
    }
}

protocol HasToolbarActionProvider {
    var toolbarActionProvider: ToolbarActionProvider { get }
}

extension UserContainer: HasToolbarActionProvider {
    var toolbarActionProvider: ToolbarActionProvider {
        toolbarActionProviderFactory()
    }
}

protocol HasToolbarSettingViewFactory {
    var toolbarSettingViewFactory: ToolbarSettingViewFactory { get }
}

extension UserContainer: HasToolbarSettingViewFactory {
    var toolbarSettingViewFactory: ToolbarSettingViewFactory {
        toolbarSettingViewFactoryFactory()
    }
}

protocol HasUnblockSender {
    var unblockSender: UnblockSender { get }
}

extension UserContainer: HasUnblockSender {
    var unblockSender: UnblockSender {
        unblockSenderFactory()
    }
}

