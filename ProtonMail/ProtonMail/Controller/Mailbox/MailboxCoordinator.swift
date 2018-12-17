//
//  MailboxCoordinator.swift.swift
//  ProtonMail - Created on 12/10/18.
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

class MailboxCoordinator : DefaultCoordinator {
    typealias VC = MailboxViewController
    
    let viewModel : MailboxViewModel
    var services: ServiceFactory
    
    internal weak var viewController: MailboxViewController?
    internal weak var navigation: UINavigationController?
    internal weak var rvc: SWRevealViewController?
    
    init(vc: MailboxViewController, vm: MailboxViewModel, services: ServiceFactory) {
        self.viewModel = vm
        self.viewController = vc
        self.services = services
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
        case search            = "toSearchViewController"
        case details           = "toMessageDetailViewController"
        case detailsFromNotify = "toMessageDetailViewControllerFromNotification"
        case onboarding        = "to_onboarding_segue"
        case feedback          = "to_feedback_segue"
        case feedbackView      = "to_feedback_view_segue"
        case humanCheck        = "toHumanCheckView"
        case folder            = "toMoveToFolderSegue"
        case labels            = "toApplyLabelsSegue"
    }
    
    /// if called from a segue prepare don't call push again
    func start() {
        self.viewController?.set(viewModel: self.viewModel)
        self.viewController?.set(coordinator: self)
        
        if self.navigation != nil, self.rvc != nil {
            self.rvc?.pushFrontViewController(self.navigation, animated: true)
        }
    }
    
    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false //
        }
        
        switch dest {
        case .details:
            self.viewController?.cancelButtonTapped()
            guard let next = destination as? MessageViewController else {
                return false
            }
            sharedVMService.messageDetails(fromList: next)
            let indexPathForSelectedRow = self.viewController?.tableView.indexPathForSelectedRow
            if let indexPathForSelectedRow = indexPathForSelectedRow {
                if let message = self.viewModel.item(index: indexPathForSelectedRow) {
                    next.message = message
                } else {
                    //let alert = LocalString._messages_cant_find_message.alertController()
                    //alert.addOKAction()
                    //present(alert, animated: true, completion: nil)
                }
            } else {
                PMLog.D("No selected row.")
            }
        default:
            return false
        }
        

        
//        switch dest {
//        case .password:
//            guard let popup = destination as? ComposePasswordViewController else {
//                return false
//            }
//            
//            guard let vc = viewController else {
//                return false
//            }
//            
//            popup.pwdDelegate = self
//            //get this data from view model
//            popup.setupPasswords(vc.encryptionPassword, confirmPassword: vc.encryptionConfirmPassword, hint: vc.encryptionPasswordHint)
//            
//        case .expirationWarning:
//            guard let popup = destination as? ExpirationWarningViewController else {
//                return false
//            }
//            guard let vc = viewController else {
//                return false
//            }
//            popup.delegate = self
//            let nonePMEmail = vc.encryptionPassword.count <= 0 ? vc.headerView.nonePMEmails : [String]()
//            popup.config(needPwd: nonePMEmail,
//                         pgp: vc.headerView.pgpEmails)
//        case .subSelection:
//            guard let destination = destination as? ContactGroupSubSelectionViewController else {
//                return false
//            }
//            guard let vc = viewController else {
//                return false
//            }
//            
//            guard let group = vc.pickedGroup else {
//                return false
//            }
//            destination.contactGroupName = group.contactTitle
//            destination.selectedEmails = group.getSelectedEmailData()
//            destination.callback = vc.pickedCallback
//        }
        return true
    }
//    // MARK: - Prepare for segue
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == kSegueToMessageDetailFromNotification {
//            self.cancelButtonTapped()
//            let messageDetailViewController = segue.destination as! MessageViewController
//            sharedVMService.messageDetails(fromPush: messageDetailViewController)
//            if let msgID = self.viewModel.notificationMessageID {
//                if let context = fetchedResultsController?.managedObjectContext {
//                    if let message = Message.messageForMessageID(msgID, inManagedObjectContext: context) {
//                        messageDetailViewController.message = message
//                        self.viewModel.resetNotificationMessage()
//                    }
//                }
//            } else {
//                PMLog.D("No selected row.")
//            }
//        } else if (segue.identifier == kSegueToMessageDetailController) {
//            self.cancelButtonTapped()
//            let messageDetailViewController = segue.destination as! MessageViewController
//            sharedVMService.messageDetails(fromList: messageDetailViewController)
//            let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow
//            if let indexPathForSelectedRow = indexPathForSelectedRow {
//                if let message = self.messageAtIndexPath(indexPathForSelectedRow) {
//                    messageDetailViewController.message = message
//                } else {
//                    let alert = LocalString._messages_cant_find_message.alertController()
//                    alert.addOKAction()
//                    present(alert, animated: true, completion: nil)
//                }
//            } else {
//                PMLog.D("No selected row.")
//            }
//        } else if segue.identifier == kSegueToComposeShow {
//            self.cancelButtonTapped()
//            //TODO:: Check
//            let composeViewController = segue.destination.children[0] as! ComposeViewController
//            if let indexPathForSelectedRow = indexPathForSelectedRow {
//                if let message = self.messageAtIndexPath(indexPathForSelectedRow) {
//                    sharedVMService.openDraft(vmp: composeViewController, with: selectedDraft ?? message)
//
//                    //TODO:: finish up here
//                    let coordinator = ComposeCoordinator(vc: composeViewController,
//                                                         vm: composeViewController.viewModel) //set view model
//                    coordinator.viewController = composeViewController
//                    composeViewController.set(coordinator: coordinator)
//                } else {
//                    let alert = LocalString._messages_cant_find_message.alertController()
//                    alert.addOKAction()
//                    present(alert, animated: true, completion: nil)
//                }
//
//            } else {
//                PMLog.D("No selected row.")
//            }
//
//        } else if segue.identifier == kSegueToApplyLabels {
//            let popup = segue.destination as! LablesViewController
//            popup.viewModel = LabelApplyViewModelImpl(msg: self.getSelectedMessages())
//            popup.delegate = self
//            self.setPresentationStyleForSelfController(self, presentingController: popup)
//            self.cancelButtonTapped()
//
//        } else if segue.identifier == kSegueMoveToFolders {
//            let popup = segue.destination as! LablesViewController
//            popup.viewModel = FolderApplyViewModelImpl(msg: self.getSelectedMessages())
//            popup.delegate = self
//            self.setPresentationStyleForSelfController(self, presentingController: popup)
//            self.cancelButtonTapped()
//
//        }
//        else if segue.identifier == kSegueToHumanCheckView{
//            let popup = segue.destination as! MailboxCaptchaViewController
//            popup.viewModel = CaptchaViewModelImpl()
//            popup.delegate = self
//            self.setPresentationStyleForSelfController(self, presentingController: popup)
//
//        } else if segue.identifier == kSegueToCompose {
//            let composeViewController = segue.destination.children[0] as! ComposeViewController
//            sharedVMService.newDraft(vmp: composeViewController)
//
//            //TODO:: finish up here
//            let coordinator = ComposeCoordinator(vc: composeViewController,
//                                                 vm: composeViewController.viewModel) //set view model
//            coordinator.viewController = composeViewController
//            composeViewController.set(coordinator: coordinator)
//        } else if segue.identifier == kSegueToTour {
//            let popup = segue.destination as! OnboardingViewController
//            self.setPresentationStyleForSelfController(self, presentingController: popup)
//        } else if segue.identifier == kSegueToFeedback {
//            let popup = segue.destination as! FeedbackPopViewController
//            popup.feedbackDelegate = self
//            //popup.viewModel = LabelViewModelImpl(msg: self.getSelectedMessages())
//            self.setPresentationStyleForSelfController(self, presentingController: popup)
//        } else if segue.identifier == kSegueToFeedbackView {
//
//        }
//    }
//
    
    
    func go(to dest: Destination) {
        self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: nil)
    }
}
