//
//  SettingsCoordinator.swift
//  ProtonMail - Created on 09/08/2018.
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
import SWRevealViewController

class MenuCoordinatorNew: DefaultCoordinator {
    typealias VC = MenuViewController
    
    weak var viewController: MenuViewController?
    internal weak var lastestCoordinator: CoordinatorNew?
    let viewModel : MenuViewModel
    var services: ServiceFactory
    
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
    enum Destination : String {
        case mailbox   = "toMailboxSegue"
        case label     = "toLabelboxSegue"
        case settings  = "toSettingsSegue"
        case bugs      = "toBugsSegue"
        case contacts  = "toContactsSegue"
        case feedbacks = "toFeedbackSegue"
        case plan      = "toServicePlan"
        case bugsPop = "toBugPop"
        case accountManager = "toAccountManager"
        case addAccount = "toAddAccountSegue"
        
        init?(rawValue: String) {
            switch rawValue {
            case "toMailboxSegue", String(describing: MailboxViewController.self): self = .mailbox
            case "toLabelboxSegue": self = .label
            case "toSettingsSegue", String(describing: SettingsTableViewController.self): self = .settings
            case "toBugsSegue": self = .bugs
            case "toContactsSegue": self = .contacts
            case "toFeedbackSegue": self = .feedbacks
            case "toServicePlan": self = .plan
            case "toBugPop": self = .bugsPop
            case "toAccountManager": self = .accountManager
            case "toAddAccountSegue": self = .addAccount
            default: return nil
            }
        }
    }
    
    init(vc: MenuViewController, vm: MenuViewModel, services: ServiceFactory) {
        defer {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(performLastSegue(_:)),
                                                   name: .switchView,
                                                   object: nil)
        }
        self.viewModel = vm
        self.viewController = vc
        self.services = services
    }
    
    deinit{
        //unnecessary in newer ios versions
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func performLastSegue(_ notification: Notification) {
        if let link = notification.object as? DeepLink {
            self.follow(link)
        } else {
            self.go(to: .mailbox)
        }
    }
    
    func start() {
        self.viewController?.set(viewModel: self.viewModel)
        self.viewController?.set(coordinator: self)
    }
    
    
    private func toPlan() {
        let user = self.viewModel.currentUser!
        let nextCoordinator = StorefrontCoordinator(rvc: self.viewController?.revealViewController(), user: user)
        nextCoordinator.viewController?.viewModel = StorefrontViewModel(currentUser: user)

        nextCoordinator.start()
    }
    
    private func toInbox(labelID: String, deepLink: DeepLink) {
        //Example of deeplink without segue
        var nextVM : MailboxViewModel?
        
        guard let user = self.viewModel.currentUser else {return}
        let labelService = user.labelService
        
        if let mailbox = Message.Location(rawValue: labelID) {
            nextVM = MailboxViewModelImpl(label: mailbox, userManager: user,
                                          usersManager: self.viewModel.users,
                                          pushService: services.get(),
                                          coreDataService: services.get())
        } else if let label = labelService.label(by: labelID) {
            //shared global service need to be changed later
            if label.exclusive {
                nextVM = FolderboxViewModelImpl(label: label, userManager: user,
                                                usersManager: self.viewModel.users,
                                                pushService: services.get(),
                                                coreDataService: services.get())
            } else {
                nextVM = LabelboxViewModelImpl(label: label, userManager: user,
                                               usersManager: self.viewModel.users,
                                               pushService: services.get(),
                                               coreDataService: services.get())
            }
        }
        
        if let vm = nextVM {
            let mailbox = MailboxCoordinator(rvc: self.viewController?.revealViewController(), vm: vm, services: self.services)
            self.lastestCoordinator = mailbox
            mailbox.start()
            
            // SWRevealViewController needs about 1/2 second to finish its pushFrontViewController(_:animated:) async work
            // and we can not present modal VCs like composer or search until then
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                mailbox.follow(deepLink)
            }
        }
       
    }
    
    func follow(_ deepLink: DeepLink) {
        
        // Navigate to notification mail firstly, ignore previous deep link
        let pushService = sharedServices.get(by: PushNotificationService.self)
        guard !pushService.hasCachedLaunchOptions() else {
            pushService.processCachedLaunchOptions()
            return
        }
        
        // take first node
        var start = deepLink.popFirst
        
        // do the setup if it's setup
        if let setup = start, let dest = Setup(rawValue: setup.name) {
            switch dest {
            case .switchUser where setup.value != nil:
                // this will setup currentUser to this MenuViewModel which will transfer it down the hierarchy
                let users = services.get(by: UsersManager.self)
                guard let user = users.getUser(bySessionID: setup.value!) else {
                    break
                }
                users.active(uid: setup.value!)
                self.viewModel.currentUser = user
                
            case .switchUserFromNotification where setup.value != nil:
                let users = services.get(by: UsersManager.self)
                guard let user = users.getUser(bySessionID: setup.value!) else {
                    break
                }
                
                users.active(uid: setup.value!)
                let isSameUser = self.viewModel.currentUser?.userinfo.userId ?? "" == user.userinfo.userId 
                self.viewModel.currentUser = user
                
                if !isSameUser {
                    String(format: LocalString._switch_account_by_click_notification,
                           user.defaultEmail).alertToastBottom()
                }
            default: break
            }
            // and clear it
            start = nil
        }
        
        // start will be cleared if it was a setup and then we'll need to take next node
        // or start will be already that first node if it was not a setup
        if let path = start ?? deepLink.popFirst, let dest = Destination(rawValue: path.name) {
            switch dest {
            case .plan:
                self.toPlan()
            case .mailbox where path.value != nil:
                self.toInbox(labelID: path.value!, deepLink: deepLink)
            default:
                self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: deepLink)
            }
        }
    }

    //old one call from vc
    func go(to dest: Destination, sender: Any? = nil) {
        switch dest {
        case .plan:
            self.toPlan()
        default:
            self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: sender)
        }
    }
    
    ///TODO::fixme. add warning or error when return false except the last one.
    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {        
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false //
        }
        
        let navigation = destination as? UINavigationController
        guard let rvc = source.revealViewController() else {
            return false
        }
        
        //Inactive nsfetchcontroller while last view entering background
        let lastFrontVC = (rvc.frontViewController as? UINavigationController)?.firstViewController()
        if let vc = lastFrontVC as? MailboxViewController {
            vc.inactiveViewModel()
        }
        
        switch dest {
        case .mailbox:
            guard let next = navigation?.firstViewController() as? MailboxViewController else {
                return false
            }
            sharedVMService.mailbox(fromMenu: next)
            var label = Message.Location.inbox
            if let index = sender as? Message.Location {
                label = index
            }
            guard let user = self.viewModel.currentUser else {
                return false
            }
            let viewModel = MailboxViewModelImpl(label: label, userManager: user, usersManager: self.viewModel.users, pushService: services.get(), coreDataService: services.get())
            let mailbox = MailboxCoordinator(rvc: rvc, nav: navigation, vc: next, vm: viewModel, services: self.services)
            self.lastestCoordinator = mailbox
            mailbox.start()
            if let deeplink = sender as? DeepLink {
                mailbox.follow(deeplink)
            }
            
        case .label:
            guard let next = navigation?.firstViewController() as? MailboxViewController else {
                return false
            }
            sharedVMService.mailbox(fromMenu: next)
            let user = self.viewModel.currentUser!
            
            var viewModel : MailboxViewModel = MailboxViewModelImpl(label: Message.Location.inbox,
                                                                    userManager: user,
                                                                    usersManager: self.viewModel.users,
                                                                    pushService: services.get(),
                                                                    coreDataService: services.get())
            
            if let label = sender as? Label {
                if label.exclusive {
                    viewModel = FolderboxViewModelImpl(label: label, userManager: user,
                                                       usersManager: self.viewModel.users,
                                                       pushService: services.get(),
                                                       coreDataService: services.get())
                } else {
                    viewModel = LabelboxViewModelImpl(label: label, userManager: user,
                                                      usersManager: self.viewModel.users,
                                                      pushService: services.get(),
                                                      coreDataService: services.get())
                }
            }
            let mailbox = MailboxCoordinator(rvc: rvc, nav: navigation, vc: next, vm: viewModel, services: self.services)
            self.lastestCoordinator = mailbox
            mailbox.start()
            if let deeplink = sender as? DeepLink {
                mailbox.follow(deeplink)
            }
            
        case .settings:
            guard let next = navigation else {
                return false
            }
            
            guard  let user = self.viewModel.currentUser else {
                return false
            }
            let vm = SettingsDeviceViewModelImpl(user: user)
            guard let settings = SettingsDeviceCoordinator(rvc: rvc, nav: next,
                                                           vm: vm, services: self.services, scene: nil) else {
                return false
            }
            settings.start()
            if let deeplink = sender as? DeepLink {
                settings.follow(deeplink)
            }
        case .contacts:
            guard let tabBarController = destination as? ContactTabBarViewController else {
                return false
            }
            let user = self.viewModel.currentUser!
            let contacts = ContactTabBarCoordinator(rvc: rvc, vc: tabBarController, services: self.services, user: user)
            contacts.start()
        case .bugs, .feedbacks:
            ///those two types use the default segue
            break
        case .plan:
            /// this handled in go function.
            break
        case .bugsPop:
            return true
        case .accountManager:
            guard let next = navigation else {
                return false
            }
            let vm = AccountManagerViewModel(usersManager: self.services.get())
            guard let accoutManager = AccountManagerCoordinator(nav: next, vm: vm, services: self.services, scene: nil) else {
                return false
            }
            accoutManager.delegate = self
            accoutManager.start()
            return true
        case .addAccount:
            guard let next = navigation else {
                return false
            }
            
            let preFilledUsername = (sender as? UsersManager.DisconnectedUserHandle)?.defaultEmail
            guard let account = AccountConnectCoordinator(nav: next,
                                                          vm: SignInViewModel(usersManager: self.services.get(), username: preFilledUsername),
                                                          services: self.services) else {
                return false
            }
            account.delegate = self
            account.start()
            return true
        }
        
        return false
    }
}

extension MenuCoordinatorNew : CoordinatorDelegate {
    func willStop(in coordinator: CoordinatorNew) {
        
    }
    
    func didStop(in coordinator: CoordinatorNew) {
        self.viewController?.updateUser()
    }
}
