//
//  MailboxCoordinator.swift.swift
//  ProtonMail - Created on 12/10/18.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import SideMenuSwift

class MailboxCoordinator: DefaultCoordinator, CoordinatorDismissalObserver {
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

    weak var delegate: CoordinatorDelegate?

    enum Destination: String {
        case composer = "toCompose"
        case composeShow = "toComposeShow"
        case composeMailto = "toComposeMailto"
        case search = "toSearchViewController"
        case details = "SingleMessageViewController"
        case onboarding = "to_onboarding_segue"
        case feedback = "to_feedback_segue"
        case feedbackView = "to_feedback_view_segue"
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
            case "to_onboarding_segue":
                self = .onboarding
            case "to_feedback_segue":
                self = .feedback
            case "to_feedback_view_segue":
                self = .feedbackView
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

    func navigate(from source: UIViewController,
                  to destination: UIViewController,
                  with identifier: String?,
                  and sender: AnyObject?) -> Bool {
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false
        }

        switch dest {
        case .details:
            break
        case .composer:
            guard let nav = destination as? UINavigationController,
                  let next = nav.viewControllers.first as? ComposeContainerViewController
            else {
                return false
            }
            navigateToComposer(nextViewController: next)
        case .composeShow, .composeMailto:
            self.viewController?.cancelButtonTapped()

            guard let nav = destination as? UINavigationController,
                  let next = nav.viewControllers.first as? ComposeContainerViewController,
                  let message = sender as? Message
            else {
                return false
            }

            navigateToCompose(message: message, nextViewController: next)
        case .humanCheck:
            guard let next = destination as? MailboxCaptchaViewController else {
                return false
            }
            let user = self.viewModel.user
            next.viewModel = CaptchaViewModelImpl(api: user.apiService)
            next.delegate = self.viewController
        case .troubleShoot:
            guard let nav = destination as? UINavigationController else {
                return false
            }

            let tsVC = NetworkTroubleShootCoordinator(segueNav: nav,
                                                      vm: NetworkTroubleShootViewModelImpl(),
                                                      services: services)
            tsVC.start()
        case .feedback, .feedbackView:
            return false
        case .search:
            guard let next = (destination as? UINavigationController)?.viewControllers.first as? SearchViewController else {
                return false
            }
            let viewModel = SearchViewModel(user: self.viewModel.user,
                                            coreDataContextProvider: self.services.get(by: CoreDataService.self), uiDelegate: next)
            next.set(viewModel: viewModel)
        case .newFolder, .newLabel, .onboarding:
            break
        }
        return true
    }

    func go(to dest: Destination, sender: Any? = nil) {
        switch dest {
        case .details:
            self.viewModel.locationViewMode == .conversation ? self.presentConversation() : self.presentSingleMessage()
        case .newFolder:
            self.presentCreateFolder(type: .folder)
        case .newLabel:
            presentCreateFolder(type: .label)
        case .onboarding:
            let viewController = OnboardViewController()
            viewController.modalPresentationStyle = .fullScreen
            self.viewController?.present(viewController, animated: true, completion: nil)
        default:
            guard let viewController = self.viewController else { return }
            if let presented = viewController.presentedViewController {
                presented.dismiss(animated: false) { [weak self] in
                    self?.viewController?.performSegue(withIdentifier: dest.rawValue, sender: sender)
                }
            } else {
                self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: sender)
            }
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

            followToDetails(message: message,
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
        let composerViewModel = ComposeContainerViewModel(editorViewModel: viewModel, uiDelegate: nil)
        let composer = ComposeContainerViewCoordinator(nav: navigationVC,
                                                       viewModel: composerViewModel,
                                                       services: services)
        composer.start()
        composer.follow(deepLink)
    }

    private func presentCreateFolder(type: PMLabelType) {
        let user = self.viewModel.user
        let coreDataService = self.services.get(by: CoreDataService.self)
        let folderLabels = user.labelService.getMenuFolderLabels(context: coreDataService.mainContext)
        let labelEditViewModel = LabelEditViewModel(user: user, label: nil, type: type, labels: folderLabels)
        let labelEditViewController = LabelEditViewController.instance()
        let coordinator = LabelEditCoordinator(services: self.services,
                                               viewController: labelEditViewController,
                                               viewModel: labelEditViewModel,
                                               coordinatorDismissalObserver: self)
        coordinator.start()
        // We want to call back when navController is dismissed to show sheet again
        if let navigation = labelEditViewController.navigationController {
            self.viewController?.navigationController?.present(navigation, animated: true, completion: nil)
        }
    }

    private func presentSingleMessage() {
        guard let indexPathForSelectedRow = self.viewController?.tableView.indexPathForSelectedRow,
              let message = self.viewModel.item(index: indexPathForSelectedRow),
              let navigationController = viewController?.navigationController else { return }
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
              let conversation = viewModel.itemOfConversation(index: selectedRowIndexPath) else { return }
        let coordinator = ConversationCoordinator(
            labelId: viewModel.labelID,
            navigationController: navigationController,
            conversation: conversation,
            user: self.viewModel.user
        )
        conversationCoordinator = coordinator
        coordinator.start()
    }

    private func navigateToComposer(nextViewController next: ComposeContainerViewController) {
        let user = self.viewModel.user
        let viewModel = ContainableComposeViewModel(msg: nil,
                                                    action: .newDraft,
                                                    msgService: user.messageService,
                                                    user: user,
                                                    coreDataContextProvider: contextProvider)
        next.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel, uiDelegate: next))
        next.set(coordinator: ComposeContainerViewCoordinator(controller: next))
    }

    private func navigateToCompose(message: Message, nextViewController next: ComposeContainerViewController) {
        let user = self.viewModel.user
        let viewModel = ContainableComposeViewModel(msg: message,
                                                    action: .openDraft,
                                                    msgService: user.messageService,
                                                    user: user,
                                                    coreDataContextProvider: contextProvider)
        next.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel, uiDelegate: next))
        next.set(coordinator: ComposeContainerViewCoordinator(controller: next))
    }

    private func followToDetails(message: Message,
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

    func fetchConversationFromBEIfNeeded(conversationID: String, goToDetailPage: @escaping () -> Void) {
        guard internetStatusProvider.currentStatus != .NotReachable else {
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

    private func showConversationView(conversationID: String,
                                      contextProvider: CoreDataContextProviderProtocol,
                                      navigationController: UINavigationController,
                                      targetID: String?) {
        if let conversation = Conversation
            .conversationForConversationID(conversationID,
                                           inManagedObjectContext: contextProvider.mainContext) {
            let coordinator = ConversationCoordinator(labelId: self.viewModel.labelID,
                                                      navigationController: navigationController,
                                                      conversation: conversation,
                                                      user: self.viewModel.user,
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
            let containerViewModel = ComposeContainerViewModel(editorViewModel: viewModel, uiDelegate: nil)
            let composer = ComposeContainerViewCoordinator(nav: nav,
                                                           viewModel: containerViewModel,
                                                           services: services)
            composer.start()
            composer.follow(deeplink)
        }
    }
}
