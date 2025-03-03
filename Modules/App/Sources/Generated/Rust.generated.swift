// Generated using Sourcery 2.2.6 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Foundation
import proton_app_uniffi

public extension AllAvailableBottomBarActionsForConversationsResult {
    func get() throws -> AllBottomBarMessageActions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AllAvailableBottomBarActionsForMessagesResult {
    func get() throws -> AllBottomBarMessageActions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AssignedSwipeActionsResult {
    func get() throws -> AssignedSwipeActions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AvailableActionsForConversationsResult {
    func get() throws -> ConversationAvailableActions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AvailableActionsForMessagesResult {
    func get() throws -> MessageAvailableActions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AvailableLabelAsActionsForConversationsResult {
    func get() throws -> [LabelAsAction] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AvailableLabelAsActionsForMessagesResult {
    func get() throws -> [LabelAsAction] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AvailableMoveToActionsForConversationsResult {
    func get() throws -> [MoveAction] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AvailableMoveToActionsForMessagesResult {
    func get() throws -> [MoveAction] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ContactListResult {
    func get() throws -> [GroupedContacts] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ContactSuggestionsResult {
    func get() throws -> ContactSuggestions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationPaginatorNextPageResult {
    func get() throws -> [Conversation] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationPaginatorReloadResult {
    func get() throws -> [Conversation] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationResult {
    func get() throws -> ConversationAndMessages? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationScrollerAllItemsResult {
    func get() throws -> [Conversation] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationScrollerFetchMoreResult {
    func get() throws -> [Conversation] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ConversationsForLabelResult {
    func get() throws -> [Conversation] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension CreateMailSessionResult {
    func get() throws -> MailSession {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension DecryptPushNotificationResult {
    func get() throws -> DecryptedPushNotification {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension DraftMessageIdResult {
    func get() throws -> Id? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension DraftSendResultUnseenResult {
    func get() throws -> [DraftSendResult] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension EmbeddedAttachmentInfoResult {
    func get() throws -> EmbeddedAttachmentInfo {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension GetMessageBodyResult {
    func get() throws -> DecryptedMessage {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension GetRegisteredDeviceResult {
    func get() throws -> RegisteredDevice? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension LabelConversationsAsResult {
    func get() throws -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension LabelMessagesAsResult {
    func get() throws -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension LoadConversationResult {
    func get() throws -> Conversation? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension LoginFlowSessionIdResult {
    func get() throws -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension LoginFlowToUserContextResult {
    func get() throws -> MailUserSession {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension LoginFlowUserIdResult {
    func get() throws -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionAllMessagesWereSentResult {
    func get() throws -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetAccountResult {
    func get() throws -> StoredAccount? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetAccountSessionsResult {
    func get() throws -> [StoredSession] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetAccountStateResult {
    func get() throws -> StoredAccountState? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetAccountsResult {
    func get() throws -> [StoredAccount] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetPrimaryAccountResult {
    func get() throws -> StoredAccount? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetSessionResult {
    func get() throws -> StoredSession? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetSessionStateResult {
    func get() throws -> StoredSessionState? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionGetSessionsResult {
    func get() throws -> [StoredSession] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionNewLoginFlowResult {
    func get() throws -> LoginFlow {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionResumeLoginFlowResult {
    func get() throws -> LoginFlow {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionStartBackgroundExecutionResult {
    func get() throws -> BackgroundExecutionHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionUserContextFromSessionResult {
    func get() throws -> MailUserSession {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchAccountSessionsResult {
    func get() throws -> WatchedSessions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchAccountsAsyncResult {
    func get() throws -> WatchedAccounts {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchAccountsResult {
    func get() throws -> WatchedAccounts {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchSessionsAsyncResult {
    func get() throws -> WatchedSessions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionWatchSessionsResult {
    func get() throws -> WatchedSessions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSettingsResult {
    func get() throws -> MailSettings {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionAccountDetailsResult {
    func get() throws -> AccountDetails {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionApplicableLabelsResult {
    func get() throws -> [SidebarCustomLabel] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionConnectionStatusResult {
    func get() throws -> ConnectionStatus {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionForkResult {
    func get() throws -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionGetAttachmentResult {
    func get() throws -> DecryptedAttachment {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionImageForSenderResult {
    func get() throws -> String? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionMovableFoldersResult {
    func get() throws -> [SidebarCustomFolder] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionObserveEventLoopErrorsResult {
    func get() throws -> EventLoopErrorObserverHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionSessionIdResult {
    func get() throws -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionUserIdResult {
    func get() throws -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionUserResult {
    func get() throws -> User {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailboxGetAttachmentResult {
    func get() throws -> DecryptedAttachment {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailboxUnreadCountResult {
    func get() throws -> UInt64 {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailboxWatchUnreadCountResult {
    func get() throws -> WatchHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MessagePaginatorNextPageResult {
    func get() throws -> [Message] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MessagePaginatorReloadResult {
    func get() throws -> [Message] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MessageResult {
    func get() throws -> Message? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MessageScrollerAllItemsResult {
    func get() throws -> [Message] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MessageScrollerFetchMoreResult {
    func get() throws -> [Message] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MessagesForConversationResult {
    func get() throws -> [Message] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MessagesForLabelResult {
    func get() throws -> [Message] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension NewAllMailMailboxResult {
    func get() throws -> Mailbox {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension NewDraftSendWatcherResult {
    func get() throws -> DraftSendResultWatcher {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension NewInboxMailboxResult {
    func get() throws -> Mailbox {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension NewMailboxResult {
    func get() throws -> Mailbox {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PaginateConversationsForLabelResult {
    func get() throws -> ConversationPaginator {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PaginateMessagesForLabelResult {
    func get() throws -> MessagePaginator {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PaginateSearchResult {
    func get() throws -> MessagePaginator {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ResolveMessageIdResult {
    func get() throws -> Id {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ScrollConversationsForLabelResult {
    func get() throws -> ConversationScroller {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ScrollMessagesForLabelResult {
    func get() throws -> MessageScroller {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension ScrollerSearchResult {
    func get() throws -> SearchScroller {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SearchForConversationsResult {
    func get() throws -> [Conversation] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SearchForMessagesResult {
    func get() throws -> [Message] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SearchScrollerAllItemsResult {
    func get() throws -> [Message] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SearchScrollerFetchMoreResult {
    func get() throws -> [Message] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SidebarAllCustomFoldersResult {
    func get() throws -> [SidebarCustomFolder] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SidebarCustomFoldersResult {
    func get() throws -> [SidebarCustomFolder] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SidebarCustomLabelsResult {
    func get() throws -> [SidebarCustomLabel] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SidebarSystemLabelsResult {
    func get() throws -> [SidebarSystemLabel] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SidebarWatchLabelsResult {
    func get() throws -> WatchHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension VoidActionResult {
    func get() throws {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension VoidDraftUndoSendResult {
    func get() throws {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension VoidEventResult {
    func get() throws {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension VoidLoginResult {
    func get() throws {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension VoidProtonResult {
    func get() throws {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension VoidSessionResult {
    func get() throws {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension WatchAvailableLabelAsActionsForConversationsResult {
    func get() throws -> WatchedLabelAs {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchAvailableLabelAsActionsForMessagesResult {
    func get() throws -> WatchedLabelAs {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchAvailableMoveToActionsResult {
    func get() throws -> WatchHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchContactListResult {
    func get() throws -> WatchedContactList {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchConversationResult {
    func get() throws -> WatchedConversation? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchConversationsForLabelResult {
    func get() throws -> WatchedConversations {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchMailSettingsResult {
    func get() throws -> SettingsWatcher {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchMessageResult {
    func get() throws -> WatchedMessage? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension WatchMessagesForLabelResult {
    func get() throws -> WatchedMessages {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
