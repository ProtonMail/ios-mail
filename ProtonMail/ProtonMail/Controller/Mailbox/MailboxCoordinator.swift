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

import Foundation
import ProtonMailAnalytics
import SideMenuSwift

class MailboxCoordinator: CoordinatorDismissalObserver {
    typealias VC = MailboxViewController

    let viewModel: MailboxViewModel
    var services: ServiceFactory
    private let contextProvider: CoreDataContextProviderProtocol
    private let internetStatusProvider: InternetConnectionStatusProvider

    weak var viewController: MailboxViewController?
    private weak var navigation: UINavigationController?
    private weak var sideMenu: SideMenuController?
    var pendingActionAfterDismissal: (() -> Void)?
    private(set) var singleMessageCoordinator: SingleMessageCoordinator?
    private(set) var conversationCoordinator: ConversationCoordinator?
    private let getApplicationState: () -> UIApplication.State

    init(sideMenu: SideMenuController?,
         nav: UINavigationController?,
         viewController: MailboxViewController,
         viewModel: MailboxViewModel,
         services: ServiceFactory,
         contextProvider: CoreDataContextProviderProtocol,
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
    }

    enum Destination: String {
        case composer = "toCompose"
        case composeShow = "toComposeShow"
        case composeMailto = "toComposeMailto"
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
            self.viewModel.locationViewMode == .conversation ? self.presentConversation() : self.presentSingleMessage()
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
            guard let messageId = path.value,
                  let message = viewModel.user.messageService.fetchMessages(
                      withIDs: [messageId],
                      in: contextProvider.mainContext
                  ).first,
                  let navigationController = viewController?.navigationController else { return }

            let messageEntity = MessageEntity(message)
            let breadcrumbMsg = """
                follow deeplink (receivedMsgId: \(messageId),\
                msgId: \(messageEntity.messageID.rawValue),\
                convId: \(messageEntity.conversationID.rawValue)
                """
            Breadcrumbs.shared.add(message: breadcrumbMsg, to: .malformedConversationRequest)

            followToDetails(message: messageEntity,
                            navigationController: navigationController,
                            deeplink: deeplink)

            self.viewModel.resetNotificationMessage()
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

    private func presentSingleMessage() {
        guard let indexPathForSelectedRow = self.viewController?.tableView.indexPathForSelectedRow,
              let message = self.viewModel.item(index: indexPathForSelectedRow),
              let navigationController = viewController?.navigationController
        else { return }
        let coordinator = SingleMessageCoordinator(
            navigationController: navigationController,
            labelId: viewModel.labelID,
            message: message,
            user: self.viewModel.user
        )
        singleMessageCoordinator = coordinator
        coordinator.start()
    }

    private func presentConversation() {
        guard let navigationController = viewController?.navigationController,
              let selectedRowIndexPath = viewController?.tableView.indexPathForSelectedRow,
              let conversation = viewModel.itemOfConversation(index: selectedRowIndexPath)
        else { return }
        let coordinator = ConversationCoordinator(
            labelId: viewModel.labelID,
            navigationController: navigationController,
            conversation: conversation,
            user: self.viewModel.user,
            internetStatusProvider: services.get(by: InternetConnectionStatusProvider.self)
        )
        conversationCoordinator = coordinator
        coordinator.start()
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

    private func navigateToComposer(existingMessage: Message?) {
        let user = self.viewModel.user
        let viewModel = ContainableComposeViewModel(msg: existingMessage,
                                                    action: existingMessage == nil ? .newDraft : .openDraft,
                                                    msgService: user.messageService,
                                                    user: user,
                                                    coreDataContextProvider: contextProvider)
        let composer = ComposeContainerViewCoordinator(presentingViewController: self.viewController,
                                                       editorViewModel: viewModel)
        composer.start()
    }

    private func presentSearch() {
        let viewModel = SearchViewModel(user: self.viewModel.user,
                                        coreDataContextProvider: self.services.get(by: CoreDataService.self))
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

    private func followToDetails(message: MessageEntity,
                                 navigationController: UINavigationController,
                                 deeplink: DeepLink?) {
        switch self.viewModel.locationViewMode {
        case .conversation:
            let targetID = message.messageID
            fetchConversationFromBEIfNeeded(conversationID: message.conversationID) { [weak self] in
                guard let self = self else { return }
                self.showConversationView(conversationID: message.conversationID,
                                          contextProvider: self.contextProvider,
                                          navigationController: navigationController,
                                          targetID: targetID)
            }
        case .singleMessage:
            let coordinator = SingleMessageCoordinator(
                navigationController: navigationController,
                labelId: viewModel.labelID,
                message: message,
                user: self.viewModel.user
            )
            coordinator.start()
            if let link = deeplink {
                coordinator.follow(link)
            }
        }
    }

    func fetchConversationFromBEIfNeeded(conversationID: ConversationID, goToDetailPage: @escaping () -> Void) {
        guard internetStatusProvider.currentStatus != .notConnected else {
            goToDetailPage()
            return
        }

        viewController?.showProgressHud()
        viewModel.fetchConversationDetail(conversationID: conversationID) { [weak self] _ in
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

    private func showConversationView(conversationID: ConversationID,
                                      contextProvider: CoreDataContextProviderProtocol,
                                      navigationController: UINavigationController,
                                      targetID: MessageID?) {
        if let conversation = Conversation
            .conversationForConversationID(conversationID.rawValue,
                                           inManagedObjectContext: contextProvider.mainContext) {
            let entity = ConversationEntity(conversation)
            let coordinator = ConversationCoordinator(
                labelId: self.viewModel.labelID,
                navigationController: navigationController,
                conversation: entity,
                user: self.viewModel.user,
                internetStatusProvider: services.get(by: InternetConnectionStatusProvider.self),
                targetID: targetID)
            coordinator.start(openFromNotification: true)
        }
    }

    private func followToComposeMailTo(path: String?, deeplink: DeepLink) {
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
}
