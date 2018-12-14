//
//  SettingsCoordinator.swift
//  ProtonMail - Created on 09/08/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import SWRevealViewController

class MenuCoordinator: Coordinator {
    func make<SomeCoordinator: Coordinator>(coordinatorFor next: MenuCoordinator.Destination) -> SomeCoordinator {
        guard next == .serviceLevel else {
            fatalError()
        }
        let nextCoordinator = ServiceLevelCoordinator(navigationController: self.navigationController)
        return nextCoordinator as! SomeCoordinator
    }
    
    weak var controller: UIViewController!
    private let navigationController = UINavigationController()
    
    enum Destination {
        case serviceLevel
    }
    
    private var observation: NSKeyValueObservation!
    func insertIntoHierarchy(_ child: UIViewController) {
        let menuButton = UIBarButtonItem(image: UIImage(named: "hamburger")!, style: .plain, target: nil, action: nil)
        self.navigationController.viewControllers = [child]
        let segue = SWRevealViewControllerSeguePushController(identifier: String(describing: type(of:child)),
                                                              source: self.controller,
                                                              destination: navigationController)
        
        observation = navigationController.observe(\UINavigationController.parent) { (controller, change) in
            ProtonMailViewController.setup(child, menuButton, true)
            self.observation = nil
        }
        
        self.controller.prepare(for: segue, sender: self)
        segue.perform()
    }
}


class MenuCoordinatorNew: DefaultCoordinator {
    typealias VC = MenuViewController
    
    weak var viewController: MenuViewController?
    
    let viewModel : MenuViewModel
    internal weak var lastestCoordinator: CoordinatorNew?
    
    enum Destination : String {
        case mailbox   = "toMailboxSegue"
        case label     = "toLabelboxSegue"
        case settings  = "toSettingsSegue"
        case bugs      = "toBugsSegue"
        case contacts  = "toContactsSegue"
        case feedbacks = "toFeedbackSegue"
        case plan      = "toServicePlan"
    }
    
    init(vc: MenuViewController, vm: MenuViewModel) {
        defer {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(performLastSegue(_:)),
                                                   name: .switchView,
                                                   object: nil)
        }
        self.viewModel = vm
        self.viewController = vc
    }
    
    deinit{
        //unnecessary in newer ios versions
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func performLastSegue(_ notification: Notification) {
        if let link = notification.object as? DeepLink {
            self.go(to: link)
        } else {
            self.go(to: .mailbox)
        }
    }
    
    func start() {
        self.viewController?.set(viewModel: self.viewModel)
        self.viewController?.set(coordinator: self)
    }
    
    func go(to dest: Destination, sender: Any? = nil) {
        switch dest {
        case .plan:
            self.toPlan()
        default:
            self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: sender)
        }
    }
    
    func toPlan() {
        let coordinator = MenuCoordinator()
        coordinator.controller = self.viewController
        coordinator.go(to: .serviceLevel, creating: ServiceLevelViewController.self)
    }
    
    func go(to deepLink: DeepLink) {
        if let path = deepLink.pop, let dest = MenuCoordinatorNew.Destination(rawValue: path.destination) {
            self.go(to: dest, sender: deepLink)
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
        
        switch dest {
        case .mailbox:
            //let index = sender as? IndexPath
            guard let next = navigation?.firstViewController() as? MailboxViewController else {
                return false
            }
            sharedVMService.mailbox(fromMenu: next)
            let viewModel = MailboxViewModelImpl(label: .inbox)
            let mailbox = MailboxCoordinator(rvc: rvc, nav: navigation, vc: next, vm: viewModel)
            mailbox.start()
        case .settings:
            guard let next = navigation?.firstViewController() as? SettingsTableViewController else {
                return false
            }
            
            let deepLink = sender as? DeepLink
            let viewModel = SettingsViewModelImpl()
            let settings = SettingsCoordinator(rvc: rvc, nav: navigation, vc: next, vm: viewModel, deeplink: deepLink)
            self.lastestCoordinator = settings
            settings.start()
        case .contacts:
            guard let tabBarController = destination as? ContactTabBarViewController else {
                return false
            }
            let contacts = ContactTabBarCoordinator(rvc: rvc, vc: tabBarController)
            contacts.start()
        default:
            return false
        }
        return false
    }
}


//        if let navigation = segue.destination as? UINavigationController {
//            let segueID = segue.identifier
//            //right now all mailbox view controller all could process together.
//            if let mailbox: MailboxViewController = navigation.firstViewController() as? MailboxViewController {
//                if let indexPath = sender as? IndexPath {
//                    let s = indexPath.section
//                    let row = indexPath.row
//                    let section = self.viewModel.section(at: s)
//                    switch section {
//                    case .inboxes:
//                        self.lastMenuItem = self.viewModel.item(inboxes: row)
//                        //TODO::fixme
//                        //sharedVMService.mailbox(fromMenu: mailbox, location: self.lastMenuItem.menuToLocation)
//                    case .labels:
//                        if  let label = self.viewModel.label(at: row) {
//                            sharedVMService.labelbox(fromMenu: mailbox, label: label)
//                        }
//                    default:
//                        break
//                    }
//                }
//            } else if (segueID == kSegueToContacts ) {
//                // setup contact group view controller
//                if let tabBarController = navigation.firstViewController() as? UITabBarController,
//                    let viewControllers = tabBarController.viewControllers {
//                    if let contactViewController = viewControllers[0] as? ContactsViewController {
//                        sharedVMService.contactsViewModel(contactViewController)
//                    }
//
//                    if let contactGroupsViewController = viewControllers[1] as? ContactGroupsViewController {
//                        sharedVMService.contactGroupsViewModel(contactGroupsViewController)
//                    }
//                }
//            }
//        } else if let tabBarController = segue.destination as? UITabBarController,
//            let viewControllers = tabBarController.viewControllers {
//            if let contactNavigation = viewControllers[0] as? UINavigationController,
//                let contactViewController = contactNavigation.firstViewController() as? ContactsViewController {
//                sharedVMService.contactsViewModel(contactViewController)
//            }
//
//            if let contactGroupNavigation = viewControllers[1] as? UINavigationController,
//                let contactGroupsViewController = contactGroupNavigation.firstViewController() as? ContactGroupsViewController {
//                sharedVMService.contactGroupsViewModel(contactGroupsViewController)
//            }
//        }
