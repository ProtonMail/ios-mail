//
//  SingleMessageViewModel.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
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

import Foundation
import ProtonCoreDataModel
import ProtonCoreUIFoundations
import ProtonCoreUtilities

class SingleMessageViewModel {
    typealias Dependencies = HasUserDefaults

    private var messageEntity: Atomic<MessageEntity>
    var message: MessageEntity {
        messageEntity.value
    }

    let contentViewModel: SingleMessageContentViewModel
    private(set) lazy var userActivity: NSUserActivity = .messageDetailsActivity(messageId: message.messageID)

    private let messageService: MessageDataService
    let user: UserManager
    let labelId: LabelID
    private let messageObserver: MessageObserver

    var refreshView: (() -> Void)?

    var selectedLabelAsLabels: Set<LabelLocation> = Set()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
    private let userIntroductionProgressProvider: UserIntroductionProgressProvider
    private let toolbarActionProvider: ToolbarActionProvider
    private let saveToolbarActionUseCase: SaveToolbarActionSettingsForUsersUseCase
    let highlightedKeywords: [String]
    private let nextMessageAfterMoveStatusProvider: NextMessageAfterMoveStatusProvider

    let coordinator: SingleMessageCoordinator
    private let dependencies: Dependencies
    private let notificationCenter: NotificationCenter

    init(labelId: LabelID,
         message: MessageEntity,
         user: UserManager,
         userIntroductionProgressProvider: UserIntroductionProgressProvider,
         saveToolbarActionUseCase: SaveToolbarActionSettingsForUsersUseCase,
         toolbarActionProvider: ToolbarActionProvider,
         coordinator: SingleMessageCoordinator,
         nextMessageAfterMoveStatusProvider: NextMessageAfterMoveStatusProvider,
         contentViewModel: SingleMessageContentViewModel,
         contextProvider: CoreDataContextProviderProtocol,
         highlightedKeywords: [String],
         notificationCenter: NotificationCenter = .default,
         dependencies: Dependencies
    ) {
        self.labelId = labelId
        self.messageEntity = .init(message)
        self.messageService = user.messageService
        self.user = user
        self.messageObserver = MessageObserver(messageID: message.messageID, contextProvider: contextProvider)
        self.highlightedKeywords = highlightedKeywords
        self.contentViewModel = contentViewModel
        self.coordinator = coordinator
        self.userIntroductionProgressProvider = userIntroductionProgressProvider
        self.toolbarActionProvider = toolbarActionProvider
        self.saveToolbarActionUseCase = saveToolbarActionUseCase
        self.nextMessageAfterMoveStatusProvider = nextMessageAfterMoveStatusProvider
        self.notificationCenter = notificationCenter
        self.dependencies = dependencies
    }

    var messageTitle: NSAttributedString {
        let style = FontManager.MessageHeader.alignment(.center)
        let attributed = message.title.keywordHighlighting.asAttributedString(keywords: highlightedKeywords)
        let range = NSRange(location: 0, length: (message.title as NSString).length)
        attributed.addAttributes(style, range: range)
        return attributed
    }

    func viewDidLoad() {
        messageObserver.observe { [weak self] newMessage in
            let newMessageEntity = MessageEntity(newMessage)
            guard self?.message != newMessageEntity else {
                return
            }
            self?.messageEntity.mutate({ value in
                value = newMessageEntity
            })
            DispatchQueue.main.async {
                self?.propagateMessageData()
            }
        }
    }

    func propagateMessageData() {
        refreshView?()
        contentViewModel.messageHasChanged(message: message)
    }

    func starTapped() {
        messageService.label(messages: [message],
                             label: Message.Location.starred.labelID,
                             apply: !message.isStarred)
    }

    func handleActionSheetAction(_ action: MessageViewActionSheetAction, completion: @escaping () -> Void) {
        switch action {
        case .markRead:
            messageService.mark(messageObjectIDs: [message.objectID.rawValue], labelID: labelId, unRead: false)
        case .markUnread:
            messageService.mark(messageObjectIDs: [message.objectID.rawValue], labelID: labelId, unRead: true)
        case .trash:
            messageService.move(messages: [message],
                                from: [labelId],
                                to: Message.Location.trash.labelID,
                                queue: true)
        case .archive:
            messageService.move(messages: [message],
                                from: [labelId],
                                to: Message.Location.archive.labelID,
                                queue: true)
        case .spam:
            messageService.move(messages: [message],
                                from: [labelId],
                                to: Message.Location.spam.labelID,
                                queue: true)
        case .delete:
            messageService.delete(messages: [message], label: labelId)
        case .reportPhishing:
            reportPhishing(completion)
            return
        case .inbox, .spamMoveToInbox:
            messageService.move(messages: [message],
                                from: [labelId],
                                to: Message.Location.inbox.labelID,
                                queue: true)
        case .viewInDarkMode:
            contentViewModel.messageInfoProvider.currentMessageRenderStyle = .dark
            return
        case .viewInLightMode:
            contentViewModel.messageInfoProvider.currentMessageRenderStyle = .lightOnly
            return
        case .star, .unstar:
            starTapped()
            return
        default:
            break
        }
        completion()
    }

    private func reportPhishing(_ completion: @escaping () -> Void) {
        let messageBody = contentViewModel.messageInfoProvider.bodyParts?.originalBody
        self.user.reportService.reportPhishing(messageID: message.messageID,
                                               messageBody: messageBody ?? LocalString._error_no_object) { _ in
            self.messageService.move(messages: [self.message],
                                     from: [self.labelId],
                                     to: Message.Location.spam.labelID,
                                     queue: true)
            completion()
        }
    }

    func getMessageHeaderUrl() -> URL? {
        let message = contentViewModel.messageInfoProvider.message
        let time = dateFormatter.string(from: message.time ?? Date())
        let title = message.title.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let filename = "headers-" + time + "-" + title.joined(separator: "-")
        guard let header = message.rawHeader else {
            assert(false, "No header in message")
            return nil
        }
        return try? self.writeToTemporaryUrl(header, filename: filename)
    }

    func getMessageBodyUrl() -> URL? {
        let message = contentViewModel.messageInfoProvider.message
        let time = dateFormatter.string(from: message.time ?? Date())
        let title = message.title.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let filename = "body-" + time + "-" + title.joined(separator: "-")
        guard let decryptedPair = try? messageService.messageDecrypter.decrypt(message: message) else {
            return nil
        }
        let body = decryptedPair.0
        return try? self.writeToTemporaryUrl(body, filename: filename)
    }

    func shouldShowToolbarCustomizeSpotlight() -> Bool {
        guard !ProcessInfo.hasLaunchArgument(.disableToolbarSpotlight) else {
            return false
        }

        if userIntroductionProgressProvider.shouldShowSpotlight(for: .toolbarCustomization, toUserWith: user.userID) {
            return true
        }

        //  If 1 of the logged accounts has a non-standard set of actions, Accounts with
        //  standard actions will see the feature spotlight once when
        //  first opening message details.
        let toolbarCustomizeSpotlightShownUserIds = dependencies.userDefaults[.toolbarCustomizeSpotlightShownUserIds]
        let ifCurrentUserAlreadySeenTheSpotlight = toolbarCustomizeSpotlightShownUserIds.contains(user.userID.rawValue)
        if user.hasAtLeastOneNonStandardToolbarAction,
           user.toolbarActionsIsStandard,
           !ifCurrentUserAlreadySeenTheSpotlight {
            return true
        }
        return false
    }

    func setToolbarCustomizeSpotlightViewIsShown() {
        userIntroductionProgressProvider.markSpotlight(
            for: .toolbarCustomization,
            asSeen: true,
            byUserWith: user.userID
        )
        dependencies.userDefaults[.toolbarCustomizeSpotlightShownUserIds].append(user.userID.rawValue)
    }

    private func writeToTemporaryUrl(_ content: String, filename: String) throws -> URL {
        let tempFileUri = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename, isDirectory: false).appendingPathExtension("txt")
        try? FileManager.default.removeItem(at: tempFileUri)
        try content.write(to: tempFileUri, atomically: true, encoding: .utf8)
        return tempFileUri
    }

    func searchForScheduled(displayAlert: @escaping () -> Void,
                            continueAction: @escaping () -> Void) {
        guard message.contains(location: .scheduled) else {
            continueAction()
            return
        }
        displayAlert()
    }

    func navigate(to navigationAction: SingleMessageNavigationAction) {
        coordinator.navigate(to: navigationAction)
    }

    func navigateToNextMessage(isInPageView: Bool, popCurrentView: (() -> Void)? = nil) {
        guard isInPageView else {
            popCurrentView?()
            return
        }
        guard nextMessageAfterMoveStatusProvider.shouldMoveToNextMessageAfterMove else {
            return
        }
        let userInfo: [String: Any] = ["expectation": PagesSwipeAction.forward, "reload": true]
        notificationCenter.post(name: .pagesSwipeExpectation, object: nil, userInfo: userInfo)
    }
}

// MARK: - Toolbar action functions
extension SingleMessageViewModel: ToolbarCustomizationActionHandler {
    func toolbarActionTypes() -> [MessageViewActionSheetAction] {
        let originMessageListIsSpamOrTrash = [
            Message.Location.spam.labelID,
            Message.Location.trash.labelID
        ].contains(labelId)
        let isInTrash = message.isTrash
        let isInArchive = message.contains(location: .archive)
        let hasMultipleRecipients = message.allRecipients.count > 1
        let isInSpam = message.isSpam
        let isRead = !message.unRead
        let isStarred = message.isStarred
        let isScheduledSend = message.isScheduledSend

        var actions = toolbarActionProvider.messageToolbarActions.addMoreActionToTheLastLocation()
        actions.removeAll(where: { $0 == .snooze })

        if isScheduledSend {
            let forbidActions: [MessageViewActionSheetAction] = [
                .replyInConversation,
                .reply,
                .forward,
                .forwardInConversation,
                .replyOrReplyAll
            ]
            actions = actions.filter { !forbidActions.contains($0) }
        }

        return replaceActionsLocally(actions: actions,
                                     isInSpam: isInSpam || originMessageListIsSpamOrTrash,
                                     isInTrash: isInTrash || originMessageListIsSpamOrTrash,
                                     isInArchive: isInArchive,
                                     isRead: isRead,
                                     isStarred: isStarred,
                                     hasMultipleRecipients: hasMultipleRecipients)
    }

    func toolbarCustomizationAllAvailableActions() -> [MessageViewActionSheetAction] {
        let messageInfoProvider = contentViewModel.messageInfoProvider
        let bodyViewModel = contentViewModel.messageBodyViewModel
        let actionSheetViewModel = MessageViewActionSheetViewModel(
            title: message.title,
            labelID: labelId,
            isStarred: message.isStarred,
            isBodyDecryptable: messageInfoProvider.isBodyDecryptable,
            messageRenderStyle: bodyViewModel.currentMessageRenderStyle,
            shouldShowRenderModeOption: messageInfoProvider.shouldDisplayRenderModeOptions,
            isScheduledSend: messageInfoProvider.message.isScheduledSend,
            shouldShowSnooze: false
        )
        let isInSpam = message.isSpam
        let isInTrash = message.isTrash
        let isInArchive = message.contains(location: .archive)
        let isRead = !message.unRead
        let isStarred = message.isStarred
        let hasMultipleRecipients = message.allRecipients.count > 1

        return replaceActionsLocally(
            actions: actionSheetViewModel.items.replaceReplyAndReplyAllWithSingleAction(),
            isInSpam: isInSpam,
            isInTrash: isInTrash,
            isInArchive: isInArchive,
            isRead: isRead,
            isStarred: isStarred,
            hasMultipleRecipients: hasMultipleRecipients
        )
    }

    func saveToolbarAction(actions: [MessageViewActionSheetAction],
                           completion: ((NSError?) -> Void)?) {
        let preference: ToolbarActionPreference = .init(
            messageActions: actions,
            listViewActions: nil
        )
        saveToolbarActionUseCase
            .callbackOn(.main)
            .execute(params: .init(preference: preference)) { result in
                switch result {
                case .success:
                    completion?(nil)
                case let .failure(error):
                    completion?(error as NSError)
                }
            }
    }
}

// MARK: - Move to functions
extension SingleMessageViewModel: MoveToActionSheetProtocol {
    func handleMoveToAction(messages: [MessageEntity], to folder: MenuLabel) {
        messageService.move(messages: messages, to: folder.location.labelID, queue: true)
    }
}

// MARK: - Label as functions
extension SingleMessageViewModel: LabelAsActionSheetProtocol {
    func handleLabelAsAction(messages: [MessageEntity],
                             shouldArchive: Bool,
                             currentOptionsStatus: [MenuLabel: PMActionSheetItem.MarkType]) {
        for (label, status) in currentOptionsStatus {
            guard status != .dash else { continue } // Ignore the option in dash
            if selectedLabelAsLabels
                .contains(where: { $0.rawLabelID == label.location.rawLabelID }) {
                // Add to message which does not have this label
                if !message.contains(location: label.location) {
                    messageService.label(messages: messages,
                                         label: label.location.labelID,
                                         apply: true)
                }
            } else {
                if message.contains(location: label.location) {
                    messageService.label(messages: messages,
                                         label: label.location.labelID,
                                         apply: false)
                }
            }
        }

        selectedLabelAsLabels.removeAll()

        if shouldArchive {
            if let fLabel = message.getFirstValidFolder() {
                messageService.move(messages: messages,
                                    from: [fLabel],
                                    to: Message.Location.archive.labelID)
            }
        }
    }

    func handleLabelAsAction(conversations: [ConversationEntity],
                             shouldArchive: Bool,
                             currentOptionsStatus: [MenuLabel: PMActionSheetItem.MarkType],
                             completion: (() -> Void)?) {
        fatalError("Not implemented")
    }
}
