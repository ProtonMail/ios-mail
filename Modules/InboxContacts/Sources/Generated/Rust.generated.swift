// Generated using Sourcery 2.2.6 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// periphery:ignore:all
import Foundation
import proton_app_uniffi

public extension AllAvailableConversationActionsForActionSheetResult {
    func get() throws(ActionError) -> ConversationActionSheet {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AllAvailableConversationActionsForConversationResult {
    func get() throws(ActionError) -> AllConversationActions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AllAvailableListActionsForConversationsResult {
    func get() throws(ActionError) -> AllListActions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AllAvailableListActionsForMessagesResult {
    func get() throws(ActionError) -> AllListActions {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AllAvailableMessageActionsForActionSheetResult {
    func get() throws(ActionError) -> MessageActionSheet {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AllAvailableMessageActionsForMessageResult {
    func get() throws(ActionError) -> AllMessageActions {
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
public extension ContactGroupByIdResult {
    func get() throws(ActionError) -> ContactGroupItem {
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
    func get() throws(ActionError) -> LabelAsOutput {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension LabelMessagesAsResult {
    func get() throws(ActionError) -> LabelAsOutput {
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
public extension MobileActionsResult {
    func get() throws(ActionError) -> [MobileAction] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MoveConversationsResult {
    func get() throws(ActionError) -> Undo? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MoveMessagesResult {
    func get() throws(ActionError) -> Undo? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowChangeMboxPassResult {
    func get() throws(PasswordError) -> SimplePasswordState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowChangePassResult {
    func get() throws(PasswordError) -> SimplePasswordState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowFidoDetailsResult {
    func get() throws(PasswordError) -> Fido2ResponseFfi? {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowHasFidoResult {
    func get() throws(PasswordError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowHasMbpResult {
    func get() throws(PasswordError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowHasTotpResult {
    func get() throws(PasswordError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowStepBackResult {
    func get() throws(PasswordError) -> SimplePasswordState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowSubmitFidoResult {
    func get() throws(PasswordError) -> SimplePasswordState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowSubmitPassResult {
    func get() throws(PasswordError) -> SimplePasswordState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowSubmitTotpResult {
    func get() throws(PasswordError) -> SimplePasswordState {
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
public extension SignupFlowAvailableCountriesResult {
    func get() throws(SignupError) -> Countries {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowAvailableDomainsResult {
    func get() throws(SignupError) -> [String] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowCompleteResult {
    func get() throws(SignupError) -> UserAddrId {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowCreateResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowSkipRecoveryResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowStepBackResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowSubmitExternalUsernameResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowSubmitInternalUsernameResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowSubmitPasswordResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowSubmitRecoveryEmailResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowSubmitRecoveryPhoneResult {
    func get() throws(SignupError) -> SimpleSignupState {
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
public extension UndoUndoResult {
    func get() throws(ActionError) {
        switch self {
        case .ok:
            break
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
