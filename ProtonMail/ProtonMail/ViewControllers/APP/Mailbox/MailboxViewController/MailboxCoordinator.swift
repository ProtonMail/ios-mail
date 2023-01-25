//
//  MailboxCoordinator.swift.swift
//  Proton Mail - Created on 12/10/18.
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

import ProtonMailAnalytics
import SideMenuSwift
import class ProtonCore_DataModel.UserInfo

class MailboxCoordinator: CoordinatorDismissalObserver {
    let viewModel: MailboxViewModel
    var services: ServiceFactory
    private let contextProvider: CoreDataContextProviderProtocol
    private let internetStatusProvider: InternetConnectionStatusProvider

    weak var viewController: MailboxViewController?
    private(set) weak var navigation: UINavigationController?
    private weak var sideMenu: SideMenuController?
    var pendingActionAfterDismissal: (() -> Void)?
    private(set) var singleMessageCoordinator: SingleMessageCoordinator?
    private(set) var conversationCoordinator: ConversationCoordinator?
    private let getApplicationState: () -> UIApplication.State
    let infoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider

    init(sideMenu: SideMenuController?,
         nav: UINavigationController?,
         viewController: MailboxViewController,
         viewModel: MailboxViewModel,
         services: ServiceFactory,
         contextProvider: CoreDataContextProviderProtocol,
         infoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider,
         internetStatusProvider: InternetConnectionStatusProvider = InternetConnectionStatusProvider(),
         getApplicationState: @escaping () -> UIApplication.State = {
        return UIApplication.shared.applicationState
    }
    ) {
        self.sideMenu = sideMenu
        self.navigation = nav
        self.viewController = viewController
        self.viewModel = viewModel
        self.services = services
        self.contextProvider = contextProvider
        self.internetStatusProvider = internetStatusProvider
        self.getApplicationState = getApplicationState
        self.infoBubbleViewStatusProvider = infoBubbleViewStatusProvider
    }

    enum Destination: String {
        case composer = "toCompose"
        case composeShow = "toComposeShow"
        case composeMailto = "toComposeMailto"
        case composeScheduledMessage = "composeScheduledMessage"
        case search = "toSearchViewController"
        case details = "SingleMessageViewController"
        case onboardingForNew = "to_onboardingForNew_segue"
        case onboardingForUpdate = "to_onboardingForUpdate_segue"
        case humanCheck = "toHumanCheckView"
        case troubleShoot = "toTroubleShootSegue"
        case newFolder = "toNewFolder"
        case newLabel = "toNewLabel"

        init?(rawValue: String) {
            switch rawValue {
            case "toCompose":
                self = .composer
            case "toComposeShow", String(describing: ComposeContainerViewController.self):
                self = .composeShow
            case "toComposeMailto":
                self = .composeMailto
            case "toSearchViewController", String(describing: SearchViewController.self):
                self = .search
            case "toMessageDetailViewController",
                String(describing: SingleMessageViewController.self),
                String(describing: ConversationViewController.self):
                self = .details
            case "to_onboardingForNew_segue":
                self = .onboardingForNew
            case "to_onboardingForUpdate_segue":
                self = .onboardingForUpdate
            case "toHumanCheckView":
                self = .humanCheck
            case "toTroubleShootSegue":
                self = .troubleShoot
            case "composeScheduledMessage":
                self = .composeScheduledMessage
            default:
                return nil
            }
        }
    }

    /// if called from a segue prepare don't call push again
    func start() {
        viewController?.set(viewModel: viewModel)
        self.viewController?.set(coordinator: self)

        if let navigation = self.navigation, self.sideMenu != nil {
            self.sideMenu?.setContentViewController(to: navigation)
            self.sideMenu?.hideMenu()
        }
        if let presented = self.viewController?.presentedViewController {
            presented.dismiss(animated: false, completion: nil)
        }
    }

    func go(to dest: Destination, sender: Any? = nil) {
        switch dest {
        case .details:
            handleDetailDirectFromMailBox()
        case .newFolder:
            self.presentCreateFolder(type: .folder)
        case .newLabel:
            presentCreateFolder(type: .label)
        case .onboardingForNew:
            presentOnboardingView()
        case .onboardingForUpdate:
            presentNewBrandingView()
        case .composer:
            navigateToComposer(existingMessage: nil)
        case .composeShow, .composeMailto:
            self.viewController?.cancelButtonTapped()

            guard let message = sender as? Message else { return }

            navigateToComposer(existingMessage: message)
        case .composeScheduledMessage:
            guard let message = sender as? Message else { return }
            editScheduleMsg(messageID: MessageID(message.messageID), originalScheduledTime: nil)
        case .troubleShoot:
            presentTroubleShootView()
        case .search:
            presentSearch()
        case .humanCheck:
            presentCaptcha()
        }
    }

    func follow(_ deeplink: DeepLink) {
        guard let path = deeplink.popFirst, let dest = Destination(rawValue: path.name) else { return }

        switch dest {
        case .details:
            handleDetailDirectFromNotification(node: path)
            viewModel.resetNotificationMessage()
        case .composeShow where path.value != nil:
            if let messageID = path.value,
               let nav = self.navigation,
               case let user = self.viewModel.user,
               case let msgService = user.messageService,
               let message = msgService.fetchMessages(withIDs: [messageID], in: contextProvider.mainContext).first {
                let viewModel = ContainableComposeViewModel(msg: message,
                                                            action: .openDraft,
                                                            msgService: msgService,
                                                            user: user,
                                                            coreDataContextProvider: contextProvider)

                showComposer(viewModel: viewModel, navigationVC: nav, deepLink: deeplink)
            }
        case .composeShow where path.value == nil:
            if let nav = self.navigation {
                let user = self.viewModel.user
                let viewModel = ContainableComposeViewModel(msg: nil,
                                                            action: .newDraft,
                                                            msgService: user.messageService,
                                                            user: user,
                                                            coreDataContextProvider: contextProvider)
                showComposer(viewModel: viewModel, navigationVC: nav, deepLink: deeplink)
            }
        case .composeMailto where path.value != nil:
            followToComposeMailTo(path: path.value, deeplink: deeplink)
        case .composeScheduledMessage where path.value != nil:
            guard let messageID = path.value,
                  let originalScheduledTime = path.states?["originalScheduledTime"] as? Date else {
                return
            }
            if case let user = self.viewModel.user,
               case let msgService = user.messageService,
               let message = msgService.fetchMessages(withIDs: [messageID], in: contextProvider.mainContext).first {
                navigateToComposer(
                    existingMessage: message,
                    isEditingScheduleMsg: true,
                    originalScheduledTime: .init(rawValue: originalScheduledTime)
                )
            }
        default:
            self.go(to: dest, sender: deeplink)
        }
    }
}

extension MailboxCoordinator {
    private func showComposer(viewModel: ContainableComposeViewModel,
                              navigationVC: UINavigationController,
                              deepLink: DeepLink) {
        let composer = ComposeContainerViewCoordinator(presentingViewController: navigationVC,
                                                       editorViewModel: viewModel,
                                                       services: services)
        composer.start()
        composer.follow(deepLink)
    }

    private func presentCreateFolder(type: PMLabelType) {
        let user = self.viewModel.user
        let folderLabels = user.labelService.getMenuFolderLabels()
        let dependencies = LabelEditViewModel.Dependencies(userManager: user)
        let labelEditNavigationController = LabelEditStackBuilder.make(
            editMode: .creation,
            type: type,
            labels: folderLabels,
            dependencies: dependencies,
            coordinatorDismissalObserver: self
        )
        viewController?.navigationController?.present(labelEditNavigationController, animated: true, completion: nil)
    }

    private func presentOnboardingView() {
        let viewController = OnboardViewController()
        viewController.modalPresentationStyle = .fullScreen
        self.viewController?.present(viewController, animated: true, completion: nil)
    }

    private func presentNewBrandingView() {
        let viewController = NewBrandingViewController.instance()
        viewController.modalPresentationStyle = .overCurrentContext
        self.viewController?.present(viewController, animated: true, completion: nil)
    }

    private func navigateToComposer(
        existingMessage: Message?,
        isEditingScheduleMsg: Bool = false,
        isOpenedFromShare: Bool = false,
        originalScheduledTime: OriginalScheduleDate? = nil
    ) {
        let user = self.viewModel.user
        let viewModel = ContainableComposeViewModel(msg: existingMessage,
                                                    action: existingMessage == nil ? .newDraft : .openDraft,
                                                    msgService: user.messageService,
                                                    user: user,
                                                    coreDataContextProvider: contextProvider,
                                                    isEditingScheduleMsg: isEditingScheduleMsg,
                                                    isOpenedFromShare: isOpenedFromShare,
                                                    originalScheduledTime: originalScheduledTime)
        let composer = ComposeContainerViewCoordinator(presentingViewController: self.viewController,
                                                       editorViewModel: viewModel)
        composer.start()
    }

    private func presentSearch() {
        let viewModel = SearchViewModel(
            user: viewModel.user,
            coreDataContextProvider: services.get(by: CoreDataService.self),
            queueManager: services.get(by: QueueManager.self),
            realAttachmentsFlagProvider: userCachedStatus
        )
        let viewController = SearchViewController(viewModel: viewModel)
        viewModel.uiDelegate = viewController
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalTransitionStyle = .coverVertical
        navigationController.modalPresentationStyle = .fullScreen
        self.viewController?.present(navigationController, animated: true)
    }

    private func presentCaptcha() {
        let next = MailboxCaptchaViewController()
        let user = self.viewModel.user
        next.viewModel = CaptchaViewModelImpl(api: user.apiService)
        next.delegate = self.viewController
        self.viewController?.present(next, animated: true)
    }

    func fetchConversationFromBEIfNeeded(conversationID: ConversationID, goToDetailPage: @escaping () -> Void) {
        guard internetStatusProvider.currentStatus != .notConnected else {
            goToDetailPage()
            return
        }

        viewController?.showProgressHud()
        viewModel.fetchConversationDetail(conversationID: conversationID) { [weak self] in
            defer {
                self?.viewController?.hideProgressHud()
            }
            // Prevent the app tries to push a new view when the app enters
            // the background due to long network fetching time.
            // It could cause the app crashed in the background.
            guard self?.getApplicationState() == .active else {
                return
            }
            goToDetailPage()
        }
    }

    private func followToComposeMailTo(path: String?, deeplink: DeepLink) {
        if let msgID = path,
           let existingMsg = Message.messageForMessageID(msgID, inManagedObjectContext: contextProvider.mainContext) {
            navigateToComposer(existingMessage: existingMsg, isOpenedFromShare: true)
            return
        }

        if let nav = self.navigation,
           let value = path,
           let mailToURL = URL(string: value) {
            let user = self.viewModel.user
            let viewModel = ContainableComposeViewModel(msg: nil,
                                                        action: .newDraft,
                                                        msgService: user.messageService,
                                                        user: user,
                                                        coreDataContextProvider: contextProvider)
            viewModel.parse(mailToURL: mailToURL)
            let composer = ComposeContainerViewCoordinator(presentingViewController: nav,
                                                           editorViewModel: viewModel,
                                                           services: services)
            composer.start()
            composer.follow(deeplink)
        }
    }

    private func presentTroubleShootView() {
        let view = NetworkTroubleShootViewController(viewModel: NetworkTroubleShootViewModel())
        let nav = UINavigationController(rootViewController: view)
        self.viewController?.present(nav, animated: true, completion: nil)
    }

    func presentToolbarCustomizationView(
        allActions: [MessageViewActionSheetAction],
        currentActions: [MessageViewActionSheetAction]
    ) {
        let view = ToolbarCustomizeViewController<MessageViewActionSheetAction>(
            viewModel: .init(
                currentActions: currentActions,
                allActions: allActions,
                actionsNotAddableToToolbar: MessageViewActionSheetAction.actionsNotAddableToToolbar,
                defaultActions: MessageViewActionSheetAction.defaultActions,
                infoBubbleViewStatusProvider: infoBubbleViewStatusProvider
            )
        )
        view.customizationIsDone = { [weak self] result in
            self?.viewController?.showProgressHud()
            self?.viewModel.updateToolbarActions(
                actions: result,
                completion: { error in
                    if let error = error {
                        error.alertErrorToast()
                    }
                    self?.viewController?.refreshActionBarItems()
                    self?.viewController?.hideProgressHud()
                })
        }
        let nav = UINavigationController(rootViewController: view)
        viewController?.navigationController?.present(nav, animated: true)
    }

    private func editScheduleMsg(messageID: MessageID, originalScheduledTime: OriginalScheduleDate?) {
        let context = contextProvider.mainContext
        guard let msg = Message.messageForMessageID(messageID.rawValue, inManagedObjectContext: context) else {
            return
        }
        navigateToComposer(existingMessage: msg, isEditingScheduleMsg: true, originalScheduledTime: originalScheduledTime)
    }
}

extension MailboxCoordinator {
    private func handleDetailDirectFromMailBox() {
        switch viewModel.locationViewMode {
        case .singleMessage:
            messageToShow(isNotification: false, node: nil) { [weak self] message in
                guard let message = message else { return }
                if UserInfo.isConversationSwipeEnabled {
                    self?.presentPageViewsFor(message: message)
                } else {
                    self?.present(message: message)
                }
            }
        case .conversation:
            conversationToShow(isNotification: false, message: nil) { [weak self] conversation in
                guard let conversation = conversation else { return }
                if UserInfo.isConversationSwipeEnabled {
                    self?.presentPageViewsFor(conversation: conversation, targetID: nil)
                } else {
                    self?.present(conversation: conversation, targetID: nil)
                }
            }
        }
    }

    private func handleDetailDirectFromNotification(node: DeepLink.Node) {
        resetNavigationViewControllersIfNeeded()
        presentMessagePlaceholder()

        messageToShow(isNotification: true, node: node) { [weak self] message in
            guard let self = self,
                  let message = message else {
                self?.viewController?.navigationController?.popViewController(animated: true)
                L11n.Error.cant_open_message.alertToastBottom()
                return
            }
            let messageID = message.messageID
            switch self.viewModel.locationViewMode {
            case .singleMessage:
                if UserInfo.isConversationSwipeEnabled {
                    self.presentPageViewsFor(message: message)
                } else {
                    self.present(message: message)
                }
                let folderID = message.firstValidFolder()
                self.switchFolderIfNeeded(folderID: folderID?.rawValue)
            case .conversation:
                self.conversationToShow(isNotification: true, message: message) { [weak self] conversation in
                    guard let conversation = conversation else {
                        self?.viewController?.navigationController?.popViewController(animated: true)
                        L11n.Error.cant_open_message.alertToastBottom()
                        return
                    }
                    if UserInfo.isConversationSwipeEnabled {
                        self?.presentPageViewsFor(conversation: conversation, targetID: messageID)
                    } else {
                        self?.present(conversation: conversation, targetID: messageID)
                    }
                    let folderID = message.firstValidFolder()
                    self?.switchFolderIfNeeded(folderID: folderID?.rawValue)
                }
            }
        }
    }

    private func conversationToShow(
        isNotification: Bool,
        message: MessageEntity?,
        completion: @escaping (ConversationEntity?) -> Void
    ) {
        guard isNotification else {
            // Click from mailbox list
            guard let indexPathForSelectedRow = viewController?.tableView.indexPathForSelectedRow,
                  let conversation = viewModel.itemOfConversation(index: indexPathForSelectedRow) else {
                completion(nil)
                return
            }
            completion(conversation)
            return
        }

        // From notification
        guard let conversationID = message?.conversationID else {
            completion(nil)
            return
        }
        fetchConversationFromBEIfNeeded(conversationID: conversationID) { [weak self] in
            guard
                let context = self?.contextProvider.mainContext,
                let conversation = Conversation
                    .conversationForConversationID(
                        conversationID.rawValue,
                        inManagedObjectContext: context
                    )
            else {
                completion(nil)
                return
            }
            completion(ConversationEntity(conversation))
        }
    }

    private func messageToShow(
        isNotification: Bool,
        node: DeepLink.Node?,
        completion: @escaping (MessageEntity?) -> Void
    ) {
        guard isNotification else {
            // Click from mailbox list
            guard let indexPathForSelectedRow = viewController?.tableView.indexPathForSelectedRow,
                  let message = self.viewModel.item(index: indexPathForSelectedRow) else {
                completion(nil)
                return
            }
            completion(message)
            return
        }

        // From notification
        guard let messageID = node?.value else {
            completion(nil)
            return
        }

        viewModel.user.messageService.fetchNotificationMessageDetail(MessageID(messageID)) { [weak self] _ in
            guard let self = self else { return }
            if let message = Message.messageForMessageID(
                messageID,
                inManagedObjectContext: self.contextProvider.mainContext
            ) {
                completion(MessageEntity(message))
            } else {
                completion(nil)
            }
        }
    }

    private func present(message: MessageEntity) {
        guard let navigationController = viewController?.navigationController else { return }
        let coordinator = SingleMessageCoordinator(
            navigationController: navigationController,
            labelId: viewModel.labelID,
            message: message,
            user: viewModel.user,
            infoBubbleViewStatusProvider: infoBubbleViewStatusProvider
        )
        coordinator.goToDraft = { [weak self] msgID, originalScheduleTime in
            self?.editScheduleMsg(messageID: msgID, originalScheduledTime: originalScheduleTime)
        }
        singleMessageCoordinator = coordinator
        coordinator.start()
    }

    private func present(conversation: ConversationEntity, targetID: MessageID?) {
        guard let navigationController = viewController?.navigationController else { return }
        let coordinator = ConversationCoordinator(
            labelId: viewModel.labelID,
            navigationController: navigationController,
            conversation: conversation,
            user: viewModel.user,
            internetStatusProvider: services.get(by: InternetConnectionStatusProvider.self),
            infoBubbleViewStatusProvider: infoBubbleViewStatusProvider,
            targetID: targetID
        )
        conversationCoordinator = coordinator
        coordinator.goToDraft = { [weak self] msgID, originalScheduledTime in
            self?.editScheduleMsg(messageID: msgID, originalScheduledTime: originalScheduledTime)
        }
        coordinator.start()
    }

    private func presentPageViewsFor(message: MessageEntity) {
        guard let navigationController = viewController?.navigationController else { return }
        let pageVM = MessagePagesViewModel(
            initialID: message.messageID,
            isUnread: viewController?.isShowingUnreadMessageOnly ?? false,
            labelID: viewModel.labelID,
            user: viewModel.user,
            infoBubbleViewStatusProvider: infoBubbleViewStatusProvider,
            goToDraft: { [weak self] msgID, originalScheduledTime in
                self?.editScheduleMsg(messageID: msgID, originalScheduledTime: originalScheduledTime)
            }
        )
        let page = PagesViewController(viewModel: pageVM, services: services)
        navigationController.show(page, sender: nil)
    }

    private func presentPageViewsFor(conversation: ConversationEntity, targetID: MessageID?) {
        guard let navigationController = viewController?.navigationController else { return }
        let pageVM = ConversationPagesViewModel(
            initialID: conversation.conversationID,
            isUnread: viewController?.isShowingUnreadMessageOnly ?? false,
            labelID: viewModel.labelID,
            user: viewModel.user,
            targetMessageID: targetID,
            infoBubbleViewStatusProvider: infoBubbleViewStatusProvider,
            goToDraft: { [weak self] msgID, originalScheduledTime in
                self?.editScheduleMsg(messageID: msgID, originalScheduledTime: originalScheduledTime)
            }
        )
        let page = PagesViewController(viewModel: pageVM, services: services)
        navigationController.show(page, sender: nil)
    }

    private func presentMessagePlaceholder() {
        guard let navigationController = viewController?.navigationController else { return }
        let placeholder = MessagePlaceholderVC()
        navigationController.pushViewController(placeholder, animated: true)
    }

    private func switchFolderIfNeeded(folderID: String?) {
        // Wait 1 second for navigation.viewControllers update 
        delay(1) {
            let link = DeepLink(MenuCoordinator.Setup.switchInboxFolder.rawValue, sender: folderID)
            NotificationCenter.default.post(name: .switchView, object: link)
        }
    }

    private func resetNavigationViewControllersIfNeeded() {
        if let viewStack = viewController?.navigationController?.viewControllers,
           viewStack.count > 1,
           let firstVC = viewStack.first {
            viewController?.navigationController?.setViewControllers([firstVC], animated: false)
        }
    }
}
