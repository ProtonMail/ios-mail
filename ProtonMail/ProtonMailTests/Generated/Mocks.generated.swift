// Generated using Sourcery 1.9.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import CoreData
import ProtonCore_PaymentsUI
import ProtonCore_TestingToolkit

@testable import ProtonMail

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
    func updateContactDetail(serverResponse: [String: Any], completion: ((Contact?, NSError?) -> Void)?) {
        updateContactDetailStub(serverResponse, completion)
    }

    @FuncStub(MockCacheServiceProtocol.parseMessagesResponse) var parseMessagesResponseStub
    func parseMessagesResponse(labelID: LabelID, isUnread: Bool, response: [String: Any], idsOfMessagesBeingSent: [String], completion: @escaping (Error?) -> Void) {
        parseMessagesResponseStub(labelID, isUnread, response, idsOfMessagesBeingSent, completion)
    }

    @FuncStub(MockCacheServiceProtocol.updateCounterSync) var updateCounterSyncStub
    func updateCounterSync(markUnRead: Bool, on labelIDs: [LabelID]) {
        updateCounterSyncStub(markUnRead, labelIDs)
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

    @PropertyStub(\MockConversationCoordinatorProtocol.goToDraft, initialGet: nil) var goToDraftStub
    var goToDraft: ((MessageID, OriginalScheduleDate?) -> Void)? {
        get {
            goToDraftStub()
        }
        set {
            goToDraftStub(newValue)
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

class MockMarkLegitimateActionHandler: MarkLegitimateActionHandler {
    @FuncStub(MockMarkLegitimateActionHandler.markAsLegitimate) var markAsLegitimateStub
    func markAsLegitimate(messageId: MessageID) {
        markAsLegitimateStub(messageId)
    }

}

class MockMessageDataActionProtocol: MessageDataActionProtocol {
    @FuncStub(MockMessageDataActionProtocol.mark, initialReturn: Bool()) var markStub
    func mark(messageObjectIDs: [NSManagedObjectID], labelID: LabelID, unRead: Bool) -> Bool {
        markStub(messageObjectIDs, labelID, unRead)
    }

}

class MockPaymentsUIProtocol: PaymentsUIProtocol {
    @FuncStub(MockPaymentsUIProtocol.showCurrentPlan) var showCurrentPlanStub
    func showCurrentPlan(presentationType: PaymentsUIPresentationType, backendFetch: Bool, completionHandler: @escaping (PaymentsUIResultReason) -> Void) {
        showCurrentPlanStub(presentationType, backendFetch, completionHandler)
    }

}

class MockReceiptActionHandler: ReceiptActionHandler {
    @FuncStub(MockReceiptActionHandler.sendReceipt) var sendReceiptStub
    func sendReceipt(messageID: MessageID) {
        sendReceiptStub(messageID)
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

class MockViewModeUpdater: ViewModeUpdater {
    @FuncStub(MockViewModeUpdater.update) var updateStub
    func update(viewMode: ViewMode, completion: ((Swift.Result<ViewMode?, Error>) -> Void)?) {
        updateStub(viewMode, completion)
    }

}

