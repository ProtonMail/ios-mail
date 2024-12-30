// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// periphery:ignore:all

import ProtonCorePayments
import ProtonInboxRSVP

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

protocol HasCheckProtonServerStatus {
    var checkProtonServerStatus: CheckProtonServerStatus { get }
}

extension GlobalContainer: HasCheckProtonServerStatus {
    var checkProtonServerStatus: CheckProtonServerStatus {
        checkProtonServerStatusFactory()
    }
}

extension UserContainer: HasCheckProtonServerStatus {
    var checkProtonServerStatus: CheckProtonServerStatus {
        globalContainer.checkProtonServerStatus
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

protocol HasContactPickerModelHelper {
    var contactPickerModelHelper: ContactPickerModelHelper { get }
}

extension GlobalContainer: HasContactPickerModelHelper {
    var contactPickerModelHelper: ContactPickerModelHelper {
        contactPickerModelHelperFactory()
    }
}

extension UserContainer: HasContactPickerModelHelper {
    var contactPickerModelHelper: ContactPickerModelHelper {
        globalContainer.contactPickerModelHelper
    }
}

protocol HasDeviceContactsProvider {
    var deviceContacts: DeviceContactsProvider { get }
}

extension GlobalContainer: HasDeviceContactsProvider {
    var deviceContacts: DeviceContactsProvider {
        deviceContactsFactory()
    }
}

extension UserContainer: HasDeviceContactsProvider {
    var deviceContacts: DeviceContactsProvider {
        globalContainer.deviceContacts
    }
}

protocol HasImageProxyCacheProtocol {
    var imageProxyCache: ImageProxyCacheProtocol { get }
}

extension GlobalContainer: HasImageProxyCacheProtocol {
    var imageProxyCache: ImageProxyCacheProtocol {
        imageProxyCacheFactory()
    }
}

extension UserContainer: HasImageProxyCacheProtocol {
    var imageProxyCache: ImageProxyCacheProtocol {
        globalContainer.imageProxyCache
    }
}

protocol HasMailboxMessageCellHelper {
    var mailboxMessageCellHelper: MailboxMessageCellHelper { get }
}

extension GlobalContainer: HasMailboxMessageCellHelper {
    var mailboxMessageCellHelper: MailboxMessageCellHelper {
        mailboxMessageCellHelperFactory()
    }
}

extension UserContainer: HasMailboxMessageCellHelper {
    var mailboxMessageCellHelper: MailboxMessageCellHelper {
        globalContainer.mailboxMessageCellHelper
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

protocol HasSenderImageCache {
    var senderImageCache: SenderImageCache { get }
}

extension GlobalContainer: HasSenderImageCache {
    var senderImageCache: SenderImageCache {
        senderImageCacheFactory()
    }
}

extension UserContainer: HasSenderImageCache {
    var senderImageCache: SenderImageCache {
        globalContainer.senderImageCache
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

protocol HasStoreKitManagerDelegateImpl {
    var storeKitManagerDelegate: StoreKitManagerDelegateImpl { get }
}

extension GlobalContainer: HasStoreKitManagerDelegateImpl {
    var storeKitManagerDelegate: StoreKitManagerDelegateImpl {
        storeKitManagerDelegateFactory()
    }
}

extension UserContainer: HasStoreKitManagerDelegateImpl {
    var storeKitManagerDelegate: StoreKitManagerDelegateImpl {
        globalContainer.storeKitManagerDelegate
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

protocol HasURLOpener {
    var urlOpener: URLOpener { get }
}

extension GlobalContainer: HasURLOpener {
    var urlOpener: URLOpener {
        urlOpenerFactory()
    }
}

extension UserContainer: HasURLOpener {
    var urlOpener: URLOpener {
        globalContainer.urlOpener
    }
}

protocol HasUserNotificationCenterProtocol {
    var userNotificationCenter: UserNotificationCenterProtocol { get }
}

extension GlobalContainer: HasUserNotificationCenterProtocol {
    var userNotificationCenter: UserNotificationCenterProtocol {
        userNotificationCenterFactory()
    }
}

extension UserContainer: HasUserNotificationCenterProtocol {
    var userNotificationCenter: UserNotificationCenterProtocol {
        globalContainer.userNotificationCenter
    }
}

protocol HasAnswerInvitation {
    var answerInvitation: AnswerInvitation { get }
}

extension UserContainer: HasAnswerInvitation {
    var answerInvitation: AnswerInvitation {
        answerInvitationFactory()
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

protocol HasCleanUserLocalMessages {
    var cleanUserLocalMessages: CleanUserLocalMessages { get }
}

extension UserContainer: HasCleanUserLocalMessages {
    var cleanUserLocalMessages: CleanUserLocalMessages {
        cleanUserLocalMessagesFactory()
    }
}

protocol HasEmailAddressStorage {
    var emailAddressStorage: EmailAddressStorage { get }
}

extension UserContainer: HasEmailAddressStorage {
    var emailAddressStorage: EmailAddressStorage {
        emailAddressStorageFactory()
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

protocol HasExtractBasicEventInfo {
    var extractBasicEventInfo: ExtractBasicEventInfo { get }
}

extension UserContainer: HasExtractBasicEventInfo {
    var extractBasicEventInfo: ExtractBasicEventInfo {
        extractBasicEventInfoFactory()
    }
}

protocol HasFetchEventDetails {
    var fetchEventDetails: FetchEventDetails { get }
}

extension UserContainer: HasFetchEventDetails {
    var fetchEventDetails: FetchEventDetails {
        fetchEventDetailsFactory()
    }
}

protocol HasFetchMessages {
    var fetchMessages: FetchMessages { get }
}

extension UserContainer: HasFetchMessages {
    var fetchMessages: FetchMessages {
        fetchMessagesFactory()
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

protocol HasImportDeviceContacts {
    var importDeviceContacts: ImportDeviceContacts { get }
}

extension UserContainer: HasImportDeviceContacts {
    var importDeviceContacts: ImportDeviceContacts {
        importDeviceContactsFactory()
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

protocol HasOnboardingUpsellPageFactory {
    var onboardingUpsellPageFactory: OnboardingUpsellPageFactory { get }
}

extension UserContainer: HasOnboardingUpsellPageFactory {
    var onboardingUpsellPageFactory: OnboardingUpsellPageFactory {
        onboardingUpsellPageFactoryFactory()
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

protocol HasPlanService {
    var planService: PlanService { get }
}

extension UserContainer: HasPlanService {
    var planService: PlanService {
        planServiceFactory()
    }
}

protocol HasPurchaseManagerProtocol {
    var purchaseManager: PurchaseManagerProtocol { get }
}

extension UserContainer: HasPurchaseManagerProtocol {
    var purchaseManager: PurchaseManagerProtocol {
        purchaseManagerFactory()
    }
}

protocol HasPurchasePlan {
    var purchasePlan: PurchasePlan { get }
}

extension UserContainer: HasPurchasePlan {
    var purchasePlan: PurchasePlan {
        purchasePlanFactory()
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

protocol HasStoreKitManagerProtocol {
    var storeKitManager: StoreKitManagerProtocol { get }
}

extension UserContainer: HasStoreKitManagerProtocol {
    var storeKitManager: StoreKitManagerProtocol {
        storeKitManagerFactory()
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

protocol HasUpdateMailbox {
    var updateMailbox: UpdateMailbox { get }
}

extension UserContainer: HasUpdateMailbox {
    var updateMailbox: UpdateMailbox {
        updateMailboxFactory()
    }
}

protocol HasUpsellButtonStateProvider {
    var upsellButtonStateProvider: UpsellButtonStateProvider { get }
}

extension UserContainer: HasUpsellButtonStateProvider {
    var upsellButtonStateProvider: UpsellButtonStateProvider {
        upsellButtonStateProviderFactory()
    }
}

protocol HasUpsellPageFactory {
    var upsellPageFactory: UpsellPageFactory { get }
}

extension UserContainer: HasUpsellPageFactory {
    var upsellPageFactory: UpsellPageFactory {
        upsellPageFactoryFactory()
    }
}

protocol HasUpsellOfferProvider {
    var upsellOfferProvider: UpsellOfferProvider { get }
}

extension UserContainer: HasUpsellOfferProvider {
    var upsellOfferProvider: UpsellOfferProvider {
        upsellOfferProviderFactory()
    }
}

protocol HasUpsellTelemetryReporter {
    var upsellTelemetryReporter: UpsellTelemetryReporter { get }
}

extension UserContainer: HasUpsellTelemetryReporter {
    var upsellTelemetryReporter: UpsellTelemetryReporter {
        upsellTelemetryReporterFactory()
    }
}

