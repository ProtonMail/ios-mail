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

import class ProtonCoreDataModel.UserInfo
import ProtonCoreTroubleShooting
import ProtonCoreUIFoundations
import ProtonMailAnalytics
import ProtonMailUI
import SideMenuSwift
import protocol ProtonCoreServices.APIService

// sourcery: mock
protocol MailboxCoordinatorProtocol: AnyObject {
    var pendingActionAfterDismissal: (() -> Void)? { get set }

    func go(to dest: MailboxCoordinator.Destination, sender: Any?)
    func presentToolbarCustomizationView(
        allActions: [MessageViewActionSheetAction],
        currentActions: [MessageViewActionSheetAction]
    )
}

class MailboxCoordinator: MailboxCoordinatorProtocol, CoordinatorDismissalObserver {
    typealias Dependencies = HasInternetConnectionStatusProviderProtocol
    & HasPushNotificationService
    & SearchViewController.Dependencies
    & SearchViewModel.Dependencies
    & SingleMessageCoordinator.Dependencies

    let viewModel: MailboxViewModel
    private let contextProvider: CoreDataContextProviderProtocol

    weak var viewController: MailboxViewController?
    private(set) weak var navigation: UINavigationController?
    private var settingsDeviceCoordinator: SettingsDeviceCoordinator?
    private weak var sideMenu: SideMenuController?
    var pendingActionAfterDismissal: (() -> Void)?
    private var timeOfLastNavigationToMessageDetails: Date?

    private let troubleShootingHelper = TroubleShootingHelper(doh: BackendConfiguration.shared.doh)
    private let dependencies: Dependencies
    private var _snoozeDateConfigReceiver: SnoozeDateConfigReceiver?
    private var onboardingUpsellCoordinator: OnboardingUpsellCoordinator?

    init(sideMenu: SideMenuController?,
         nav: UINavigationController?,
         viewController: MailboxViewController,
         viewModel: MailboxViewModel,
         dependencies: Dependencies) {
        self.sideMenu = sideMenu
        self.navigation = nav
        self.viewController = viewController
        self.viewModel = viewModel
        self.contextProvider = dependencies.contextProvider
        self.dependencies = dependencies
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
        case troubleShoot = "toTroubleShootSegue"
        case newFolder = "toNewFolder"
        case newLabel = "toNewLabel"
        case referAFriend = "referAFriend"
        case settingsContacts = "toSettingsContacts"
        case subscriptions = "subscriptions"

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
            case "toTroubleShootSegue":
                self = .troubleShoot
            case "composeScheduledMessage":
                self = .composeScheduledMessage
            case "referAFriend":
                self = .referAFriend
            case "toSettingsContacts":
                self = .settingsContacts
            case "subscriptions":
                self = .subscriptions
            default:
                return nil
            }
        }
    }

    /// if called from a segue prepare don't call push again
    func start() {
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

            guard let message = sender as? MessageEntity else { return }

            navigateToComposer(existingMessage: message)
        case .composeScheduledMessage:
            guard let message = sender as? Message else { return }
            editScheduleMsg(messageID: MessageID(message.messageID), originalScheduledTime: nil)
        case .troubleShoot:
            presentTroubleShootView()
        case .search:
            presentSearch()
        case .referAFriend:
            presentReferAFriend()
        case .settingsContacts:
            navigateToSettings(destination: .contactsSettings)
        case .subscriptions:
            goToSubscriptions()
        }
    }

    func follow(_ deeplink: DeepLink) {
        guard let path = deeplink.popFirst, let dest = Destination(rawValue: path.name) else { return }

        switch dest {
        case .details:
            SystemLogger.log(
                message: "Mailbox start follow: \(path.debugDescription), userID: \(viewModel.user.userID)",
                category: .notificationDebug
            )
            handleDetailDirectFromNotification(node: path)
            viewModel.resetNotificationMessage()
        case .composeShow:
            if let nav = self.navigation {
                let existingMessage: MessageEntity?
                if let messageID = path.value {
                    existingMessage = fetchMessage(by: .init(messageID))
                } else {
                    existingMessage = nil
                }

                let composer = dependencies.composerViewFactory.makeComposer(
                    msg: existingMessage,
                    action: existingMessage == nil ? .newDraft : .openDraft
                )
                nav.present(composer, animated: true)
            }
        case .composeMailto where path.value != nil:
            let upsellPageEntryPoint: UpsellPageEntryPoint?
            if deeplink.first?.name == "toUpsellPage", deeplink.first?.value == "scheduleSend" {
                upsellPageEntryPoint = .scheduleSend
            } else {
                upsellPageEntryPoint = nil
            }

            followToComposeMailTo(path: path.value, upsellPageEntryPoint: upsellPageEntryPoint)
        case .composeScheduledMessage where path.value != nil:
            guard let messageID = path.value,
                  let originalScheduledTime = path.states?["originalScheduledTime"] as? Date else {
                return
            }
            if let message = fetchMessage(by: .init(messageID)) {
                navigateToComposer(
                    existingMessage: message,
                    isEditingScheduleMsg: true,
                    originalScheduledTime: .init(originalScheduledTime)
                )
            }
        default:
            self.go(to: dest, sender: deeplink)
        }
    }
}

extension MailboxCoordinator {
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
        let viewController = OnboardViewController(isPaidUser: viewModel.user.hasPaidMailPlan)
        viewController.modalPresentationStyle = .fullScreen
        viewController.onViewDidDisappear = { [weak self] in
            guard let self else { return }

            if shouldPresentOnboardingUpsell() {
                presentOnboardingUpsell()
            } else {
                requestNotificationAuthorizationIfApplicable()
            }
        }
        navigation?.present(viewController, animated: true, completion: nil)
    }

    private func shouldPresentOnboardingUpsell() -> Bool {
        dependencies.featureFlagProvider.isEnabled(.postOnboardingUpsellPage) &&
        !viewModel.user.hasPaidMailPlan &&
        dependencies.userDefaults[.didSignUpOnThisDevice] != true
    }

    @MainActor
    private func presentOnboardingUpsell() {
        guard let navigation else {
            return
        }

        onboardingUpsellCoordinator = dependencies.paymentsUIFactory.makeOnboardingUpsellCoordinator(
            rootViewController: navigation
        )

        onboardingUpsellCoordinator?.start { [weak self] in
            self?.requestNotificationAuthorizationIfApplicable()
        }
    }

    private func requestNotificationAuthorizationIfApplicable() {
        viewController?.requestNotificationAuthorizationIfApplicable(trigger: .onboardingFinished)
    }

    private func presentNewBrandingView() {
        let viewController = NewBrandingViewController.instance()
        viewController.modalPresentationStyle = .overCurrentContext
        self.viewController?.present(viewController, animated: true, completion: nil)
    }

    private func navigateToComposer(
        existingMessage: MessageEntity?,
        isEditingScheduleMsg: Bool = false,
        originalScheduledTime: Date? = nil,
        upsellPageEntryPoint: UpsellPageEntryPoint? = nil
    ) {
        guard let navigationVC = navigation else {
            return
        }
        let composer = dependencies.composerViewFactory.makeComposer(
            msg: existingMessage,
            action: existingMessage == nil ? .newDraft : .openDraft,
            isEditingScheduleMsg: isEditingScheduleMsg,
            originalScheduledTime: originalScheduledTime,
            composerDelegate: viewController
        )

        navigationVC.present(composer, animated: true) {
            if let upsellPageEntryPoint {
                let actualComposer = composer.viewControllers.first as? ComposeContainerViewController
                actualComposer?.presentUpsellPage(entryPoint: upsellPageEntryPoint)
            }
        }
    }

    private func presentSearch() {
        let viewModel = SearchViewModel(dependencies: dependencies)
        let viewController = SearchViewController(viewModel: viewModel, dependencies: dependencies)
        viewModel.uiDelegate = viewController
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalTransitionStyle = .coverVertical
        navigationController.modalPresentationStyle = .fullScreen
        self.viewController?.present(navigationController, animated: true)
    }

    func fetchConversationFromBEIfNeeded(conversationID: ConversationID, goToDetailPage: @escaping () -> Void) {
        guard dependencies.internetConnectionStatusProvider.status.isConnected else {
            goToDetailPage()
            return
        }

        viewController?.showProgressHud()
        viewModel.fetchConversationDetail(conversationID: conversationID) { [weak self] in
            defer {
                self?.viewController?.hideProgressHud()
            }
            goToDetailPage()
        }
    }

    private func followToComposeMailTo(path: String?, upsellPageEntryPoint: UpsellPageEntryPoint?) {
        if let msgID = path,
           let msg = fetchMessage(by: .init(msgID)) {
            navigateToComposer(existingMessage: msg, upsellPageEntryPoint: upsellPageEntryPoint)
            return
        }

        if let nav = self.navigation,
           let value = path,
           let mailToURL = URL(string: value) {
            let composer = dependencies.composerViewFactory.makeComposer(
                msg: nil,
                action: .newDraft,
                isEditingScheduleMsg: false,
                mailToUrl: mailToURL
            )
            nav.present(composer, animated: true)
        }
    }

    private func presentTroubleShootView() {
        if let viewController = viewController {
            troubleShootingHelper.showTroubleShooting(over: viewController)
        }
    }

    func presentToolbarCustomizationView(
        allActions: [MessageViewActionSheetAction],
        currentActions: [MessageViewActionSheetAction]
    ) {
        let view = dependencies.toolbarSettingViewFactory.makeCustomizeView(
            currentActions: currentActions,
            allActions: allActions
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

    private func editScheduleMsg(messageID: MessageID, originalScheduledTime: Date?) {
        let msg: MessageEntity? = fetchMessage(by: messageID)
        guard let msg = msg else {
            return
        }
        navigateToComposer(
            existingMessage: msg,
            isEditingScheduleMsg: true,
            originalScheduledTime: originalScheduledTime
        )
    }

    private func fetchMessage(by messageID: MessageID) -> MessageEntity? {
        return dependencies.contextProvider.read(block: { context in
            if let msg = Message.messageForMessageID(messageID.rawValue, inManagedObjectContext: context) {
                return MessageEntity(msg)
            } else {
                return nil
            }
        })
    }

    private func goToSubscriptions() {
        let link = DeepLink(.toSubscriptionPage)
        NotificationCenter.default.post(name: .switchView, object: link)
    }
}

extension MailboxCoordinator {
    private func handleDetailDirectFromMailBox() {
        switch viewModel.locationViewMode {
        case .singleMessage:
            messageToShow(isNotification: false, node: nil) { [weak self] message in
                guard let self = self,
                      let message = message else { return }
                if viewModel.messageLocation == .sent,
                   viewModel.isConversationModeEnabled,
                   let conversation = findConversation(for: message) {
                    self.presentPageViewsFor(conversation: conversation, targetID: message.messageID)
                } else {
                    self.presentPageViewsFor(message: message)
                }
            }
        case .conversation:
            conversationToShow(isNotification: false, message: nil) { [weak self] conversation in
                guard let self = self,
                      let conversation = conversation else { return }
                self.presentPageViewsFor(conversation: conversation, targetID: nil)
            }
        }
    }

    private func findConversation(for message: MessageEntity) -> ConversationEntity? {
        let conversationID = message.conversationID

        return contextProvider.read { context in
            let conversations = self.conversationDataService.fetchLocalConversations(
                withIDs: [conversationID],
                in: context
            )

            return conversations.first.map(ConversationEntity.init)
        }
    }

    private func handleDetailDirectFromNotification(node: DeepLink.Node) {
        if let timeOfLastNavigationToMessageDetails,
            Date().timeIntervalSince(timeOfLastNavigationToMessageDetails) < 3 {
            return
        }

        timeOfLastNavigationToMessageDetails = Date()

        resetNavigationViewControllersIfNeeded()
        SystemLogger.log(
            message: "PresentMessagePlaceholderIfNeeded: \(node.debugDescription)",
            category: .notificationDebug
        )
        presentMessagePlaceholderIfNeeded()

        messageToShow(isNotification: true, node: node) { [weak self] message in
            SystemLogger.log(
                message: "Finished fetching msg: message id is: \(message?.messageID.rawValue ?? "Nil")",
                category: .notificationDebug
            )
            guard let self, let message else {
                self?.viewController?.navigationController?.popViewController(animated: true)
                L10n.Error.cant_open_message.alertToastBottom()
                return
            }
            let messageID = message.messageID
            switch self.viewModel.locationViewMode {
            case .singleMessage:
                SystemLogger.log(
                    message: "Display notification in single message mode. id: \(messageID)",
                    category: .notificationDebug
                )
                self.presentPageViewsFor(message: message)
            case .conversation:
                SystemLogger.log(
                    message: "Start fetching conversation for msg id: \(messageID)",
                    category: .notificationDebug
                )
                self.conversationToShow(isNotification: true, message: message) { [weak self] conversation in
                    SystemLogger.log(
                        message: "Finished fetching conversation: conv id is: \(conversation?.conversationID.rawValue ?? "Nil")",
                        category: .notificationDebug
                    )
                    guard let conversation = conversation else {
                        self?.viewController?.navigationController?.popViewController(animated: true)
                        L10n.Error.cant_open_message.alertToastBottom()
                        return
                    }

                    SystemLogger.log(
                        message: "Display notification in conversation mode. msg id: \(messageID), conv id: \(conversation.conversationID.rawValue)",
                        category: .notificationDebug
                    )
                    self?.presentPageViewsFor(conversation: conversation, targetID: messageID)
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
            guard let conversation = self?.contextProvider.read(block: { context in
                if let conversation = Conversation.conversationForConversationID(
                    conversationID.rawValue,
                    inManagedObjectContext: context
                ) {
                    return ConversationEntity(conversation)
                } else {
                    return nil
                }
            }) else {
                completion(nil)
                return
            }
            completion(conversation)
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
        viewModel.user.messageService.fetchNotificationMessageDetail(MessageID(messageID)) { result in
            switch result {
            case .success(let message):
                completion(message)
            case .failure(let error):
                SystemLogger.log(message: "\(error)", isError: true)
                completion(nil)
            }
        }
    }

    private func presentPageViewsFor(message: MessageEntity) {
        viewController?.loadViewIfNeeded()

        let pageVM = MessagePagesViewModel(
            initialID: message.messageID,
            isUnread: viewController?.isShowingUnreadMessageOnly ?? false,
            labelID: viewModel.labelID,
            user: viewModel.user,
            userIntroduction: dependencies.userCachedStatus,
            goToDraft: { [weak self] msgID, originalScheduledTime in
                self?.editScheduleMsg(messageID: msgID, originalScheduledTime: originalScheduledTime)
            }
        )

        presentPageViews(pageVM: pageVM)
    }

    private func presentPageViewsFor(conversation: ConversationEntity, targetID: MessageID?) {
        let pageVM = ConversationPagesViewModel(
            initialID: conversation.conversationID,
            isUnread: viewController?.isShowingUnreadMessageOnly ?? false,
            labelID: viewModel.labelID,
            user: viewModel.user,
            targetMessageID: targetID,
            userIntroduction: dependencies.userCachedStatus,
            goToDraft: { [weak self] msgID, originalScheduledTime in
                self?.editScheduleMsg(messageID: msgID, originalScheduledTime: originalScheduledTime)
            }
        )
        presentPageViews(pageVM: pageVM)
    }

    private func presentPageViews<T, U, V>(pageVM: PagesViewModel<T, U, V>) {
        guard let navigationController = viewController?.navigationController else {
            SystemLogger.log(
                message: "Can not find the navigation view to show the swiping detail view.",
                category: .notificationDebug
            )
            return
        }
        var viewControllers = navigationController.viewControllers
        // if a placeholder VC is there, it has been presented with a push animation; avoid doing a 2nd one
        let animated = !(viewControllers.last is MessagePlaceholderVC)
        viewControllers.removeAll { !($0 is MailboxViewController) }
        let page = PagesViewController(viewModel: pageVM, dependencies: dependencies)
        viewControllers.append(page)
        navigationController.setViewControllers(viewControllers, animated: animated)
    }

    private func presentMessagePlaceholderIfNeeded() {
        guard let navigationController = viewController?.navigationController,
              !navigationController.viewControllers.contains(where: { $0 is MessagePlaceholderVC }) else { return }
        let placeholder = MessagePlaceholderVC()
        navigationController.pushViewController(placeholder, animated: true)
    }

    private func presentReferAFriend() {
        guard let referralLink = viewController?.viewModel.user.userInfo.referralProgram?.link else {
            return
        }
        let view = ReferralShareViewController(
            referralLink: referralLink
        )
        let navigation = UINavigationController(rootViewController: view)
        navigation.modalPresentationStyle = .fullScreen
        viewController?.present(navigation, animated: true)
    }

    private func resetNavigationViewControllersIfNeeded() {
        if let viewStack = viewController?.navigationController?.viewControllers,
           viewStack.count > 1,
           let firstVC = viewStack.first {
            viewController?.navigationController?.setViewControllers([firstVC], animated: false)
        }
    }

    private func navigateToSettings(destination: SettingsDeviceCoordinator.Destination?) {
        let settingsNavController = UINavigationController()
        settingsNavController.modalPresentationStyle = .fullScreen

        let settings = SettingsDeviceCoordinator(
            navigationController: settingsNavController,
            dependencies: dependencies.user.container
        )
        settings.start()
        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        settingsNavController.viewControllers.first?.navigationItem.backBarButtonItem = backItem

        settingsDeviceCoordinator = settings

        navigation?.present(settingsNavController, animated: true)
        if let destination {
            settings.go(to: destination)
        }
    }
}

// MARK: - Snooze
extension MailboxCoordinator: SnoozeSupport {
    var conversationDataService: ConversationDataServiceProxy { viewModel.user.conversationService }

    var calendar: Calendar { LocaleEnvironment.calendar }

    var isPaidUser: Bool { viewModel.user.hasPaidMailPlan }

    var presentingView: UIView { navigation?.view ?? viewController?.view ?? UIView() }

    var snoozeConversations: [ConversationID] { viewModel.selectedConversations.map(\.conversationID) }

    var snoozeDateConfigReceiver: SnoozeDateConfigReceiver {
        let receiver = _snoozeDateConfigReceiver ?? SnoozeDateConfigReceiver(
            saveDate: { [weak self] date in
                self?.snooze(on: date)
                self?._snoozeDateConfigReceiver = nil
            }, cancelHandler: { [weak self] in
                self?._snoozeDateConfigReceiver = nil
            }, showSendInTheFutureAlertHandler: {
                L10n.Snooze.selectTimeInFuture.alertToastBottom()
            }
        )
        _snoozeDateConfigReceiver = receiver
        return receiver
    }

    var weekStart: WeekStart { viewModel.user.userInfo.weekStartValue }

    @MainActor
    func showSnoozeSuccessBanner(on date: Date) {
        guard let viewController = self.viewController else { return }
        let dateStr = PMDateFormatter.shared.stringForSnoozeTime(from: date)

        let title = String(format: L10n.Snooze.successBannerTitle, dateStr)
        let banner = PMBanner(message: title, style: PMBannerNewStyle.info)
        banner.show(at: PMBanner.onTopOfTheBottomToolBar, on: viewController)
    }

    func presentPaymentView() {
        viewController?.presentUpsellPage(entryPoint: .snooze) { [unowned self] in
            guard let viewController else {
                return
            }

            presentSnoozeConfigSheet(on: viewController, current: Date())
        }
    }
}
