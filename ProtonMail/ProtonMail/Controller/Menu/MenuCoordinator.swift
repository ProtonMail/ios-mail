//
//  MenuViewController.swift
//  ProtonMail
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
import ProtonCore_AccountSwitcher
import ProtonCore_Networking
import ProtonCore_PaymentsUI

final class MenuCoordinator: DefaultCoordinator, CoordinatorDismissalObserver {
    
    enum Setup: String {
        case switchUser = "USER"
        case switchUserFromNotification = "UserFromNotification"
        init?(rawValue: String) {
            switch rawValue {
            case "USER": self = .switchUser
            case "UserFromNotification": self = .switchUserFromNotification
            default: return nil
            }
        }
    }

    typealias VC = MenuViewController
    weak var viewController: VC?
    private let menuWidth: CGFloat
    private let vm: MenuVMProtocol
    let services: ServiceFactory
    private let vmService: ViewModelService
    private let pushService: PushNotificationService
    private let coreDataService: CoreDataService
    private let lastUpdatedStore:LastUpdatedStoreProtocol
    private let usersManager: UsersManager
    var pendingActionAfterDismissal: (() -> Void)?

    // todo: that would be better if vc is protocol
    init(services: ServiceFactory,
         vmService: ViewModelService,
         pushService: PushNotificationService,
         coreDataService: CoreDataService,
         lastUpdatedStore:LastUpdatedStoreProtocol,
         usersManager: UsersManager,
         vc: VC, vm: MenuVMProtocol, menuWidth: CGFloat = 327) {

        //Setup side menu setting
        SideMenuController.preferences.basic.menuWidth = menuWidth
        SideMenuController.preferences.basic.position = .sideBySide
        SideMenuController.preferences.basic.enablePanGesture = true
        SideMenuController.preferences.basic.enableRubberEffectWhenPanning = false
        SideMenuController.preferences.animation.shouldAddShadowWhenRevealing = true
        SideMenuController.preferences.animation.shadowColor = .black
        SideMenuController.preferences.animation.shadowAlpha = 0.52
        SideMenuController.preferences.animation.revealDuration = 0.25
        SideMenuController.preferences.animation.hideDuration = 0.25
        self.menuWidth = menuWidth
        
        self.services = services
        self.coreDataService = coreDataService
        self.vmService = vmService
        self.pushService = pushService
        self.lastUpdatedStore = lastUpdatedStore
        self.usersManager = usersManager
        self.viewController = vc
        
        self.vm = vm
    }
    
    func start() {
        self.viewController?.set(vm: self.vm, coordinator: self)
        self.vm.set(menuWidth: self.menuWidth)
    }
    
    func follow(_ deepLink: DeepLink) {
        if self.pushService.hasCachedLaunchOptions() {
            pushService.processCachedLaunchOptions()
            return
        }
        var start = deepLink.popFirst
        start = self.processUserInfoIn(node: start)
        
        guard let path = start ?? deepLink.popFirst,
              let label = MenuCoordinator.getLocation(by: path.name, value: path.value) else {
            return
        }
        
        self.go(to: label, deepLink: deepLink)
    }
    
    func go(to labelInfo: MenuLabel, deepLink: DeepLink?=nil) {
        switch labelInfo.location {
        case .customize(_):
            self.handleCustomLabel(labelInfo: labelInfo, deepLink: deepLink)
        case .inbox, .draft, .sent, .starred, .archive, .spam, .trash, .allmail:
            self.navigateToMailBox(labelInfo: labelInfo, deepLink: deepLink)
        case .subscription:
            self.navigateToSubscribe()
        case .settings:
            self.navigateToSettings(deepLink: deepLink)
        case .contacts:
            self.navigateToContact()
        case .bugs:
            self.navigateToBugReport()
        case .accountManger:
            self.navigateToAccountManager()
        case .addAccount:
            let mail = labelInfo.name
            self.navigateToAddAccount(mail: mail)
        case .addLabel:
            self.navigateToCreateFolder(type: .label)
        case .addFolder:
            self.navigateToCreateFolder(type: .folder)
        case .provideFeedback:
            self.navigateToMailBox(labelInfo: MenuLabel(location: .inbox), deepLink: deepLink, showFeedbackActionSheet: true)
        default:
            break
        }
        self.vm.highlight(label: labelInfo)
    }
}

// MARK: helper function
extension MenuCoordinator {
    /// If the node contain user info return `nil` after processed
    private func processUserInfoIn(node: DeepLink.Node?) -> DeepLink.Node? {
        guard let setup = node,
              let dest = Setup(rawValue: setup.name),
              let sessionID = setup.value else {
            return node
        }
        
        guard let user = self.usersManager.getUser(bySessionID: sessionID) else {
            return node
        }
        
        switch dest {
        case .switchUser:
            self.usersManager.active(uid: sessionID)
        case .switchUserFromNotification:
            let isAnotherUser = self.usersManager.firstUser?.userinfo.userId ?? "" != user.userinfo.userId
            self.usersManager.active(uid: sessionID)
            // viewController?.setupLabelsIfViewIsLoaded()
            // rebase todo, check MR 496
            if isAnotherUser {
                String(format: LocalString._switch_account_by_click_notification,
                       user.defaultEmail).alertToastBottom()
            }
        }
        self.vm.userDataInit()
        return nil
    }
    
    // If SignInCoordinator.swift doesn't use this function anymore
    // set this function as private function
    class func getLocation(by path: String, value: String?) -> MenuLabel? {
        switch path {
        case "toMailboxSegue",
             "toLabelboxSegue",
             String(describing: MailboxViewController.self):
            let value = value ?? "0"
            let location = LabelLocation(id: value)
            return MenuLabel(location: location)
        case "toSettingsSegue",
             String(describing: SettingsTableViewController.self):
            return MenuLabel(location: .settings)
        case "toBugsSegue": return MenuLabel(location: .bugs)
        case "toContactsSegue": return MenuLabel(location: .contacts)
        case "toServicePlan",
             "Subscription":
            return MenuLabel(location: .subscription)
        case "toBugPop": return MenuLabel(location: .bugs)
        case "toAccountManager": return MenuLabel(location: .customize("toAccountManager"))
        case "toAddAccountSegue": return MenuLabel(location: .customize("toAddAccountSegue"))
        case .skeletonTemplate: return MenuLabel(location: .customize(.skeletonTemplate))
        default: return nil
        }
    }
    
    private func setupContentVC(destination: UIViewController) {
        guard let sideMenu = self.viewController?.sideMenuController else {
            return
        }
        sideMenu.setContentViewController(to: destination)
        sideMenu.hideMenu(animated: true, completion: nil)
    }
    
    private func queryLabel(id: String) -> Label? {
        guard let user = self.usersManager.firstUser else {
            return nil
        }
        let labelService = user.labelService
        let label = labelService.label(by: id)
        return label
    }
}

// MARK: Navigation
extension MenuCoordinator {
    func handleSwitchView(deepLink: DeepLink?) {
        if let deepLink = deepLink {
            follow(deepLink)
        } else {
            // There is no previous states , navigate to inbox
            presentInitialPage()
        }
    }

    private func presentInitialPage() {
        let label = MenuLabel(location: .inbox)
        navigateToMailBox(labelInfo: label, deepLink: nil)
    }
    
    private func handleCustomLabel(labelInfo: MenuLabel, deepLink: DeepLink?) {
        if case .customize(let id) = labelInfo.location {
            if id == .skeletonTemplate {
                self.navigateToSkeletonVC()
            } else {
                self.navigateToMailBox(labelInfo: labelInfo, deepLink: deepLink)
            }
        }
    }
    
    private func navigateToMailBox(labelInfo: MenuLabel, deepLink: DeepLink?, showFeedbackActionSheet: Bool = false) {
        guard !scrollToLatestMessageInConversationViewIfPossible(deepLink) else {
            return
        }

        let vc = MailboxViewController.instance()
        vc.shouldShowFeedbackActionSheet = showFeedbackActionSheet
        self.vmService.mailbox(fromMenu: vc)
        
        guard let user = self.usersManager.firstUser,
              let navigation = vc.navigationController else {
            return
        }
        var viewModel: MailboxViewModel
        switch labelInfo.location {
        case .customize(let id):
            if labelInfo.type == .folder,
               let label = self.queryLabel(id: id) {
                viewModel = FolderboxViewModelImpl(label: label, userManager: user,
                                                   usersManager: self.usersManager,
                                                   pushService: self.pushService,
                                                   coreDataService: self.coreDataService,
                                                   lastUpdatedStore: self.lastUpdatedStore,
                                                   queueManager: self.services.get(by: QueueManager.self))
            } else if labelInfo.type == .label,
                      let label = self.queryLabel(id: id) {
                viewModel = LabelboxViewModelImpl(label: label, userManager: user,
                                                  usersManager: self.usersManager,
                                                  pushService: self.pushService,
                                                  coreDataService: self.coreDataService,
                                                  lastUpdatedStore: self.lastUpdatedStore,
                                                  queueManager: self.services.get(by: QueueManager.self))
            } else {
                // the type is unknown or the label doesn't exist
                return
            }
        case .inbox, .draft, .sent, .starred, .archive, .spam, .trash, .allmail:
            let msgLocation = labelInfo.location.toMessageLocation
            viewModel = MailboxViewModelImpl(label: msgLocation,
                                             userManager: user,
                                             usersManager: self.usersManager,
                                             pushService: self.pushService,
                                             coreDataService: self.coreDataService,
                                             lastUpdatedStore: self.lastUpdatedStore,
                                             queueManager: self.services.get(by: QueueManager.self))
        default: return
        }
        
        let mailbox = MailboxCoordinator(sideMenu: self.viewController?.sideMenuController, nav: navigation, viewController: vc, viewModel: viewModel, services: self.services)
        mailbox.start()
        if let deeplink = deepLink {
            mailbox.follow(deeplink)
        }
        self.setupContentVC(destination: navigation)
    }
    
    private func navigateToSubscribe() {
        guard let user = self.usersManager.firstUser,
              let sideMenuViewController = viewController?.sideMenuController else { return }
        let paymentsUI = PaymentsUI(payments: user.payments)
        let coordinator = StorefrontCoordinator(
            paymentsUI: paymentsUI,
            sideMenu: sideMenuViewController,
            eventsService: user.eventsService
        )
        coordinator.start()
    }
    
    private func navigateToSettings(deepLink: DeepLink?) {
        let vc = SettingsDeviceViewController.instance()
        guard let user = self.usersManager.firstUser,
              let navigation = vc.navigationController else {
            return
        }
        let vm = SettingsDeviceViewModelImpl(user: user,
                                             users: self.usersManager,
                                             dohSetting: DoHMail.default,
                                             biometricStatus: UIDevice.current)
        guard let settings = SettingsDeviceCoordinator(sideMenu: self.viewController?.sideMenuController,
                                                       nav: navigation,
                                                       vm: vm,
                                                       services: self.services,
                                                       scene: nil) else {
            return
        }
        settings.start()
        if let deeplink = deepLink {
            settings.follow(deeplink)
        }
        self.setupContentVC(destination: navigation)
    }
    
    private func navigateToContact() {
        let vc = ContactTabBarViewController.instance()
        guard let user = self.usersManager.firstUser else {
            return
        }
        let contacts = ContactTabBarCoordinator(sideMenu: self.viewController?.sideMenuController,
                                                vc: vc,
                                                services: self.services,
                                                user: user)
        contacts.start()
        self.setupContentVC(destination: vc)
    }
    
    private func navigateToBugReport() {
        let vc = ReportBugsViewController.instance()
        guard let user = self.usersManager.firstUser,
              let navigation = vc.navigationController else {
            return
        }
        vc.user = user
        vm.highlight(label: MenuLabel(location: .bugs))
        self.setupContentVC(destination: navigation)
    }
    
    private func navigateToAccountManager() {
        guard let menuVC = self.viewController else {
            return
        }
        
        let vc = AccountManagerVC.instance()
        let list = self.vm.getAccountList()
        let vm = AccountManagerViewModel(accounts: list, uiDelegate: vc)
        vm.set(delegate: menuVC)
        guard let nav = vc.navigationController,
              let sideMenu = self.viewController?.sideMenuController else {
            return
        }
        
        sideMenu.present(nav, animated: true) {
            sideMenu.hideMenu()
        }
    }
    
    private func navigateToAddAccount(mail: String) {

        guard let sideMenu = self.viewController?.sideMenuController else { return }

        let signInEnvironment = SignInCoordinatorEnvironment.live(
            services: sharedServices, forceUpgradeDelegate: ForceUpgradeManager.shared.forceUpgradeHelper
        )

        let coordinator: SignInCoordinator = .loginFlowForSecondAndAnotherAccount(
            username: mail.isEmpty ? nil : mail, environment: signInEnvironment
        ) { [weak self] result in
            switch result {
            case .succeeded:
                sideMenu.dismiss(animated: false, completion: nil)
            case .loggedInFreeAccountsLimitReached:
                sideMenu.dismiss(animated: false, completion: nil)
            case .alreadyLoggedIn:
                sideMenu.dismiss(animated: false, completion: nil)
            case .userWantsToGoToTroubleshooting:
                sideMenu.dismiss(animated: false) { [weak self] in self?.navigateToTroubleshooting() }
            case .errored:
                sideMenu.dismiss(animated: false) { [weak self] in self?.navigateToAccountManager() }
            case .dismissed:
                sideMenu.dismiss(animated: false) { [weak self] in self?.navigateToAccountManager() }
            }
        }
        coordinator.delegate = self
        let vc = coordinator.actualViewController
        vc.modalPresentationStyle = .overCurrentContext
        sideMenu.present(vc, animated: false) {
            sideMenu.hideMenu()
            coordinator.start()
        }
    }

    private func navigateToTroubleshooting() {
        let troubleshootingVC = UIStoryboard.Storyboard.alert.storyboard.make(NetworkTroubleShootViewController.self)
        troubleshootingVC.onDismiss = { [weak self] in
            self?.navigateToAccountManager()
        }
        let navigationVC = UINavigationController(rootViewController: troubleshootingVC)
        navigationVC.modalPresentationStyle = .fullScreen
        guard let sideMenu = self.viewController?.sideMenuController else {
            return
        }
        sideMenu.present(navigationVC, animated: true) {
            sideMenu.hideMenu()
        }
    }
    
    private func navigateToCreateFolder(type: PMLabelType) {
        guard let user = self.vm.currentUser else { return }
        var folders = self.vm.folderItems
        if folders.count == 1,
           let first = folders.first,
           first.location == .addFolder {
            folders = []
        }
        let vm = LabelEditViewModel(user: user,
                                    label: nil,
                                    type: type,
                                    labels: folders)
        let vc = LabelEditViewController.instance()
        let coordinator = LabelEditCoordinator(services: self.services,
                                               viewController: vc,
                                               viewModel: vm,
                                               coordinatorDismissalObserver: self)
        coordinator.start()
        guard let sideMenu = self.viewController?.sideMenuController,
              let nvc = vc.navigationController else { return }
        sideMenu.present(nvc, animated: true) {
            sideMenu.hideMenu()
        }
    }

    private func scrollToLatestMessageInConversationViewIfPossible(_ deepLink: DeepLink?) -> Bool {
        guard usersManager.firstUser?.conversationStateService.viewMode == .conversation,
              let deepLink = deepLink else {
            return false
        }
        //find messageId in deepLink
        var path = deepLink.first
        var messageId: String?
        while(path != nil) {
            if path?.name == "SingleMessageViewController" {
                messageId = path?.value
                break
            } else {
                path = path?.next
            }
        }

        guard let messageId = messageId,
              let message = Message.messageForMessageID(messageId, inManagedObjectContext: coreDataService.mainContext) else {
            return false
        }

        var isFound = false
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            window.enumerateViewControllerHierarchy { controller, stop in
                if let conversationVC = controller as? ConversationViewController,
                   conversationVC.viewModel.conversation.conversationID == message.conversationID {
                    conversationVC.showMessage(of: message.messageID)
                    isFound = true
                    stop = true
                }
            }
        }
        return isFound
    }

    private func navigateToSkeletonVC() {
        let skeletonVC = SkeletonViewController.instance()
        guard let navigation = skeletonVC.navigationController else { return }
        self.setupContentVC(destination: navigation)
    }
}

extension MenuCoordinator : CoordinatorDelegate {
    func willStop(in coordinator: CoordinatorNew) {
        
    }
    
    func didStop(in coordinator: CoordinatorNew) {
        guard let user = self.usersManager.firstUser else {
            return
        }
        self.vm.activateUser(id: user.userInfo.userId)
        let label = MenuLabel(location: .inbox)
        self.navigateToMailBox(labelInfo: label, deepLink: nil)
    }
}
