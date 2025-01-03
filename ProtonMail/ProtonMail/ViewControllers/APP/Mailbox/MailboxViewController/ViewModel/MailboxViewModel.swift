//
//  MailboxViewModel.swift
//  Proton Mail - Created on 8/15/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Combine
import CoreData
import LifetimeTracker
import ProtonCoreDataModel
import ProtonCoreFeatureFlags
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCorePayments
import ProtonCoreServices
import ProtonCoreUIFoundations
import ProtonCoreUtilities
import ProtonMailAnalytics
import ProtonMailUI
import UIKit

struct LabelInfo {
    let name: String

    init(name: String) {
        self.name = name
    }
}

protocol MailboxViewModelUIProtocol: AnyObject {
    var isUsingDefaultSizeCategory: Bool { get }

    func updateTitle()
    func updateUnreadButton(count: Int)
    func selectionDidChange()
    func clickSnoozeActionButton()
}

class MailboxViewModel: NSObject, StorageLimit, UpdateMailboxSourceProtocol, AttachmentPreviewViewModelProtocol {
    typealias Dependencies = HasCheckProtonServerStatus
    & HasFeatureFlagCache
    & HasFeatureFlagProvider
    & HasFeatureFlagsDownloadService
    & HasFetchAttachmentUseCase
    & HasFetchAttachmentMetadataUseCase
    & HasFetchMessageDetailUseCase
    & HasFetchMessages
    & HasFetchSenderImage
    & HasMailEventsPeriodicScheduler
    & HasPushNotificationService
    & HasUpsellOfferProvider
    & HasUpdateMailbox
    & HasUpsellButtonStateProvider
    & HasUserDefaults
    & HasUserIntroductionProgressProvider
    & HasUserNotificationCenterProtocol
    & HasUsersManager
    & HasQueueManager
    & HasAutoImportContactsFeature
    & HasImportDeviceContacts
    & HasUserCachedStatus
    & HasPlanService

    let labelID: LabelID
    var storageAlertVisibility: StorageAlertVisibility = .hidden
    var lockedStateAlertVisibility: LockedStateAlertVisibility = .hidden
    /// This field saves the label object of custom folder/label
    private(set) var label: LabelInfo?
    var messageLocation: Message.Location? {
        return Message.Location(rawValue: labelID.rawValue)
    }
    /// message service
    internal let user: UserManager
    internal let messageService: MessageDataService
    internal let eventsService: EventsFetching
    /// fetch controller
    private(set) var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    private var labelPublisher: MailboxLabelPublisher?
    private var unreadCounterPublisher: UnreadCounterPublisher?
    var unreadCount: Int {
        unreadCounterPublisher?.unreadCount ?? 0
    }

    private var mailboxLastUpdateTime: Date? {
        let key = UserSpecificLabelKey(labelID: labelID, userID: user.userID)
        return dependencies.userDefaults[.mailboxLastUpdateTimes][key.userDefaultsKey]
    }

    private(set) var selectedIDs: Set<String> = Set()

    var selectedLabelAsLabels: Set<LabelLocation> = Set()

    private let lastUpdatedStore: LastUpdatedStoreProtocol
    let coreDataContextProvider: CoreDataContextProviderProtocol
    private let conversationStateProvider: ConversationStateProviderProtocol
    private let contactGroupProvider: ContactGroupsProviderProtocol
    let labelProvider: LabelProviderProtocol
    private let contactProvider: ContactProviderProtocol
    let conversationProvider: ConversationProvider

    var viewModeIsChanged: (() -> Void)?
    var sendHapticFeedback:(() -> Void)?
    let totalUserCountClosure: () -> Int
    var isHavingUser: Bool {
        return totalUserCountClosure() > 0
    }
    var isFetchingMessage: Bool {
        dependencies.updateMailbox.isFetching
    }
    private(set) var isFirstFetch: Bool = true

    weak var uiDelegate: MailboxViewModelUIProtocol?

    private let dependencies: Dependencies

    /// `swipyCellDidSwipe` will be setting this value repeatedly during a swipe gesture.
    /// We only want to send a haptic signal one a state change.
    private var swipingTriggerActivated = false {
        didSet {
            if swipingTriggerActivated != oldValue {
                sendHapticFeedback?()
            }
        }
    }

    let toolbarActionProvider: ToolbarActionProvider
    let saveToolbarActionUseCase: SaveToolbarActionSettingsForUsersUseCase

    var listEditing: Bool = false {
        didSet {
            if !listEditing {
                selectedIDs.removeAll()
            }
        }
    }

    var reloadRightBarButtons: AnyPublisher<Void, Never> {
        let publishersThatAffectVisibleButtons: [AnyPublisher] = [
            upsellButtonVisibilityHasChanged
        ]

        return Publishers.MergeMany(publishersThatAffectVisibleButtons).eraseToAnyPublisher()
    }

    var isNewEventLoopEnabled: Bool {
        user.isNewEventLoopEnabled
    }

    private var prefetchedItemsCount: Atomic<Int> = .init(0)
    private var isPrefetching: Atomic<Bool> = .init(false)

    private(set) var diffableDataSource: MailboxDiffableDataSource?

    var isLoggingOut: Bool {
        dependencies.usersManager.loggingOutUserIDs.contains(user.userID)
    }

    private var storageExceedObservation: Cancellable?
    private var lockedStateObservation: Cancellable?

    private var plansDataSource: PlansDataSourceProtocol? {
        switch dependencies.planService {
        case .left:
            return nil
        case .right(let pdsp):
            return pdsp
        }
    }

    init(labelID: LabelID,
         label: LabelInfo?,
         userManager: UserManager,
         coreDataContextProvider: CoreDataContextProviderProtocol,
         lastUpdatedStore: LastUpdatedStoreProtocol,
         conversationStateProvider: ConversationStateProviderProtocol,
         contactGroupProvider: ContactGroupsProviderProtocol,
         labelProvider: LabelProviderProtocol,
         contactProvider: ContactProviderProtocol,
         conversationProvider: ConversationProvider,
         eventsService: EventsFetching,
         dependencies: Dependencies,
         toolbarActionProvider: ToolbarActionProvider,
         saveToolbarActionUseCase: SaveToolbarActionSettingsForUsersUseCase,
         totalUserCountClosure: @escaping () -> Int
    ) {
        self.labelID = labelID
        self.label = label
        self.user = userManager
        self.messageService = userManager.messageService
        self.eventsService = eventsService
        self.coreDataContextProvider = coreDataContextProvider
        self.lastUpdatedStore = lastUpdatedStore
        self.conversationStateProvider = conversationStateProvider
        self.contactGroupProvider = contactGroupProvider
        self.contactProvider = contactProvider
        self.totalUserCountClosure = totalUserCountClosure
        self.labelProvider = labelProvider
        self.conversationProvider = conversationProvider
        self.dependencies = dependencies
        self.toolbarActionProvider = toolbarActionProvider
        self.saveToolbarActionUseCase = saveToolbarActionUseCase

        super.init()
        trackLifetime()
        self.setupAlertBox()
        self.conversationStateProvider.add(delegate: self)
        dependencies.updateMailbox.setup(source: self)
    }

    func viewDidLoad() {
        if !hasPreloadedPlanToUpsell && shouldShowUpsellButton {
            Task { [unowned self] in
                do {
                    try await dependencies.upsellOfferProvider.update()
                } catch {
                    SystemLogger.log(error: error, category: .iap)
                }
            }
        }
    }

    /// localized navigation title. override it or return label name
    var localizedNavigationTitle: String {
        guard let location = Message.Location(labelID) else {
            return label?.name ?? ""
        }
        return location.localizedTitle
    }

    var isConversationModeEnabled: Bool {
        conversationStateProvider.viewMode == .conversation
    }

    var locationViewMode: ViewMode {
        let singleMessageOnlyLabels: [Message.Location] = [.draft, .sent, .scheduled]
        if let location = Message.Location(labelID), singleMessageOnlyLabels.contains(location) {
            return .singleMessage
        }
        return self.conversationStateProvider.viewMode
    }

    var isTrashOrSpam: Bool {
        let ids = [
            LabelLocation.trash.labelID,
            LabelLocation.spam.labelID
        ]
        return ids.contains(self.labelID)
    }

    var isCurrentUserSelectedUnreadFilterInInbox: Bool {
        get {
            return self.user.isUserSelectedUnreadFilterInInbox
        }
        set {
            self.user.isUserSelectedUnreadFilterInInbox = newValue
        }
    }

    var actionSheetViewModel: MailListActionSheetViewModel {
        return .init(
            labelId: labelId.rawValue,
            title: .actionSheetTitle(selectedCount: selectedIDs.count, viewMode: locationViewMode),
            locationViewMode: locationViewMode
        )
    }

    // Needs refactor to test

    var isInDraftFolder: Bool {
        return labelID.rawValue == Message.Location.draft.rawValue
    }

    var countOfFetchedObjects: Int {
        diffableDataSource?.snapshot().numberOfItems ?? 0
    }

    var selectedMessages: [MessageEntity] {
        let msgs = diffableDataSource?.snapshot().itemIdentifiers
            .compactMap { row in
                if case .real(let item) = row, case .message(let msg) = item {
                    return msg
                } else {
                    return nil
                }
            }.filter { selectedIDs.contains($0.messageID.rawValue) }
        return msgs ?? []
    }

    var selectedConversations: [ConversationEntity] {
        let conversations = diffableDataSource?.snapshot().itemIdentifiers
            .compactMap { row in
                if case .real(let item) = row, case .conversation(let conversation) = item {
                    return conversation
                } else {
                    return nil
                }
            }.filter { selectedIDs.contains($0.conversationID.rawValue) }
        return conversations ?? []
    }

    var selectedItems: [MailboxItem] {
        switch locationViewMode {
        case .conversation:
            return selectedConversations.map(MailboxItem.conversation)
        case .singleMessage:
            return selectedMessages.map(MailboxItem.message)
        }
    }

    var isAllLoadedMessagesSelected: Bool {
        selectedItems.count == rowCount(section: 0)
    }

    // Fetched by each cell in the view, use lazy to avoid fetching too much times
    lazy private(set) var customFolders: [LabelEntity] = {
        labelProvider.getCustomFolders()
    }()

    var allEmails: [EmailEntity] {
        return contactProvider.getAllEmails()
    }

    func setupAlertBox() {
        if let lockedFlags = user.userInfo.lockedFlags {
            lockedStateAlertVisibility = LockedStateAlertVisibility(lockedFlags: lockedFlags)
        } else {
            setupStorageAlert()
        }
    }

    private func setupStorageAlert() {
        let usersWhoHaveSeenStorageBanner = dependencies.userDefaults[.usersWhoHaveSeenStorageBanner]
        let userDismissedBanner = usersWhoHaveSeenStorageBanner[user.userID.rawValue] ?? false
        if FeatureFlagsRepository.shared.isEnabled(CoreFeatureFlagType.splitStorage, reloadValue: true),
           !userDismissedBanner,
           !user.userInfo.isOnAStoragePaidPlan {
            if mailStoragePercentage > StorageAlertVisibility.bannerThreshold {
                storageAlertVisibility = .mail(mailStoragePercentage)
            } else if driveStoragePercentage > StorageAlertVisibility.bannerThreshold {
                storageAlertVisibility = .drive(driveStoragePercentage)
            }
        } else {
            storageAlertVisibility = .hidden
        }
    }

    private var mailStoragePercentage: CGFloat {
        guard let usedBaseSpace = user.userInfo.usedBaseSpace,
              let maxBaseSpace = user.userInfo.maxBaseSpace,
              maxBaseSpace > 0 else {
            return 0
        }
        let factor = CGFloat(usedBaseSpace) / CGFloat(maxBaseSpace)
        return CGFloat.maximum(factor, 0.01)
    }

    private var driveStoragePercentage: CGFloat {
        guard let usedDriveSpace = user.userInfo.usedDriveSpace,
              let maxDriveSpace = user.userInfo.maxDriveSpace,
              maxDriveSpace > 0 else {
            return 0
        }
        let factor = CGFloat(usedDriveSpace) / CGFloat(maxDriveSpace)
        return CGFloat.maximum(factor, 0.01)
    }

    func onStorageAlertDismissed() {
        storageAlertVisibility = .hidden
        var usersWhoHaveSeenStorageBanner = dependencies.userDefaults[.usersWhoHaveSeenStorageBanner]
        usersWhoHaveSeenStorageBanner[user.userID.rawValue] = true
        dependencies.userDefaults[.usersWhoHaveSeenStorageBanner] = usersWhoHaveSeenStorageBanner
    }

    func setupDiffableDataSource(
        tableView: UITableView,
        cellConfigurator: @escaping (UITableView, IndexPath, MailboxRow) -> UITableViewCell
    ) {
        diffableDataSource = .init(tableView: tableView, cellProvider: cellConfigurator)
    }

    func contactGroups() -> [ContactGroupVO] {
        contactGroupProvider.getAllContactGroupVOs()
    }

    func fetchContacts() {
        contactProvider.fetchContacts(completion: nil)
    }

    func resetTourValue() {
        dependencies.userDefaults[.lastTourVersion] = Constants.App.TourVersion
    }

    func shouldShowAutoImportContactsSpotlight() -> Bool {
        user.container.autoImportContactsFeature.isFeatureEnabled && shouldShowSpotlight(for: .autoImportContacts)
    }

    func shouldShowDynamicFontSizeSpotlight() -> Bool {
        uiDelegate?.isUsingDefaultSizeCategory == false && shouldShowSpotlight(for: .dynamicFontSize)
    }

    func shouldShowSpotlight(for featureKey: SpotlightableFeatureKey) -> Bool {
        guard !ProcessInfo.isRunningUITests else { return false }

        if 
            let remoteFeatureFlag = featureKey.correspondingRemoteFeatureFlag,
            !dependencies.featureFlagProvider.isEnabled(remoteFeatureFlag)
        {
            return false
        }

        // If one of logged in user has seen spotlight, shouldn't show it again
        return dependencies.usersManager.users.allSatisfy {
            dependencies
                .userIntroductionProgressProvider
                .shouldShowSpotlight(for: featureKey, toUserWith: $0.userID)
        }
    }

    func hasSeenSpotlight(for featureKey: SpotlightableFeatureKey) {
        dependencies
            .userIntroductionProgressProvider
            .markSpotlight(for: featureKey, asSeen: true, byUserWith: user.userID)
    }

    func hasSeenAutoImportContactsSpotlight() {
        guard user.container.autoImportContactsFeature.isFeatureEnabled else { return }
        hasSeenSpotlight(for: .autoImportContacts)
    }

    func tagUIModels(for conversation: ConversationEntity) -> [TagUIModel] {
        let labelIDs = conversation.contextLabelRelations.map(\.labelID.rawValue)
        let request = NSFetchRequest<Label>(entityName: Label.Attributes.entityName)

        /// This regex means "contains more than just digits" and is used to differentiate:
        /// - system labelIDs which contains only digits
        /// - custom labelIDs which are UUIDs
        let isCustomLabelRegex = "(?!^\\d+$)^.+$"

        let predicates: [NSPredicate] = [
            NSPredicate(format: "%K IN %@", Label.Attributes.labelID, labelIDs),
            NSPredicate(format: "%K == %u", Label.Attributes.type, LabelEntity.LabelType.messageLabel.rawValue),
            NSPredicate(format: "%K == %@", Label.Attributes.userID, user.userID.rawValue),
            NSPredicate(format: "%K MATCHES %@", Label.Attributes.labelID, isCustomLabelRegex)
        ]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        request.sortDescriptors = [
            NSSortDescriptor(key: "order", ascending: true)
        ]

        var output: [TagUIModel] = []

        if let expirationTime = conversation.expirationTime {
            if conversation.isExpiring() {
                let title = expirationTime.countExpirationTime(processInfo: dependencies.userCachedStatus)
                let expirationDateTag = TagUIModel(
                    title: title,
                    titleColor: ColorProvider.InteractionStrong,
                    titleWeight: .regular,
                    icon: IconProvider.hourglass,
                    tagColor: ColorProvider.InteractionWeak
                )
                output.append(expirationDateTag)
            }
        }

        do {
            let orderedCustomLabels = try coreDataContextProvider.read { context in
                try context.fetch(request).map(LabelEntity.init(label:))
            }

            let tags = orderedCustomLabels.map { label in
                TagUIModel(
                    title: label.name,
                    titleColor: .white,
                    titleWeight: .semibold,
                    icon: nil,
                    tagColor: UIColor(hexString: label.color, alpha: 1.0)
                )
            }

            output.append(contentsOf: tags)
        } catch {
            PMAssertionFailure(error)
        }

        return output
    }

    /// create a fetch controller with labelID
    ///
    /// - Returns: fetched result controller
    private func makeFetchController(isUnread: Bool) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let isAscending = self.labelID == Message.Location.scheduled.labelID ? true : false
        let fetchedResultsController = messageService.fetchedResults(
            by: self.labelID,
            viewMode: self.locationViewMode,
            isUnread: isUnread,
            isAscending: isAscending
        )
        return fetchedResultsController
    }

    private func makeLabelPublisherIfNeeded() {
        guard Message.Location(labelID) == nil else {
            return
        }
        labelPublisher = MailboxLabelPublisher(contextProvider: coreDataContextProvider)
        labelPublisher?.startObserve(
            labelID: labelID,
            userID: user.userID,
            onContentChanged: { [weak self] labels in
                if let label = labels.first {
                    self?.label = .init(name: label.name)
                    self?.uiDelegate?.updateTitle()
                }
            }
        )
    }

    private func makeUnreadCounterPublisher() {
        unreadCounterPublisher = .init(
            contextProvider: coreDataContextProvider,
            userID: user.userID
        )
        unreadCounterPublisher?.startObserve(
            labelID: labelID,
            viewMode: locationViewMode,
            onContentChanged: { [weak self] unreadCount in
                self?.uiDelegate?.updateUnreadButton(count: unreadCount)
            }
        )
    }

    /// Setup fetch controller to fetch message of specific labelID
    ///
    /// - Parameter delegate: delegate from viewcontroller
    /// - Parameter isUnread: the flag used to filter the unread message or not
    func setupFetchController(_ delegate: NSFetchedResultsControllerDelegate?, isUnread: Bool = false) {
        fetchedResultsController = self.makeFetchController(isUnread: isUnread)
        fetchedResultsController?.delegate = delegate
        fetchedResultsController?.managedObjectContext.perform {
            do {
                try ObjC.catchException {
                    try? self.fetchedResultsController?.performFetch()
                }
            } catch {
                PMAssertionFailure(error)
            }
        }

        makeLabelPublisherIfNeeded()
        makeUnreadCounterPublisher()
    }

    /// reset delegate if fetch controller is valid
    func resetFetchedController() {
        if let controller = self.fetchedResultsController {
            controller.delegate = nil
            self.fetchedResultsController = nil
        }
    }

    // MARK: - table view usesage

    /// get section cound
    ///
    /// - Returns:
    func sectionCount() -> Int {
        return diffableDataSource?.snapshot().numberOfSections ?? 0
    }

    /// get row count of a section
    ///
    /// - Parameter section: section index
    /// - Returns: row count
    func rowCount(section: Int) -> Int {
        guard diffableDataSource?.snapshot().indexOfSection(section) != nil else { return 0 }
        return diffableDataSource?.snapshot().numberOfItems(inSection: section) ?? 0
    }

    /// get message item from a indexpath
    ///
    /// - Parameter index: table cell indexpath
    /// - Returns: message (nil)
    func item(index: IndexPath) -> MessageEntity? {
        if let item = diffableDataSource?.item(of: index),
           case .real(let mailboxItem) = item,
           case .message(let messageEntity) = mailboxItem {
            return messageEntity
        } else {
            return nil
        }
    }

    func itemOfConversation(index: IndexPath) -> ConversationEntity? {
        if let item = diffableDataSource?.item(of: index),
           case .real(let mailboxItem) = item,
           case .conversation(let conversationEntity) = mailboxItem {
            return conversationEntity
        } else {
            return nil
        }
    }

    func mailboxItem(at indexPath: IndexPath) -> MailboxItem? {
        if let message = item(index: indexPath) {
            return .message(message)
        } else if let conversation = itemOfConversation(index: indexPath) {
            return .conversation(conversation)
        } else {
            return nil
        }
    }

    // MARK: - operations

    /// check if need to load more older messages
    ///
    /// - Parameter index: the current table index
    /// - Returns: yes or no
    func loadMore(index: IndexPath) -> Bool {
        let snapshot = diffableDataSource?.snapshot()
        guard let number = snapshot?.numberOfSections else {
            return false
        }
        guard number > index.section else {
            return false
        }
        guard let total = snapshot?.numberOfItems(inSection: index.section) else {
            return false
        }
        if total - index.row <= 2 {
            return true
        }
        return false
    }

    /// the latest cache time of current location
    ///
    /// - Returns: location cache info
    func lastUpdateTime() -> LabelCountEntity? {
        // handle the message update in the draft location since the `FetchMessage` UseCase uses the following labelID to update the time info
        var id = labelID
        if id == LabelLocation.draft.labelID {
            id = LabelLocation.hiddenDraft.labelID
        } else if id == LabelLocation.sent.labelID {
            id = LabelLocation.hiddenSent.labelID
        }

        return lastUpdatedStore.lastUpdate(by: id, userID: user.userID, type: locationViewMode)
    }

    func getLastUpdateTimeText() -> String {
        var result = LocalString._mailblox_last_update_time_more_than_1_hour

        if let updateTime = mailboxLastUpdateTime {
            let time = updateTime.timeIntervalSinceReferenceDate
            let differenceFromNow = Int(Date().timeIntervalSinceReferenceDate - time)

            guard differenceFromNow >= 0 else {
                return ""
            }

            let hour = differenceFromNow / 3600
            let minute = differenceFromNow / 60

            if hour >= 1 {
                result = LocalString._mailblox_last_update_time_more_than_1_hour
            } else if minute < 60 && minute >= 1 {
                result = String.localizedStringWithFormat(LocalString._mailblox_last_update_time, minute)
            } else if minute < 1 && differenceFromNow < 60 {
                result = LocalString._mailblox_last_update_time_just_now
            }
        }
        return result
    }

    func getEmptyFolderCheckMessage(folder: LabelLocation) -> String {
        String(format: LocalString._clean_message_warning, folder.localizedTitle)
    }

    func emptyFolder() {
        let isTrashFolder = self.labelID == LabelLocation.trash.labelID
        let location: Message.Location = isTrashFolder ? .trash: .spam
        self.messageService.empty(location: location)
    }

    func fetchConversationDetail(conversationID: ConversationID, completion: @escaping () -> Void) {
        conversationProvider.fetchConversation(with: conversationID, includeBodyOf: nil, callOrigin: "MailboxViewModel") { result in
            assert(result.error == nil)

            DispatchQueue.main.async {
                completion()
            }
        }
    }

    final func resetNotificationMessage() {
        messageService.pushNotificationMessageID = nil
    }

    /// this is a workaground for draft. somehow back from the background the fetch controller can't get the latest data. remove this when fix this issue
    ///
    /// - Returns: bool
    func reloadTable() -> Bool {
        return labelID.rawValue == Message.Location.draft.rawValue
    }

    func deleteSelectedIDs() {
        switch locationViewMode {
        case .conversation:
            deletePermanently(conversationIDs: selectedConversations.map(\.conversationID))
        case .singleMessage:
            messageService.delete(messages: selectedMessages, label: self.labelID)
        }
    }

    private func deletePermanently(conversationIDs: [ConversationID]) {
        conversationProvider.deleteConversations(with: conversationIDs, labelID: self.labelID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.eventsService.fetchEvents(labelID: self.labelId)
            case .failure(let error):
                assertionFailure("\(error)")
            }
        }
    }

    func checkStorageIsCloseLimit() {
        guard !FeatureFlagsRepository.shared.isEnabled(CoreFeatureFlagType.splitStorage, reloadValue: true) else { return }
        let usedStorageSpace = user.userInfo.usedSpace
        let maxStorageSpace = user.userInfo.maxSpace
        checkSpace(usedStorageSpace,
                   maxSpace: maxStorageSpace,
                   userID: user.userInfo.userId)
    }

    func getTimeOfItem(at indexPath: IndexPath) -> Date? {
        mailboxItem(at: indexPath)?.time(labelID: labelID)
    }

    func getOnboardingDestination() -> MailboxCoordinator.Destination? {
        guard let tourVersion = dependencies.userDefaults[.lastTourVersion] else {
            return .onboardingForNew
        }
        if tourVersion == Constants.App.TourVersion {
            return nil
        } else {
            return .onboardingForUpdate
        }
    }

    func shouldRequestNotificationAuthorization(trigger: NotificationAuthorizationRequestTrigger) async -> Bool {
        let authorizationStatus = await dependencies.userNotificationCenter.authorizationStatus()

        guard authorizationStatus == .notDetermined else {
            // if status is determined, the system prompt cannot be shown anymore, so we shouldn't show the custom prompt either
            return false
        }

        let notificationAuthorizationRequestDates = dependencies.userDefaults[.notificationAuthorizationRequestDates]

        guard let mostRecentRequestDate = notificationAuthorizationRequestDates.last else {
            // if the user has never been prompted, prompt them now
            return true
        }

        switch trigger {
        case .onboardingFinished:
            // the onboarding prompt is never to be shown again
            return false
        case .messageSent:
            let hasAlreadyRetriedBefore = notificationAuthorizationRequestDates.count > 1

            if hasAlreadyRetriedBefore {
                return false
            } else {
                let nextRequestDate = nextNotificationAuthorizationRequestDate(since: mostRecentRequestDate)
                return nextRequestDate < .now
            }
        }
    }

    private func nextNotificationAuthorizationRequestDate(since mostRecentRequestDate: Date) -> Date {
        var retryInterval = DateComponents()

        if Application.isTestflightBeta {
            retryInterval.minute = 5
        } else {
            retryInterval.day = 20
        }

        return Calendar.autoupdatingCurrent.date(byAdding: retryInterval, to: mostRecentRequestDate)!
    }

    func userDidRespondToNotificationAuthorizationRequest(accepted: Bool) {
        dependencies.userDefaults[.notificationAuthorizationRequestDates].append(.now)

        if accepted {
            dependencies.pushService.authorizeIfNeededAndRegister()
        }
    }

    private func handleMoveToArchiveAction(on items: [MailboxItem]) {
        move(items: items, from: labelID, to: Message.Location.archive.labelID)
    }

    private func handleMoveToSpamAction(on items: [MailboxItem]) {
        move(items: items, from: labelID, to: Message.Location.spam.labelID)
    }

    private func handleUnstarAction(on items: [MailboxItem]) {
        let starredItemIDs = items
            .filter(\.isStarred)
            .map(\.itemID)

        label(IDs: Set<String>(starredItemIDs), with: Message.Location.starred.labelID, apply: false)
    }

    private func handleStarAction(on items: [MailboxItem]) {
        let unstarredItemIDs = items
            .filter { !$0.isStarred }
            .map(\.itemID)

        label(IDs: Set<String>(unstarredItemIDs), with: Message.Location.starred.labelID, apply: true)
    }

    private func handleMarkReadAction(on items: [MailboxItem]) {
        let unreadItemsIDs = items
            .filter { $0.isUnread(labelID: labelID) }
            .map(\.itemID)

        mark(IDs: Set(unreadItemsIDs), unread: false)
    }

    private func handleMarkUnreadAction(on items: [MailboxItem]) {
        let readItemsIDs = items
            .filter { !$0.isUnread(labelID: labelID) }
            .map(\.itemID)

        mark(IDs: Set(readItemsIDs), unread: true)
    }

    private func handleRemoveAction(on items: [MailboxItem]) {
        move(items: items, from: labelID, to: Message.Location.trash.labelID)
    }

    func searchForScheduled(swipeSelectedID: [String],
                            displayAlert: @escaping (Int) -> Void,
                            continueAction: @escaping () -> Void) {
        swipeSelectedID.forEach { selectedIDs.insert($0) }
        let selectedNum: Int
        switch locationViewMode {
        case .conversation:
            selectedNum = selectedConversations.filter { $0.contains(of: .scheduled) }.count
        case .singleMessage:
            selectedNum = selectedMessages.filter { $0.contains(location: .scheduled) }.count
        }
        if selectedNum == 0 {
            continueAction()
        } else {
            displayAlert(selectedNum)
        }
    }

    func fetchSenderImageIfNeeded(
        item: MailboxItem,
        isDarkMode: Bool,
        scale: CGFloat,
        completion: @escaping (UIImage?) -> Void
    ) {
        let senderImageRequestInfo: SenderImageRequestInfo?
        switch item {
        case .message(let messageEntity):
            senderImageRequestInfo = messageEntity.getSenderImageRequestInfo(isDarkMode: isDarkMode)
        case .conversation(let conversationEntity):
            senderImageRequestInfo = conversationEntity.getSenderImageRequestInfo(isDarkMode: isDarkMode)
        }

        guard let info = senderImageRequestInfo else {
            completion(nil)
            return
        }

        dependencies.fetchSenderImage
            .callbackOn(.main)
            .execute(
                params: .init(
                    senderImageRequestInfo: info,
                    scale: scale,
                    userID: user.userID
                )) { result in
                    switch result {
                    case .success(let image):
                        completion(image)
                    case .failure:
                        completion(nil)
                    }
            }
    }

    @MainActor
    func isProtonUnreachable(completion: @MainActor @escaping (Bool) -> Void) {
        guard
            dependencies.featureFlagCache.isFeatureFlag(.protonUnreachableBanner, enabledForUserWithID: user.userID)
        else {
            completion(false)
            return
        }
        Task { [weak self] in
            let status = await self?.dependencies.checkProtonServerStatus.execute()
            await MainActor.run {
                completion(status == .serverDown)
            }
        }
    }

    func deleteExpiredMessages() {
        DispatchQueue.global().async {
            self.user.cacheService.deleteExpiredMessages()
        }
    }

    func enableAutoImportContact() {
        dependencies.autoImportContactsFeature.enableSettingForUser()
        let params = ImportDeviceContacts.Params(
            userKeys: user.userInfo.userKeys,
            mailboxPassphrase: user.mailboxPassword
        )
        dependencies.importDeviceContacts.execute(params: params)
    }

    func setupStorageObservation(didChanged: @escaping (Bool) -> Void) {
        storageExceedObservation = user.$isStorageExceeded.sink(receiveValue: { value in
            didChanged(value)
        })
    }
    
    func setupLockedStateObservation(didChanged: @escaping (Bool) -> Void) {
        lockedStateObservation = user.$userLockedFlagsChanged.sink(receiveValue: { value in
            didChanged(value)
        })
    }
}

// MARK: - Data fetching methods
extension MailboxViewModel {

    func hasMessageEnqueuedTasks(_ messageID: MessageID) -> Bool {
        dependencies.queueManager.queuedMessageIds().contains(messageID.rawValue)
    }

    func fetchMessages(time: Int, isUnread: Bool, completion: @escaping (Error?) -> Void) {
        switch self.locationViewMode {
        case .singleMessage:
            dependencies.fetchMessages
                .callbackOn(.main)
                .execute(
                    params: .init(
                        labelID: labelID,
                        endTime: time,
                        isUnread: isUnread,
                        onMessagesRequestSuccess: nil
                    ),
                    callback: { result in
                        completion(result.error)
                    }
                )
        case .conversation:
            conversationProvider.fetchConversations(for: self.labelID, before: time, unreadOnly: isUnread, shouldReset: false) { result in
                switch result {
                case .success:
                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
            }
        }
    }

    func updateMailbox(
        showUnreadOnly: Bool,
        isCleanFetch: Bool,
        errorHandler: @escaping (Error) -> Void,
        completion: @escaping () -> Void
    ) {
        let isCurrentLocationEmpty = (fetchedResultsController?.sections?.first?.numberOfObjects ?? 0) == 0
        let fetchMessagesAtTheEnd = isCurrentLocationEmpty || isFirstFetch
        isFirstFetch = false
        var queryLabel = labelID
        switch user.mailSettings.showMoved {
        case .doNotKeep:
            break
        case .keepDraft:
            if queryLabel == LabelLocation.draft.labelID {
                queryLabel = LabelLocation.hiddenDraft.labelID
            }
        case .keepSent:
            if queryLabel == LabelLocation.sent.labelID {
                queryLabel = LabelLocation.hiddenSent.labelID
            }
        case .keepBoth:
            if queryLabel == LabelLocation.draft.labelID {
                queryLabel = LabelLocation.hiddenDraft.labelID
            } else if queryLabel == LabelLocation.sent.labelID {
                queryLabel = LabelLocation.hiddenSent.labelID
            }
        }

        dependencies.updateMailbox.execute(
            params: .init(
                labelID: queryLabel,
                showUnreadOnly: showUnreadOnly,
                isCleanFetch: isCleanFetch,
                fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                errorHandler: errorHandler,
                userID: user.userID
            )
        ) { _ in
            completion()
        }
    }

    func fetchMessageDetail(message: MessageEntity, callback: @escaping FetchMessageDetailUseCase.Callback) {
        let params: FetchMessageDetail.Params = .init(
            message: message,
            hasToBeQueued: false,
            ignoreDownloaded: message.isDraft
        )
        dependencies.fetchMessageDetail
            .callbackOn(.main)
            .execute(params: params, callback: callback)
    }

    func enableJumpToNextMessage(completion: @escaping () -> Void) {
        let request = UpdateNextMessageOnMoveRequest(isEnable: true)
        user.apiService.perform(
            request: request,
            response: VoidResponse()
        ) { [weak self] _, response in
            if response.error == nil {
                var statusProvider = self?.user.container.nextMessageAfterMoveStatusProvider
                statusProvider?.shouldMoveToNextMessageAfterMove = true
            }
            completion()
        }
    }
}

// MARK: Message Actions
extension MailboxViewModel {
    func containsStarMessages(messageIDs: Set<String>) -> Bool {
        switch self.locationViewMode {
        case .conversation:
            return coreDataContextProvider.read { context in
                let conversations = self.conversationProvider.fetchLocalConversations(withIDs: NSMutableSet(set: messageIDs), in: context)
                return conversations.contains { $0.contains(of: Message.Location.starred.labelID.rawValue) }
            }
        case .singleMessage:
            return coreDataContextProvider.read { context in
                let messages = self.messageService.fetchMessages(withIDs: NSMutableSet(set: messageIDs), in: context)
                return messages.contains { $0.contains(label: .starred) }
            }
        }
    }

    func selectionContainsReadItems() -> Bool {
        selectedItems.contains { !$0.isUnread(labelID: labelID) }
    }

    func label(IDs messageIDs: Set<String>,
               with labelID: LabelID,
               apply: Bool,
               completion: (() -> Void)? = nil) {
        switch self.locationViewMode {
        case .singleMessage:
            let messages = selectedMessages.filter { messageIDs.contains($0.messageID.rawValue) }
            messageService.label(messages: messages, label: labelID, apply: apply)
        case .conversation:
            if apply {
                conversationProvider.label(conversationIDs: Array(messageIDs.map{ ConversationID($0) }), as: labelID) { [weak self] result in
                    defer {
                        completion?()
                    }
                    guard let self = self else { return }
                    if let _ = try? result.get() {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
            } else {
                conversationProvider.unlabel(conversationIDs: Array(messageIDs.map{ ConversationID($0) }), as: labelID) { [weak self] result in
                    defer {
                        completion?()
                    }
                    guard let self = self else { return }
                    if let _ = try? result.get() {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
            }
        }
    }

    func mark(
        IDs messageIDs: Set<String>,
        unread: Bool,
        completion: (() -> Void)? = nil
    ) {
        switch self.locationViewMode {
        case .singleMessage:
            let filteredMessageIDs = selectedMessages.filter { messageIDs.contains($0.messageID.rawValue) && $0.unRead != unread
            }.map(\.objectID.rawValue)
            messageService.mark(
                messageObjectIDs: filteredMessageIDs,
                labelID: labelID,
                unRead: unread
            )
            completion?()
        case .conversation:
            let filteredConversationIDs = selectedConversations.filter {
                messageIDs.contains($0.conversationID.rawValue) && $0.isUnread(labelID: labelID) != unread
            }.map(\.conversationID)
            if unread {
                conversationProvider.markAsUnread(
                    conversationIDs: filteredConversationIDs,
                    labelID: labelID
                ) { _ in
                    completion?()
                }
            } else {
                conversationProvider.markAsRead(
                    conversationIDs: filteredConversationIDs,
                    labelID: labelId
                ) { _ in
                    completion?()
                }
            }
        }
    }

    func moveSelectedIDs(from fLabel: LabelID, to tLabel: LabelID, completion: (() -> Void)? = nil) {
        move(items: selectedItems, from: fLabel, to: tLabel, completion: completion)
    }

    func move(items: [MailboxItem], from fLabel: LabelID, to tLabel: LabelID, completion: (() -> Void)? = nil) {
        move(items: MailboxItemGroup(mailboxItems: items), from: fLabel, to: tLabel, completion: completion)
    }

    private func move(items: MailboxItemGroup, from fLabel: LabelID, to tLabel: LabelID, completion: (() -> Void)?) {
        switch items {
        case .messages(let messages):
            var fLabels: [LabelID] = []

            for msg in messages {
                // the label that is not draft, sent, starred, allmail
                fLabels.append(msg.getFirstValidFolder() ?? fLabel)
            }

            messageService.move(messages: messages, from: fLabels, to: tLabel)
            completion?()
        case .conversations(let conversations):
            conversationProvider.move(
                conversationIDs: conversations.map(\.conversationID),
                from: fLabel,
                to: tLabel,
                callOrigin: "MailboxViewModel - move"
            ) { [weak self] result in
                defer {
                    completion?()
                }
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.eventsService.fetchEvents(labelID: self.labelId)
                }
            }
        case .empty:
            completion?()
        }
    }
}

// Message Selection
extension MailboxViewModel {

    func canSelectMore() -> Bool {
        let maximum = dependencies.featureFlagCache.featureFlags(for: user.userID)[.mailboxSelectionLimitation]
        return selectedIDs.count < maximum
    }

    /// - Returns: Does id allow to be added?
    func select(id: String) -> Bool {
        let maximum = dependencies.featureFlagCache.featureFlags(for: user.userID)[.mailboxSelectionLimitation]
        guard selectedIDs.count < maximum else {
            uiDelegate?.selectionDidChange()
            return false
        }
        self.selectedIDs.insert(id)
        uiDelegate?.selectionDidChange()
        return true
    }

    func removeSelected(id: String) {
        self.selectedIDs.remove(id)
        uiDelegate?.selectionDidChange()
    }

    func removeAllSelectedIDs() {
        self.selectedIDs.removeAll()
        uiDelegate?.selectionDidChange()
    }

    func selectionContains(id: String) -> Bool {
        return self.selectedIDs.contains(id)
    }

    func removeDeletedIDFromSelectedItem(existingIDs: Set<String>) {
        let intersection = selectedIDs.intersection(existingIDs)
        selectedIDs = intersection
    }
}

// MARK: - Swipe actions
extension MailboxViewModel {
    func isSwipeActionValid(_ action: MessageSwipeAction, item: MailboxItem) -> Bool {
        guard let location = messageLocation else {
            return true
        }

        let helper = MailBoxSwipeActionHelper()

        let result: Bool
        if location == .allmail {
            switch item {
            case .message(let message):
                result = helper.checkIsSwipeActionValidOnMessage(
                    isDraft: message.isDraft,
                    isUnread: message.unRead,
                    isStar: message.contains(location: .starred),
                    isInTrash: message.contains(location: .trash),
                    isInArchive: message.contains(location: .archive),
                    isInSent: message.contains(location: .sent),
                    isInSpam: message.contains(location: .spam),
                    action: action
                )
            case .conversation(let conversation):
                result = helper.checkIsSwipeActionValidOnConversation(
                    isUnread: conversation.isUnread(labelID: labelID),
                    isStar: conversation.starred,
                    isInArchive: conversation.contains(of: Message.Location.archive.labelID),
                    isInSpam: conversation.contains(of: Message.Location.spam.labelID),
                    isInSent: conversation.contains(of: Message.Location.sent.labelID),
                    action: action
                )
            }
        } else {
            result = helper.checkIsSwipeActionValidOn(location: location, action: action)
        }
        return result
    }

    func convertSwipeActionTypeToMessageSwipeAction(_ type: SwipeActionSettingType,
                                                    isStarred: Bool,
                                                    isUnread: Bool) -> MessageSwipeAction {
        switch type {
        case .none:
            return .none
        case .trash:
            return .trash
        case .spam:
            return .spam
        case .starAndUnstar:
            return isStarred ? .unstar : .star
        case .archive:
            return .archive
        case .readAndUnread:
            return isUnread ? .read : .unread
        case .labelAs:
            return .labelAs
        case .moveTo:
            return .moveTo
        }
    }

    func handleSwipeAction(_ action: MessageSwipeAction, on item: MailboxItem) {
        switch action {
        case .unstar:
            handleUnstarAction(on: [item])
        case .star:
            handleStarAction(on: [item])
        case .read:
            handleMarkReadAction(on: [item])
        case .unread:
            handleMarkUnreadAction(on: [item])
        case .trash:
            handleRemoveAction(on: [item])
        case .archive:
            handleMoveToArchiveAction(on: [item])
        case .spam:
            handleMoveToSpamAction(on: [item])
        case .labelAs, .moveTo, .none:
            break
        }
    }

    func swipyCellDidSwipe(triggerActivated: Bool) {
        /*
         This method is called continuously during a swipe.
         If the trigger has been activated, the `triggerActivated` value is `true` on every  subsequent call, so it's
         impossible to intercept the exact moment of activation without storing this value to a property and checking
         against `oldValue`.
         */
        swipingTriggerActivated = triggerActivated
    }
}

extension MailboxViewModel: ConversationStateServiceDelegate {
    func viewModeHasChanged(viewMode: ViewMode) {
        viewModeIsChanged?()
    }
}

// MARK: - Auto-Delete Spam & Trash Banners

extension MailboxViewModel {
    enum InfoBannerType {
        case spam
        case trash
    }

    enum BannerToDisplay {
        case upsellBanner
        case promptBanner
        case infoBanner(InfoBannerType)
    }

    var headerBanner: BannerToDisplay? {
        let infoBannerType: InfoBannerType
        if self.labelID == LabelLocation.spam.labelID {
            infoBannerType = .spam
        } else if self.labelID == LabelLocation.trash.labelID {
            infoBannerType = .trash
        } else {
            return nil
        }

        if !user.hasPaidMailPlan {
            return .upsellBanner
        } else if user.isAutoDeleteImplicitlyDisabled {
            return .promptBanner
        } else if user.isAutoDeleteEnabled {
            return .infoBanner(infoBannerType)
        } else {
            return nil
        }
    }

    func updateAutoDeleteSetting(to newStatus: Bool, for user: UserManager, completion: @escaping ((Error?) -> Void)) {
        let request = UpdateAutoDeleteSpamAndTrashDaysRequest(shouldEnable: newStatus)
        user.apiService.perform(
            request: request,
            response: VoidResponse()
        ) { _, response in
            DispatchQueue.main.async {
                if let error = response.error {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }
    }

    func alertToConfirmEnabling(completion: @escaping ((Error?) -> Void)) -> UIAlertController {
        let alert = L10n.AutoDeleteSettings.enableAlertMessage.alertController()
        alert.title = L10n.AutoDeleteSettings.enableAlertTitle
        let cancelTitle = LocalString._general_cancel_button
        let confirm = UIAlertAction(title: L10n.AutoDeleteSettings.enableAlertButton, style: .default) { [weak self] _ in
            guard let self else { return }
            self.updateAutoDeleteSetting(to: true, for: self.user, completion: { error in
                completion(error)
            })
        }
        let cancel = UIAlertAction(title: cancelTitle, style: .cancel) { _ in }
        [confirm, cancel].forEach(alert.addAction)
        return alert
    }
}

// MARK: - Prefetch
extension MailboxViewModel {
    func itemsToPrefetch() -> [MailboxItem] {
        switch self.locationViewMode {
        case .conversation:
            let allConversations: [ConversationEntity] = diffableDataSource?.snapshot()
                .itemIdentifiers
                .compactMap { row in
                    if case .real(let item) = row,
                       case .conversation(let conversation) = item {
                        return conversation
                    } else {
                        return nil
                    }
                } ?? []
            let unreadConversations = allConversations.filter { $0.isUnread(labelID: labelID) == true }
            let readConversations = allConversations.filter { $0.isUnread(labelID: labelID) == false }
            let orderedConversations = unreadConversations.appending(readConversations)
            return orderedConversations.map { MailboxItem.conversation($0) }
        case .singleMessage:
            let allMessages: [MessageEntity] = diffableDataSource?.snapshot()
                .itemIdentifiers
                .compactMap { row in
                    if case .real(let item) = row,
                       case .message(let message) = item {
                        return message
                    } else {
                        return nil
                    }
                } ?? []
            let unreadMessages = allMessages.filter { $0.unRead == true }
            let readMessages = allMessages.filter { $0.unRead == false }
            let orderedMessages = unreadMessages.appending(readMessages)
            return orderedMessages.map { MailboxItem.message($0) }
        }
    }

    func prefetchIfNeeded() {
        guard isPrefetching.value == false else {
            return
        }

        let prefetchSize = dependencies.userCachedStatus.featureFlags(for: user.userID)[.mailboxPrefetchSize]
        let itemsToPrefetch = itemsToPrefetch().prefix(prefetchSize)

        guard itemsToPrefetch.count > 0, prefetchedItemsCount.value < prefetchSize else {
            return
        }

        isPrefetching.mutate { $0 = true }

        for item in itemsToPrefetch {
            switch item {
            case .message(let messageEntity):
                if messageEntity.body.isEmpty || !messageEntity.isDetailDownloaded {
                    self.fetchMessageDetail(message: messageEntity) { [weak self] _ in
                        self?.prefetchedItemsCount.mutate { $0 += 1 }
                        if itemsToPrefetch.last == item {
                            self?.isPrefetching.mutate { $0 = false }
                        }
                    }
                }
            case .conversation(let conversationEntity):
                self.fetchConversationDetail(conversationID: conversationEntity.conversationID) { [weak self] in
                    self?.prefetchedItemsCount.mutate { $0 += 1 }
                    if itemsToPrefetch.last == item {
                        self?.isPrefetching.mutate { $0 = false }
                    }
                }
            }
        }
    }
}

// MARK: - Attachment Preview
extension MailboxViewModel {
    func previewableAttachments(for mailboxItem: MailboxItem) -> [AttachmentsMetadata] {
        let isSpam = switch mailboxItem {
            case .message(let message):
                message.isSpam
            case .conversation(let conversation):
                conversation.contextLabelRelations.contains(where: { $0.labelID == Message.Location.spam.labelID })
        }
        guard dependencies.featureFlagCache.isFeatureFlag(.attachmentsPreview, enabledForUserWithID: user.userID),
              !isSpam else {
            return []
        }
        return mailboxItem.previewableAttachments
    }

    func requestPreviewOfAttachment(
        at indexPath: IndexPath,
        index: Int
    ) async throws -> SecureTemporaryFile {
        guard let mailboxItem = mailboxItem(at: indexPath),
              let attachmentMetadata = mailboxItem.attachmentsMetadata[safe: index] else {
            PMAssertionFailure("IndexPath should match MailboxItem")
            throw AttachmentPreviewError.indexPathDidNotMatch
        }

        let userKeys = user.toUserKeys()

        let metadata = try await dependencies.fetchAttachmentMetadata.execution(
            params: .init(attachmentID: .init(attachmentMetadata.id))
        )
        let attachmentFile = try await dependencies.fetchAttachment.execute(
            params: .init(
                attachmentID: .init(attachmentMetadata.id),
                attachmentKeyPacket: metadata.keyPacket,
                userKeys: userKeys
            )
        )
        let fileData = attachmentFile.data
        let fileName = attachmentMetadata.name.cleaningFilename()
        let secureTempFile = SecureTemporaryFile(data: fileData, name: fileName)
        return secureTempFile
    }

    func fetchEventsWithNewEventLoop() {
        dependencies.mailEventsPeriodicScheduler.triggerSpecialLoop(forSpecialLoopID: user.userID.rawValue)
    }

    func stopNewEventLoop() {
        dependencies.mailEventsPeriodicScheduler.disableSpecialLoop(withSpecialLoopID: user.userID.rawValue)
    }

    func startNewEventLoop() {
        dependencies.mailEventsPeriodicScheduler.enableSpecialLoop(forSpecialLoopID: user.userID.rawValue)
    }
}

// MARK: - Upsell

extension MailboxViewModel {
    var isUpsellButtonVisible: Bool {
        shouldShowUpsellButton && hasPreloadedPlanToUpsell
    }

    private var shouldShowUpsellButton: Bool {
        dependencies.upsellButtonStateProvider.shouldShowUpsellButton
    }

    private var upsellButtonVisibilityHasChanged: AnyPublisher<Void, Never> {
        dependencies
            .upsellOfferProvider
            .availablePlanPublisher
            .map { [unowned self] plan in
                /**
                 We can't use `isUpsellButtonVisible` here: $availablePlan publishes on willSet,
                 which means `hasPreloadedPlanToUpsell` is based on an outdated value.
                 */
                plan != nil && shouldShowUpsellButton
            }
            .removeDuplicates()
            .map { _ in }
            .eraseToAnyPublisher()
    }

    private var hasPreloadedPlanToUpsell: Bool {
        dependencies.upsellOfferProvider.availablePlan != nil
    }

    func upsellButtonWasTapped() {
        dependencies.upsellButtonStateProvider.upsellButtonWasTapped()
    }
}

extension MailboxViewModel: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}

extension MailboxViewModel {
    @MainActor
    func fetchUserPlan(completion: @MainActor @escaping (_ subscription: CurrentPlan.Subscription) -> Void) {
        Task { [weak self] in
            guard let self = self, let plansDataSource = self.plansDataSource else { return }
            try await plansDataSource.fetchCurrentPlan()
            if let subscription = plansDataSource.currentPlan?.subscriptions.first {
                completion(subscription)
            }
        }
    }
}

// MARK: Cancellation Reminder Modal Related

extension MailboxViewModel {
    func shouldShowReminderModal() -> Bool {
        guard let autoDowngradeReminderFF = dependencies.featureFlagCache.featureFlags(for: user.userID)[.autoDowngradeReminder] as? [String: Int] else { return false }
        return autoDowngradeReminderFF.values.contains(1)
    }
    
    func markRemindersAsSeen() {
        guard var autoDowngradeReminderFF = dependencies.featureFlagCache.featureFlags(for: user.userID)[.autoDowngradeReminder] as? [String: Int] else { return }
        autoDowngradeReminderFF.forEach { (key, val) in
            autoDowngradeReminderFF[key] = val == 1 ? 2 : val
        }
        dependencies.featureFlagsDownloadService.updateFeatureFlag(.autoDowngradeReminder, value: autoDowngradeReminderFF) { error in
            if let error {
                let message = "Failed to update AutoDowngradeReminder feature flag: \(error)"
                SystemLogger.log(message: message, isError: true)
            } else {
                self.user.refreshFeatureFlags()
            }
        }
    }
    
    func reactivateSubscription(completion: @escaping ((Error?) -> Void)) {
        user.apiService.perform(
            request: RenewSubscriptionRequest(api: user.apiService),
            response: VoidResponse()
        ) { _, response in
            DispatchQueue.main.async {
                completion(response.error)
            }
        }
    }
}

extension MailboxViewModel {
    enum NotificationAuthorizationRequestTrigger {
        case onboardingFinished
        case messageSent

        var promptVariant: NotificationAuthorizationPrompt.Variant {
            switch self {
            case .onboardingFinished: .onboardingFinished
            case .messageSent: .messageSent
            }
        }
    }
}

// MARK: - Misc

extension String {
    static func actionSheetTitle(selectedCount: Int, viewMode: ViewMode) -> String {
        switch viewMode {
        case .singleMessage:
            return .localizedStringWithFormat(LocalString._general_message, selectedCount)
        case .conversation:
            return .localizedStringWithFormat(LocalString._general_conversation, selectedCount)
        }
    }
}
