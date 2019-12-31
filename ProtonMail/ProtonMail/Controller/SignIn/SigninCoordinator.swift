//
//  SignInCoordinator.swift
//  ProtonMail - Created on 8/20/19.
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


class SigninCoordinator: DefaultCoordinator {
    typealias VC = SignInViewController
    
    weak var viewController: VC?
    let viewModel : SigninViewModel
    var services: ServiceFactory
    
    enum Destination : String {
        case mailbox   = "toMailboxSegue"
        case label     = "toLabelboxSegue"
        case settings  = "toSettingsSegue"
        case bugs      = "toBugsSegue"
        case contacts  = "toContactsSegue"
        case feedbacks = "toFeedbackSegue"
        case plan      = "toServicePlan"
        
        init?(rawValue: String) {
            switch rawValue {
            case "toMailboxSegue", String(describing: MailboxViewController.self): self = .mailbox
            case "toLabelboxSegue": self = .label
            case "toSettingsSegue": self = .settings
            case "toBugsSegue": self = .bugs
            case "toContactsSegue": self = .contacts
            case "toFeedbackSegue": self = .feedbacks
            case "toServicePlan": self = .plan
            default: return nil
            }
        }
    }
    
    init(destination: UIWindow, vm: SigninViewModel, services: ServiceFactory) {
        self.viewModel = vm
        self.services = services
        
        // defined by Storyboard
        let controller = (destination.rootViewController as! UINavigationController).viewControllers.first as! VC
        
        self.viewController = controller
        self.viewController?.modalPresentationStyle = .fullScreen
    }
    
    func start() {
        self.viewController?.set(viewModel: self.viewModel)
        self.viewController?.set(coordinator: self)
    }
    
    private func toPlan() {
        let coordinator = MenuCoordinator()
        coordinator.controller = self.viewController
        coordinator.go(to: .serviceLevel, creating: StorefrontCollectionViewController.self)
    }
    
    private func toInbox(labelID: String, deepLink: DeepLink) {
//        //Example of deeplink without segue
//        var nextVM : MailboxViewModel?
//        if let mailbox = Message.Location(rawValue: labelID) {
//            nextVM = MailboxViewModelImpl(label: mailbox, service: services.get(), pushService: services.get())
//        } else if let label = sharedLabelsDataService.label(by: labelID) {
//            //shared global service need to be changed later
//            if label.exclusive {
//                nextVM = FolderboxViewModelImpl(label: label, service: services.get(), pushService: services.get())
//            } else {
//                nextVM = LabelboxViewModelImpl(label: label, service: services.get(), pushService: services.get())
//            }
//        }
//
//        if let vm = nextVM {
//            let mailbox = MailboxCoordinator(rvc: self.viewController?.revealViewController(), vm: vm, services: self.services)
//            self.lastestCoordinator = mailbox
//            mailbox.start()
//            mailbox.follow(deepLink)
//        }
        
    }
    
    func follow(_ deepLink: DeepLink) {
        if let path = deepLink.popFirst, let dest = MenuCoordinatorNew.Destination(rawValue: path.name) {
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
        
        return false
    }
}
