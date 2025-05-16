// Generated using Sourcery 2.2.6 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Foundation
import proton_app_uniffi

public extension AttachmentListAddInlineResult {
    func get() throws(DraftAttachmentUploadError) -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AttachmentListAddResult {
    func get() throws(DraftAttachmentUploadError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension AttachmentListAttachmentsResult {
    func get() throws(DraftAttachmentUploadError) -> [DraftAttachment] {
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
public extension AttachmentListRemoveWithCidResult {
    func get() throws(DraftAttachmentUploadError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension AttachmentListRetryResult {
    func get() throws(DraftAttachmentUploadError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension AttachmentListWatcherResult {
    func get() throws(DraftAttachmentUploadError) -> DraftAttachmentWatcher {
        switch self {
        case .ok(let value):
            value
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
public extension ConversationScrollerAllItemsResult {
    func get() throws(UserSessionError) -> [Conversation] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationScrollerFetchMoreResult {
    func get() throws(UserSessionError) -> [Conversation] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension CreateMailIosExtensionSessionResult {
    func get() throws(UserSessionError) -> MailSession {
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
    func get() throws(ProtonError) -> DraftScheduleSendOption {
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
public extension EmbeddedAttachmentInfoResult {
    func get() throws(ProtonError) -> EmbeddedAttachmentInfo {
        switch self {
        case .ok(let value):
            value
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
public extension LoginFlowToUserContextResult {
    func get() throws(LoginError) -> MailUserSession {
        switch self {
        case .ok(let value):
            value
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
public extension MailSessionAllMessagesWereSentResult {
    func get() throws(UserSessionError) -> Bool {
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
public extension MailSessionGetUnsentMessagesIdsInQueueResult {
    func get() throws(UserSessionError) -> [Id] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionInitializedUserContextFromSessionResult {
    func get() throws(UserSessionError) -> MailUserSession? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionNewLoginFlowResult {
    func get() throws(LoginError) -> LoginFlow {
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
    func get() throws(LoginError) -> LoginFlow {
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
public extension MailSessionUserContextFromSessionResult {
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
public extension MessageScrollerAllItemsResult {
    func get() throws(UserSessionError) -> [Message] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MessageScrollerFetchMoreResult {
    func get() throws(UserSessionError) -> [Message] {
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
public extension NewDraftResult {
    func get() throws(DraftOpenError) -> Draft {
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
public extension OpenDraftResult {
    func get() throws(DraftOpenError) -> OpenDraft {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SearchScrollerAllItemsResult {
    func get() throws(UserSessionError) -> [Message] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SearchScrollerFetchMoreResult {
    func get() throws(UserSessionError) -> [Message] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension VoidDraftDiscardResult {
    func get() throws(DraftDiscardError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension VoidDraftSaveResult {
    func get() throws(DraftSaveError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension VoidDraftSendResult {
    func get() throws(DraftSendError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension VoidLoginResult {
    func get() throws(LoginError) {
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
