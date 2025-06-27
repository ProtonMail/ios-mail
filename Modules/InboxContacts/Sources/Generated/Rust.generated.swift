// Generated using Sourcery 2.2.6 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// periphery:ignore:all
import Foundation
import proton_app_uniffi

public extension AllAvailableBottomBarActionsForConversationsResult {
    func get() throws(ActionError) -> AllBottomBarMessageActions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AllAvailableBottomBarActionsForMessagesResult {
    func get() throws(ActionError) -> AllBottomBarMessageActions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AssignedSwipeActionsResult {
    func get() throws(ActionError) -> AssignedSwipeActions {
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
public extension AvailableActionsForConversationsResult {
    func get() throws(ActionError) -> ConversationAvailableActions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AvailableActionsForMessageResult {
    func get() throws(ActionError) -> MessageAvailableActions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AvailableLabelAsActionsForConversationsResult {
    func get() throws(ActionError) -> [LabelAsAction] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AvailableLabelAsActionsForMessagesResult {
    func get() throws(ActionError) -> [LabelAsAction] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AvailableMoveToActionsForConversationsResult {
    func get() throws(ActionError) -> [MoveAction] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AvailableMoveToActionsForMessagesResult {
    func get() throws(ActionError) -> [MoveAction] {
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
public extension ContactListResult {
    func get() throws(ActionError) -> [GroupedContacts] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ContactSuggestionsResult {
    func get() throws(ActionError) -> ContactSuggestions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationResult {
    func get() throws(ActionError) -> ConversationAndMessages? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationsForLabelResult {
    func get() throws(ActionError) -> [Conversation] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension CreateMailIosExtensionSessionResult {
    func get() throws(UserContextError) -> MailSession {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension CreateMailSessionResult {
    func get() throws(UserContextError) -> MailSession {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension DecryptPushNotificationResult {
    func get() throws(ActionError) -> DecryptedPushNotification {
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
public extension GetAutoDeleteBannerResult {
    func get() throws(ActionError) -> AutoDeleteBanner? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension GetContactDetailsResult {
    func get() throws(UserContextError) -> ContactDetailCard {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension GetMessageBodyResult {
    func get() throws(ActionError) -> DecryptedMessage {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension LabelConversationsAsResult {
    func get() throws(ActionError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension LabelMessagesAsResult {
    func get() throws(ActionError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension LoadConversationResult {
    func get() throws(ActionError) -> Conversation? {
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
public extension LoginFlowPasswordChangeRequiredResult {
    func get() throws(LoginError) -> Bool {
        switch self {
        case .ok(let value):
            value
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
public extension MailSessionAllMessagesWereSentResult {
    func get() throws(UserContextError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionAppProtectionResult {
    func get() throws(UserContextError) -> AppProtection {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionChangeAppSettingsResult {
    func get() throws(UserContextError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetAccountResult {
    func get() throws(UserContextError) -> StoredAccount? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetAccountSessionsResult {
    func get() throws(UserContextError) -> [StoredSession] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetAccountStateResult {
    func get() throws(UserContextError) -> StoredAccountState? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetAccountsResult {
    func get() throws(UserContextError) -> [StoredAccount] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetAppSettingsResult {
    func get() throws(UserContextError) -> AppSettings {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetPrimaryAccountResult {
    func get() throws(UserContextError) -> StoredAccount? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetSessionResult {
    func get() throws(UserContextError) -> StoredSession? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetSessionStateResult {
    func get() throws(UserContextError) -> StoredSessionState? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetSessionsResult {
    func get() throws(UserContextError) -> [StoredSession] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetUnsentMessagesIdsInQueueResult {
    func get() throws(UserContextError) -> [Id] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionInitializedUserContextFromSessionResult {
    func get() throws(UserContextError) -> MailUserSession? {
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
public extension MailSessionRegisterDeviceTaskResult {
    func get() throws(ActionError) -> RegisterDeviceTaskHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionRemainingPinAttemptsResult {
    func get() throws(UserContextError) -> UInt32? {
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
    func get() throws(UserContextError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionShouldAutoLockResult {
    func get() throws(UserContextError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionSignOutAllResult {
    func get() throws(UserContextError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionStartBackgroundExecutionResult {
    func get() throws(UserContextError) -> BackgroundExecutionHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionStartBackgroundExecutionWithDurationResult {
    func get() throws(UserContextError) -> BackgroundExecutionHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionToUserContextResult {
    func get() throws(ProtonError) -> MailUserSession {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionUnsetBiometricsAppProtectionResult {
    func get() throws(UserContextError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionUserContextFromSessionResult {
    func get() throws(UserContextError) -> MailUserSession {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchAccountSessionsResult {
    func get() throws(UserContextError) -> WatchedSessions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchAccountsAsyncResult {
    func get() throws(UserContextError) -> WatchedAccounts {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchAccountsResult {
    func get() throws(UserContextError) -> WatchedAccounts {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchSessionsAsyncResult {
    func get() throws(UserContextError) -> WatchedSessions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchSessionsResult {
    func get() throws(UserContextError) -> WatchedSessions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSettingsResult {
    func get() throws(UserContextError) -> MailSettings {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionAccountDetailsResult {
    func get() throws(UserContextError) -> AccountDetails {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionApplicableLabelsResult {
    func get() throws(UserContextError) -> [SidebarCustomLabel] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionConnectionStatusResult {
    func get() throws(UserContextError) -> ConnectionStatus {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionForkResult {
    func get() throws(UserContextError) -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionGetAttachmentResult {
    func get() throws(ActionError) -> DecryptedAttachment {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionGetPaymentsPlansResult {
    func get() throws(UserContextError) -> PaymentsPlans {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionGetPaymentsResourcesIconsResult {
    func get() throws(UserContextError) -> Data {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionGetPaymentsSubscriptionResult {
    func get() throws(UserContextError) -> Subscriptions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionImageForSenderResult {
    func get() throws(UserContextError) -> String? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionMovableFoldersResult {
    func get() throws(UserContextError) -> [SidebarCustomFolder] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionPostPaymentsSubscriptionResult {
    func get() throws(UserContextError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionPostPaymentsTokensResult {
    func get() throws(UserContextError) -> PaymentToken {
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
    func get() throws(UserContextError) -> String {
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
    func get() throws(UserContextError) -> User {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionUserSettingsResult {
    func get() throws(UserContextError) -> UserSettings {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailboxGetAttachmentResult {
    func get() throws(ActionError) -> DecryptedAttachment {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailboxUnreadCountResult {
    func get() throws(UserContextError) -> UInt64 {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailboxWatchUnreadCountResult {
    func get() throws(UserContextError) -> WatchHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MessageResult {
    func get() throws(ActionError) -> Message? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MessagesForConversationResult {
    func get() throws(ActionError) -> [Message] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MessagesForLabelResult {
    func get() throws(ActionError) -> [Message] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension NewAllMailMailboxResult {
    func get() throws(UserContextError) -> Mailbox {
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
    func get() throws(UserContextError) -> Mailbox {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension NewMailboxResult {
    func get() throws(UserContextError) -> Mailbox {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ResolveMessageIdResult {
    func get() throws(ActionError) -> Id {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ScrollConversationsForLabelResult {
    func get() throws(ActionError) -> ConversationScroller {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ScrollMessagesForLabelResult {
    func get() throws(ActionError) -> MessageScroller {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ScrollerSearchResult {
    func get() throws(ActionError) -> SearchScroller {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SearchForConversationsResult {
    func get() throws(ActionError) -> [Conversation] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SearchForMessagesResult {
    func get() throws(ActionError) -> [Message] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SidebarAllCustomFoldersResult {
    func get() throws(ActionError) -> [SidebarCustomFolder] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SidebarCustomFoldersResult {
    func get() throws(ActionError) -> [SidebarCustomFolder] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SidebarCustomLabelsResult {
    func get() throws(ActionError) -> [SidebarCustomLabel] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SidebarSystemLabelsResult {
    func get() throws(ActionError) -> [SidebarSystemLabel] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SidebarWatchLabelsResult {
    func get() throws(ActionError) -> WatchHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension TestStubMessageBodyResult {
    func get() throws(ActionError) -> DecryptedMessage {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension VoidActionResult {
    func get() throws(ActionError) {
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
    func get() throws(UserContextError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension WatchAvailableLabelAsActionsForConversationsResult {
    func get() throws(ActionError) -> WatchedLabelAs {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchAvailableLabelAsActionsForMessagesResult {
    func get() throws(ActionError) -> WatchedLabelAs {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchAvailableMoveToActionsResult {
    func get() throws(ActionError) -> WatchHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchContactListResult {
    func get() throws(ActionError) -> WatchedContactList {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchConversationResult {
    func get() throws(ActionError) -> WatchedConversation? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchConversationsForLabelResult {
    func get() throws(ActionError) -> WatchedConversations {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchMailSettingsResult {
    func get() throws(UserContextError) -> SettingsWatcher {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchMessageResult {
    func get() throws(ActionError) -> WatchedMessage? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchMessagesForLabelResult {
    func get() throws(ActionError) -> WatchedMessages {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
