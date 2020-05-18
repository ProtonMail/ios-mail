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
import SWRevealViewController

class MailboxCoordinator : DefaultCoordinator {
    typealias VC = MailboxViewController
    
    let viewModel : MailboxViewModel
    var services: ServiceFactory
    
    internal weak var viewController: MailboxViewController?
    internal weak var navigation: UINavigationController?
    internal weak var rvc: SWRevealViewController?
    // whole the ref until started
    internal var navBeforeStart: UINavigationController?
    
    init(rvc: SWRevealViewController?, vm: MailboxViewModel, services: ServiceFactory) {
        self.rvc = rvc
        self.viewModel = vm
        self.services = services
        
        let inbox : UIStoryboard = UIStoryboard.Storyboard.inbox.storyboard
        let vc = inbox.make(VC.self)
        let nav = UINavigationController(rootViewController: vc)
        self.viewController = vc
        self.navBeforeStart = nav
        self.navigation = nav
    }
    
    init(nav: UINavigationController?, vc: MailboxViewController, vm: MailboxViewModel, services: ServiceFactory) {
        self.viewModel = vm
        self.viewController = vc
        self.services = services
        self.navigation = nav
    }
    
    init(vc: MailboxViewController, vm: MailboxViewModel, services: ServiceFactory) {
        self.viewModel = vm
        self.services = services
        self.viewController = vc
    }
    
    init(rvc: SWRevealViewController?, nav: UINavigationController?, vc: MailboxViewController, vm: MailboxViewModel, services: ServiceFactory) {
        self.rvc = rvc
        self.navigation = nav
        self.viewController = vc
        self.viewModel = vm
        self.services = services
    }
    
    weak var delegate: CoordinatorDelegate?
    
    enum Destination : String {
        case composer          = "toCompose"
        case composeShow       = "toComposeShow"
        case composeMailto     = "toComposeMailto"
        case search            = "toSearchViewController"
        case details           = "toMessageDetailViewController"
        case detailsFromNotify = "toMessageDetailViewControllerFromNotification"
        case onboarding        = "to_onboarding_segue"
        case feedback          = "to_feedback_segue"
        case feedbackView      = "to_feedback_view_segue"
        case humanCheck        = "toHumanCheckView"
        case folder            = "toMoveToFolderSegue"
        case labels            = "toApplyLabelsSegue"
        case troubleShoot      = "toTroubleShootSegue"
        
        init?(rawValue: String) {
            switch rawValue {
            case "toCompose": self = .composer
            case "toComposeShow", String(describing: ComposeContainerViewController.self): self = .composeShow
            case "toComposeMailto": self = .composeMailto
            case "toSearchViewController", String(describing: SearchViewController.self): self = .search
            case "toMessageDetailViewController", String(describing: MessageContainerViewController.self): self = .details
            case "toMessageDetailViewControllerFromNotification": self = .detailsFromNotify
            case "to_onboarding_segue": self = .onboarding
            case "to_feedback_segue": self = .feedback
            case "to_feedback_view_segue": self = .feedbackView
            case "toHumanCheckView": self = .humanCheck
            case "toMoveToFolderSegue": self = .folder
            case "toApplyLabelsSegue": self = .labels
            case "toTroubleShootSegue": self = .troubleShoot
            default: return nil
            }
        }
    }
    
    /// if called from a segue prepare don't call push again
    func start() {
        self.viewController?.set(viewModel: self.viewModel)
        self.viewController?.set(coordinator: self)
        
        if self.navigation != nil, self.rvc != nil {
            self.rvc?.pushFrontViewController(self.navigation, animated: true)
        }
        self.navBeforeStart = nil
    }

    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false //
        }
        
        switch dest {
        case .details:
            self.viewController?.cancelButtonTapped()
            guard let next = destination as? MessageContainerViewController else {
                return false
            }
            let vmService = services.get() as ViewModelService
            vmService.messageDetails(fromList: next)
            guard let indexPathForSelectedRow = self.viewController?.tableView.indexPathForSelectedRow,
                let message = self.viewModel.item(index: indexPathForSelectedRow) else {
                    return false
            }
            
            next.set(viewModel: .init(message: message, msgService: self.viewModel.messageService, user: self.viewModel.user))
            next.set(coordinator: .init(controller: next))
        case .detailsFromNotify:
            guard let next = destination as? MessageContainerViewController else {
                return false
            }
            let vmService = services.get() as ViewModelService
            vmService.messageDetails(fromPush: next)
            guard let message = self.viewModel.notificationMessage else {
                return false
            }
            let user = self.viewModel.user
            next.set(viewModel: .init(message: message, msgService: user.messageService, user: user))
            next.set(coordinator: .init(controller: next))
            self.viewModel.resetNotificationMessage()
            
        case .composer:
            guard let nav = destination as? UINavigationController,
                let next = nav.viewControllers.first as? ComposeContainerViewController else
            {
                return false
            }
            let user = self.viewModel.user
            let viewModel = ContainableComposeViewModel(msg: nil, action: .newDraft, msgService: user.messageService, user: user)
            next.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel))
            next.set(coordinator: ComposeContainerViewCoordinator(controller: next))
            
        case .composeShow, .composeMailto:
            self.viewController?.cancelButtonTapped()
            
            guard let nav = destination as? UINavigationController,
                let next = nav.viewControllers.first as? ComposeContainerViewController,
                let message = sender as? Message else
            {
                return false
            }

            let user = self.viewModel.user
            let viewModel = ContainableComposeViewModel(msg: message, action: .openDraft, msgService: user.messageService, user: user)
            next.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel))
            next.set(coordinator: ComposeContainerViewCoordinator(controller: next))
            
        case .search, .onboarding:
            return true
        case .feedback:
            return false

        case .feedbackView:
            return false
        case .humanCheck:
            guard let next = destination as? MailboxCaptchaViewController else {
                return false
            }
            next.viewModel = CaptchaViewModelImpl()
            next.delegate = self.viewController
        case .folder:
            guard let next = destination as? LablesViewController else {
                return false
            }
            
            guard let messages = sender as? [Message] else {
                return false
            }

            let user = self.viewModel.user
            next.viewModel = FolderApplyViewModelImpl(msg: messages, folderService: user.labelService, messageService: user.messageService, apiService: user.apiService)
            next.delegate = self.viewController
        case .labels:
            guard let next = destination as? LablesViewController else {
                return false
            }
            guard let messages = sender as? [Message] else {
                return false
            }
            
            let user = self.viewModel.user
            next.viewModel = LabelApplyViewModelImpl(msg: messages, labelService: user.labelService, messageService: user.messageService, apiService: user.apiService)
            next.delegate = self.viewController
            
        case .troubleShoot:
            guard let nav = destination as? UINavigationController else
            {
                return false
            }
            
            let tsVC = NetworkTroubleShootCoordinator.init(segueNav: nav, vm: NetworkTroubleShootViewModelImpl(), services: services)
            tsVC.start()
        }
        return true
    }   
    
    func go(to dest: Destination, sender: Any? = nil) {
        self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: sender)
    }
    
    func follow(_ deeplink: DeepLink) {
        guard let path = deeplink.popFirst, let dest = Destination(rawValue: path.name) else { return }
            
        switch dest {
        case .details:
            if let messageID = path.value,
                case let user = self.viewModel.user,
                case let msgService = user.messageService,
                let message = msgService.fetchMessages(withIDs: [messageID]).first,
                let nav = self.navigation
            {
                let details = MessageContainerViewCoordinator(nav: nav, viewModel: .init(message: message, msgService: msgService, user: user), services: services)
                details.start()
                details.follow(deeplink)
            }
        case .composeShow where path.value != nil:
            if let messageID = path.value,
                let nav = self.navigation,
                case let user = self.viewModel.user,
                case let msgService = user.messageService,
                let message = msgService.fetchMessages(withIDs: [messageID]).first
            {
                let viewModel = ContainableComposeViewModel(msg: message, action: .openDraft, msgService: msgService, user: user)
                let composer = ComposeContainerViewCoordinator.init(nav: nav, viewModel: ComposeContainerViewModel(editorViewModel: viewModel), services: services)
                composer.start()
                composer.follow(deeplink)
            }
            
        case .composeShow where path.value == nil:
            if let nav = self.navigation {
                let user = self.viewModel.user
                let viewModel = ContainableComposeViewModel(msg: nil, action: .newDraft, msgService: user.messageService, user: user)
                let composer = ComposeContainerViewCoordinator.init(nav: nav, viewModel: ComposeContainerViewModel(editorViewModel: viewModel), services: services)
                composer.start()
                composer.follow(deeplink)
            }
        case .composeMailto where path.value != nil:
            if let nav = self.navigation, let value = path.value {
                let user = self.viewModel.user
                let mailToURL = URL(string: value)!
                let viewModel = ContainableComposeViewModel(msg: nil, action: .newDraft, msgService: user.messageService, user: user)
                if let mailTo : NSURL = mailToURL as? NSURL, mailTo.scheme == "mailto", let resSpecifier = mailTo.resourceSpecifier {
                    let rawURLparts = resSpecifier.components(separatedBy: "?")
                    if (rawURLparts.count > 2) {
                        
                    } else {
                        let defaultRecipient = rawURLparts[0]
                        if defaultRecipient.count > 0 { //default to
                            if defaultRecipient.isValidEmail() {
                                viewModel.addToContacts(ContactVO(name: defaultRecipient, email: defaultRecipient))
                            }
                            PMLog.D("to: \(defaultRecipient)")
                        }
                        
                        if (rawURLparts.count == 2) {
                            let queryString = rawURLparts[1]
                            let params = queryString.components(separatedBy: "&")
                            for param in params {
                                let keyValue = param.components(separatedBy: "=")
                                if (keyValue.count != 2) {
                                    continue
                                }
                                let key = keyValue[0].lowercased()
                                var value = keyValue[1]
                                value = value.removingPercentEncoding ?? ""
                                if key == "subject" {
                                    PMLog.D("subject: \(value)")
                                    viewModel.setSubject(value)
                                }
                                
                                if key == "body" {
                                    PMLog.D("body: \(value)")
                                    viewModel.setBody(value)
                                }
                                
                                if key == "to" {
                                    PMLog.D("to: \(value)")
                                    if value.isValidEmail() {
                                        viewModel.addToContacts(ContactVO(name: value, email: value))
                                    }
                                }
                                
                                if key == "cc" {
                                    PMLog.D("cc: \(value)")
                                    if value.isValidEmail() {
                                        viewModel.addCcContacts(ContactVO(name: value, email: value))
                                    }
                                }
                                
                                if key == "bcc" {
                                    PMLog.D("bcc: \(value)")
                                    if value.isValidEmail() {
                                        viewModel.addBccContacts(ContactVO(name: value, email: value))
                                    }
                                }
                            }
                        }
                    }
                }
                let composer = ComposeContainerViewCoordinator.init(nav: nav, viewModel: ComposeContainerViewModel(editorViewModel: viewModel), services: services)
                composer.start()
                composer.follow(deeplink)
            }
            
        default:
            self.go(to: dest, sender: deeplink)
        }
    }
}
