// Generated using Sourcery 2.2.6 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// periphery:ignore:all
import Foundation
import proton_app_uniffi

public extension AttachmentDataResult {
    func get() throws(ProtonError) -> AttachmentData {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AttachmentListRemoveResult {
    func get() throws(ProtonError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension BodyOutputResult {
    func get() throws(ProtonError) -> BodyOutput {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ChallengeLoaderGetResult {
    func get() throws(ProtonError) -> ChallengeLoaderResponse {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ChallengeLoaderPostResult {
    func get() throws(ProtonError) -> ChallengeLoaderResponse {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ChallengeLoaderPutResult {
    func get() throws(ProtonError) -> ChallengeLoaderResponse {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationScrollerChangeFilterResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationScrollerChangeIncludeResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationScrollerCursorResult {
    func get() throws(MailScrollerError) -> MailConversationCursor {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationScrollerFetchMoreResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationScrollerFetchNewResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationScrollerForceRefreshResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationScrollerGetItemsResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationScrollerHasMoreResult {
    func get() throws(MailScrollerError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationScrollerRefreshResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationScrollerSupportsIncludeFilterResult {
    func get() throws(MailScrollerError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationScrollerTotalResult {
    func get() throws(MailScrollerError) -> UInt64 {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension CreateMailSessionResult {
    func get() throws(UserSessionError) -> MailSession {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension CustomSettingsMobileSignatureResult {
    func get() throws(ProtonError) -> MobileSignature {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension CustomSettingsSetMobileSignatureEnabledResult {
    func get() throws(ProtonError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension CustomSettingsSetMobileSignatureResult {
    func get() throws(ProtonError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension CustomSettingsSetSwipeToAdjacentConversationResult {
    func get() throws(ProtonError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension CustomSettingsSwipeToAdjacentConversationResult {
    func get() throws(ProtonError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension DraftExpirationTimeResult {
    func get() throws(ProtonError) -> DraftExpirationTime {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension DraftGetPasswordResult {
    func get() throws(ProtonError) -> DraftPassword? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension DraftHtmlForComposerResult {
    func get() throws(ProtonError) -> HtmlForComposer {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension DraftIsPasswordProtectedResult {
    func get() throws(ProtonError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension DraftListSenderAddressesResult {
    func get() throws(ProtonError) -> DraftSenderAddressList {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension DraftMessageIdResult {
    func get() throws(ProtonError) -> Id? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension DraftScheduleSendOptionsResult {
    func get() throws(ProtonError) -> DraftScheduleSendOptions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension DraftSendResultUnseenResult {
    func get() throws(ProtonError) -> [DraftSendResult] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension DraftValidateRecipientsExpirationFeatureResult {
    func get() throws(ProtonError) -> DraftRecipientExpirationFeatureReport {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension GetContactDetailsResult {
    func get() throws(UserSessionError) -> ContactDetailCard {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension IosShareExtInitDraftResult {
    func get() throws(ProtonError) -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension IosShareExtSaveDraftResult {
    func get() throws(ProtonError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension LoginFlowCheckHostDeviceConfirmationResult {
    func get() throws(LoginError) -> QrPollingResult {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension LoginFlowDelinquentStateResult {
    func get() throws(LoginError) -> DelinquentState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension LoginFlowGenerateSignInQrCodeResult {
    func get() throws(LoginError) -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension LoginFlowGetFidoDetailsResult {
    func get() throws(LoginError) -> Fido2ResponseFfi? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension LoginFlowLoginResult {
    func get() throws(LoginError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension LoginFlowMigrateResult {
    func get() throws(LoginError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension LoginFlowSessionIdResult {
    func get() throws(LoginError) -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension LoginFlowSubmitFidoResult {
    func get() throws(LoginError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension LoginFlowSubmitMailboxPasswordResult {
    func get() throws(LoginError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension LoginFlowSubmitNewPasswordResult {
    func get() throws(LoginError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension LoginFlowSubmitTotpResult {
    func get() throws(LoginError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension LoginFlowUserIdResult {
    func get() throws(LoginError) -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailConversationCursorFetchNextResult {
    func get() throws(MailScrollerError) -> Conversation? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailMessageCursorFetchNextResult {
    func get() throws(MailScrollerError) -> Message? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionAppProtectionResult {
    func get() throws(UserSessionError) -> AppProtection {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionChangeAppSettingsResult {
    func get() throws(UserSessionError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionExportLogsResult {
    func get() throws(ProtonError) -> UInt64 {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetAccountResult {
    func get() throws(UserSessionError) -> StoredAccount? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetAccountSessionsResult {
    func get() throws(UserSessionError) -> [StoredSession] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetAccountStateResult {
    func get() throws(UserSessionError) -> StoredAccountState? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetAccountsResult {
    func get() throws(UserSessionError) -> [StoredAccount] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetAppSettingsResult {
    func get() throws(UserSessionError) -> AppSettings {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetPrimaryAccountResult {
    func get() throws(UserSessionError) -> StoredAccount? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetSessionResult {
    func get() throws(UserSessionError) -> StoredSession? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetSessionStateResult {
    func get() throws(UserSessionError) -> StoredSessionState? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetSessionsResult {
    func get() throws(UserSessionError) -> [StoredSession] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionInitializedUserSessionFromStoredSessionResult {
    func get() throws(UserSessionError) -> MailUserSession? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionIsFeatureEnabledResult {
    func get() throws(ProtonError) -> Bool? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionNewLoginFlowResult {
    func get() throws(ProtonError) -> LoginFlow {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionNewSignupFlowResult {
    func get() throws(ProtonError) -> SignupFlow {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionRemainingPinAttemptsResult {
    func get() throws(UserSessionError) -> UInt32? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionResumeLoginFlowResult {
    func get() throws(ProtonError) -> LoginFlow {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionSetBiometricsAppProtectionResult {
    func get() throws(UserSessionError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionShouldAutoLockResult {
    func get() throws(UserSessionError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionSignOutAllResult {
    func get() throws(UserSessionError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionStartBackgroundExecutionResult {
    func get() throws(UserSessionError) -> BackgroundExecutionHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionStartBackgroundExecutionWithDurationResult {
    func get() throws(UserSessionError) -> BackgroundExecutionHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionToPrimaryUserSessionResult {
    func get() throws(UserSessionError) -> MailUserSession {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionToUserSessionResult {
    func get() throws(UserSessionError) -> MailUserSession {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionUnsetBiometricsAppProtectionResult {
    func get() throws(UserSessionError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionUserSessionFromStoredSessionResult {
    func get() throws(UserSessionError) -> MailUserSession {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchAccountSessionsResult {
    func get() throws(UserSessionError) -> WatchedSessions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchAccountsAsyncResult {
    func get() throws(UserSessionError) -> WatchedAccounts {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchAccountsResult {
    func get() throws(UserSessionError) -> WatchedAccounts {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchFeatureFlagsAsyncResult {
    func get() throws(ProtonError) -> WatchedFeatureFlags {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchFeatureFlagsResult {
    func get() throws(ProtonError) -> WatchedFeatureFlags {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchSessionsAsyncResult {
    func get() throws(UserSessionError) -> WatchedSessions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchSessionsResult {
    func get() throws(UserSessionError) -> WatchedSessions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSettingsResult {
    func get() throws(UserSessionError) -> MailSettings {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSettingsSyncResult {
    func get() throws(UserSessionError) -> MailSettings {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionAccountDetailsResult {
    func get() throws(UserSessionError) -> AccountDetails {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionApplicableLabelsResult {
    func get() throws(UserSessionError) -> [SidebarCustomLabel] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionConnectionStatusResult {
    func get() throws(UserSessionError) -> ConnectionStatus {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionForkResult {
    func get() throws(UserSessionError) -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionGetPaymentsPlansResult {
    func get() throws(UserSessionError) -> PaymentsPlans {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionGetPaymentsResourcesIconsResult {
    func get() throws(UserSessionError) -> Data {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionGetPaymentsStatusResult {
    func get() throws(UserSessionError) -> PaymentsStatus {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionGetPaymentsSubscriptionResult {
    func get() throws(UserSessionError) -> Subscriptions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionImageForSenderResult {
    func get() throws(UserSessionError) -> String? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionMovableFoldersResult {
    func get() throws(UserSessionError) -> [SidebarCustomFolder] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionNewPasswordChangeFlowResult {
    func get() throws(UserSessionError) -> PasswordFlow {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionPostPaymentsSubscriptionResult {
    func get() throws(UserSessionError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionPostPaymentsTokensResult {
    func get() throws(UserSessionError) -> PaymentToken {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionSessionIdResult {
    func get() throws(ProtonError) -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionSessionUuidResult {
    func get() throws(UserSessionError) -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionUserIdResult {
    func get() throws(ProtonError) -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionUserResult {
    func get() throws(UserSessionError) -> User {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionUserSettingsResult {
    func get() throws(UserSessionError) -> UserSettings {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionWatchAddressesResult {
    func get() throws(ProtonError) -> WatchHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionWatchLabelsResult {
    func get() throws(ProtonError) -> WatchHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionWatchUserResult {
    func get() throws(ProtonError) -> WatchHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionWatchUserSettingsResult {
    func get() throws(ProtonError) -> WatchHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailboxUnreadCountResult {
    func get() throws(UserSessionError) -> UInt64 {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailboxWatchUnreadCountResult {
    func get() throws(UserSessionError) -> WatchHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MessageScrollerChangeFilterResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MessageScrollerChangeIncludeResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MessageScrollerCursorResult {
    func get() throws(MailScrollerError) -> MailMessageCursor {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MessageScrollerFetchMoreResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MessageScrollerFetchNewResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MessageScrollerForceRefreshResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MessageScrollerGetItemsResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MessageScrollerHasMoreResult {
    func get() throws(MailScrollerError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MessageScrollerRefreshResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MessageScrollerSupportsIncludeFilterResult {
    func get() throws(MailScrollerError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MessageScrollerTotalResult {
    func get() throws(MailScrollerError) -> UInt64 {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension NewAllMailMailboxResult {
    func get() throws(UserSessionError) -> Mailbox {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension NewChallengeLoaderResult {
    func get() throws(ProtonError) -> ChallengeLoader {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension NewDraftSendWatcherResult {
    func get() throws(ProtonError) -> DraftSendResultWatcher {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension NewInboxMailboxResult {
    func get() throws(UserSessionError) -> Mailbox {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension NewMailboxResult {
    func get() throws(UserSessionError) -> Mailbox {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ResolveSystemLabelByIdResult {
    func get() throws(ProtonError) -> SystemLabel? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ResolveSystemLabelIdResult {
    func get() throws(ProtonError) -> Id? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension RsvpEventGetResult {
    func get() throws(ProtonError) -> RsvpEvent {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SearchScrollerChangeIncludeResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension SearchScrollerChangeKeywordsResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension SearchScrollerCursorResult {
    func get() throws(MailScrollerError) -> MailMessageCursor {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SearchScrollerFetchMoreResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension SearchScrollerForceRefreshResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension SearchScrollerGetItemsResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension SearchScrollerHasMoreResult {
    func get() throws(MailScrollerError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SearchScrollerRefreshResult {
    func get() throws(MailScrollerError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension SearchScrollerSupportsIncludeFilterResult {
    func get() throws(MailScrollerError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SearchScrollerTotalResult {
    func get() throws(MailScrollerError) -> UInt64 {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension UpdateNextMessageOnMoveResult {
    func get() throws(UserSessionError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension VoidAnswerRsvpResult {
    func get() throws(ProtonError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension VoidProtonResult {
    func get() throws(ProtonError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension VoidSessionResult {
    func get() throws(UserSessionError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension WatchMailSettingsResult {
    func get() throws(UserSessionError) -> SettingsWatcher {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
