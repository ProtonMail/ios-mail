//
//  SettingsCoordinator.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 09/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

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
    
    
    enum Destination : String {
        case mailbox   = "toMailboxSegue"
        case label     = "toLabelboxSegue"
        case settings  = "toSettingsSegue"
        case bugs      = "toBugsSegue"
        case contacts  = "toContactsSegue"
        case feedbacks = "toFeedbackSegue"
    }
    
    init(vc: MenuViewController, vm: MenuViewModel) {
        self.viewModel = vm
        self.viewController = vc
    }
    
    func start() {
        self.viewController?.set(viewModel: self.viewModel)
        self.viewController?.set(coordinator: self)
    }
    
    func go(to dest: Destination, sender: Any? = nil) {
        self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: sender)
    }
    ///TODO::fixme. add warning or error when return false except the last one.
    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false //
        }
        
        guard let navigation = destination as? UINavigationController else {
            return false
        }
        
        guard let rvc = source.revealViewController() else {
            return false
        }
        
        switch dest {
        case .mailbox:
            //let index = sender as? IndexPath
            guard let next = navigation.firstViewController() as? MailboxViewController else {
                return false
            }
            sharedVMService.mailbox(fromMenu: next)
            let viewModel = MailboxViewModelImpl(label: .inbox)
            let mailbox = MailboxCoordinator(rvc: rvc, nav: navigation, vc: next, vm: viewModel)
            mailbox.start()
        case .settings:
            guard let next = navigation.firstViewController() as? SettingsTableViewController else {
                return false
            }

            let viewModel = SettingsViewModelImpl()
            let settings = SettingsCoordinator(rvc: rvc, nav: navigation, vc: next, vm: viewModel)
            settings.start()
        default:
            return false
        }
    
        
        
        return false
    }
}

//        segue.destination.view.accessibilityElementsHidden = false
//        self.view.accessibilityElementsHidden = true
//
//        // TODO: this deeplink implementation is ugly, consider using Coordinators pattern
//        if #available(iOS 10.0, *),
//            sender is NotificationsSnoozer,
//            let navigation = segue.destination as? UINavigationController,
//            let settings = navigation.topViewController as? SettingTableViewController
//        {
//            settings.performSegue(withIdentifier: settings.kNotificationsSnoozeSegue, sender: sender)
//        }
//
//
//
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
