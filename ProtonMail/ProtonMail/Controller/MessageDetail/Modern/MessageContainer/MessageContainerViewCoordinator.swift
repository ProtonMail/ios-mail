//
//  MessageViewCoordinator.swift
//  ProtonMail - Created on 07/03/2019.
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
import QuickLook

class MessageContainerViewCoordinator: TableContainerViewCoordinator {

    internal enum Destinations: String {
        case folders = "toMoveToFolderSegue"
        case labels = "toApplyLabelsSegue"
        case composerReply = "toComposeReply"
        case composerReplyAll = "toComposeReplyAll"
        case composerForward = "toComposeForward"
        case composerDraft = "toDraft"
        case toTroubleshoot = "toTroubleShootSegue"
        
        init?(rawValue: String) {
            switch rawValue {
            case "toMoveToFolderSegue": self = .folders
            case "toApplyLabelsSegue": self = .labels
            case "toComposeReply": self = .composerReply
            case "toComposeReplyAll": self = .composerReplyAll
            case "toComposeForward": self = .composerForward
            case "toDraft", String(describing: ComposeContainerViewController.self): self = .composerDraft
            case "toTroubleShootSegue": self = .toTroubleshoot
            default: return nil
            }
        }
    }
    
    typealias VC = MessageContainerViewController
    internal weak var controller: MessageContainerViewController!
    internal weak var navigationController: UINavigationController?
    var viewController: MessageContainerViewController?
    var configuration: ((MessageContainerViewController) -> ())?
    
    var services: ServiceFactory = ServiceFactory.default
    let user: UserManager
    
    init(nav: UINavigationController, viewModel: MessageContainerViewModel, services: ServiceFactory) {
        self.navigationController = nav
        self.services = services
        let vc = UIStoryboard.Storyboard.message.storyboard.make(VC.self)
        self.viewController = vc
        self.controller = vc
        self.user = viewModel.user
        self.viewController?.set(viewModel: viewModel)
    }
    
    func follow(_ deeplink: DeepLink) {
        guard let path = deeplink.popFirst, let destination = Destinations(rawValue: path.name) else { return }
        
        switch destination {
        case .composerDraft:
            if let messageID = path.value,
                let nav = self.navigationController,
                let message = user.messageService.fetchMessages(withIDs: [messageID]).first
            {
                let viewModel = ContainableComposeViewModel(msg: message, action: .openDraft, msgService: user.messageService, user: user)
                let composer = ComposeContainerViewCoordinator(nav: nav, viewModel: ComposeContainerViewModel(editorViewModel: viewModel), services: services)
                composer.start()
                composer.follow(deeplink)
            }
        default:
            self.go(to: destination, sender: deeplink)
        }
    }

    override func start() {
        guard let viewController = viewController else {
            return
        }
        viewController.set(coordinator: self)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    init(controller: MessageContainerViewController) {
        self.controller = controller
        self.user = controller.viewModel.user
    }
    
    deinit {
        self.stop()
    }
    
    func stop() {
        // break ViewModel observations before it is destroyed to prevent crash on iOS 9-10
        self.observationThread = nil
    }
    
    private var tempClearFileURL: URL?
    
    internal func go(to destination: Destinations, sender: Any? = nil) {
        self.controller.performSegue(withIdentifier: destination.rawValue, sender: sender)
    }
    
    // Create controllers
    
    private var headerControllers: [UIViewController] = []
    private var bodyControllers: [UIViewController] = []
    private var attachmentsControllers: [UIViewController] = []
    private var observationThread: NSKeyValueObservation?

    internal func createChildControllers(with viewModel: MessageContainerViewModel) {
        let children = viewModel.children()
        
        self.observationThread = viewModel.observe(\.thread) { [weak self] viewModel, change in
            // TODO: remove children one by one for threads mode support
            guard viewModel.thread.isEmpty else { return }
            (self?.viewController ?? self?.controller)?.navigationController?.popViewController(animated: true)
        }
        
        // TODO: good place for generics
        self.bodyControllers = []
        self.headerControllers = []
        self.attachmentsControllers = []
        
        children.forEach { head, body, attachments in
            self.headerControllers.append(self.createHeaderController(head))
            self.bodyControllers.append(self.createBodyController(body))
            self.attachmentsControllers.append(self.createAttachmentsController(attachments))
        }
    }
    
    private func createHeaderController(_ childViewModel: MessageHeaderViewModel) -> MessageHeaderViewController {
        guard let childController = self.controller.storyboard?.make(MessageHeaderViewController.self) else {
            fatalError("No storyboard for creating MessageBodyViewController")
        }
        childController.set(viewModel: childViewModel)
        childController.set(coordinator: .init(controller: childController))
        return childController
    }
    
    private func createBodyController(_ childViewModel: MessageBodyViewModel) -> MessageBodyViewController {
        guard let childController =  self.controller.storyboard?.make(MessageBodyViewController.self) else {
            fatalError("No storyboard for creating MessageBodyViewController")
        }
        
        childController.set(viewModel: childViewModel)
        childController.set(coordinator: .init(controller: childController,
                                               enclosingScroller: self.controller,
                                               user: self.controller.viewModel.user) )
        return childController
    }
    
    private func createAttachmentsController(_ childViewModel: MessageAttachmentsViewModel) -> MessageAttachmentsViewController {
        guard let childController =  self.controller.storyboard?.make(MessageAttachmentsViewController.self) else {
            fatalError("No storyboard for creating MessageAttachmentsViewController")
        }
        childController.set(viewModel: childViewModel)
        childController.set(coordinator: .init(controller: childController))
        return childController
    }

    internal func presentPrintController() {
        let pairs = zip(self.headerControllers, self.bodyControllers).compactMap { header, body -> (HeaderedPrintRenderer.CustomViewPrintRenderer, HeaderedPrintRenderer)? in
            guard let headerPrinter = (header as? Printable)?.printPageRenderer() as? HeaderedPrintRenderer.CustomViewPrintRenderer,
                let bodyPrinter = (body as? Printable)?.printPageRenderer() as? HeaderedPrintRenderer else
            {
                    return nil
            }
            bodyPrinter.header = headerPrinter
            
            (header as? Printable)?.printingWillStart?(renderer: headerPrinter)
            (body as? Printable)?.printingWillStart?(renderer: bodyPrinter)
            
            return (headerPrinter, bodyPrinter)
        }
        
        // TODO: this will not work good with multiple printable children, will need to make a unified one-by-one renderer
        let printController = UIPrintInteractionController.shared
        printController.printPageRenderer = pairs.first(where: { _,_ in true })?.1
        printController.present(animated: true, completionHandler: { _, _, _ in
            self.headerControllers.forEach { ($0 as? Printable)?.printingDidFinish?() }
            self.bodyControllers.forEach { ($0 as? Printable)?.printingDidFinish?() }
        })
    }
    
    // Embed subviews
    override internal func embedChild(indexPath: IndexPath, onto cell: UITableViewCell) {
        let standalone = self.controller.viewModel.thread[indexPath.section]
        switch standalone.divisions[indexPath.row] {
        case .header:
            cell.clipsToBounds = true // this is needed only with old EmailHeaderView in order to cut off its bottom line
            self.embedHeader(index: indexPath.section, onto: cell.contentView)
            
        case .attachments:
            self.embedAttachments(index: indexPath.section, onto: cell.contentView)
            
        case .body:
            self.embedBody(index: indexPath.section, onto: cell.contentView)
            
        default:
            assert(false, "Child not embedded")
            break
        }
    }
    
    private func embedBody(index: Int, onto view: UIView) {
        self.embed(self.bodyControllers[index], onto: view, ownedBy: self.controller)
    }
    private func embedHeader(index: Int, onto view: UIView) {
        self.embed(self.headerControllers[index], onto: view, ownedBy: self.controller)
    }
    private func embedAttachments(index: Int, onto view: UIView) {
        self.embed(self.attachmentsControllers[index], onto: view, ownedBy: self.controller)
    }
    
    internal func dismiss() {
        self.controller.navigationController?.popViewController(animated: true)
    }
    
    internal func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch Destinations(rawValue: segue.identifier!) {
        case .some(let destination) where destination == .composerReply ||
                                            destination == .composerReplyAll ||
                                            destination == .composerForward:
            guard let messages = sender as? [Message] else { return }
            guard let tapped = ComposeMessageAction(destination),
                let navigator = segue.destination as? UINavigationController,
                let next = navigator.viewControllers.first as? ComposeContainerViewController else
            {
                assert(false, "Wrong root view controller in Compose storyboard")
                return
            }
            next.set(viewModel: ComposeContainerViewModel(editorViewModel: ContainableComposeViewModel(msg: messages.first!,
                                                                                                       action: tapped,
                                                                                                       msgService: user.messageService,
                                                                                                       user: user)))
            next.set(coordinator: ComposeContainerViewCoordinator(controller: next))
            
        case .some(.labels):
            guard let messages = sender as? [Message] else { return }
            let popup = segue.destination as! LablesViewController
            popup.viewModel = LabelApplyViewModelImpl(msg: messages, labelService: user.labelService, messageService: user.messageService, apiService: user.apiService)
            popup.delegate = self
            self.controller.setPresentationStyleForSelfController(self.controller, presentingController: popup)
            
        case .some(.folders):
            guard let messages = sender as? [Message] else { return }
            let popup = segue.destination as! LablesViewController
            popup.delegate = self
            popup.viewModel = FolderApplyViewModelImpl(msg: messages, folderService: user.labelService, messageService: user.messageService, apiService: user.apiService)
            self.controller.setPresentationStyleForSelfController(self.controller, presentingController: popup)
        case .some(.toTroubleshoot):
            guard let nav = segue.destination as? UINavigationController else {
                return
            }
            let tsVC = NetworkTroubleShootCoordinator.init(segueNav: nav, vm: NetworkTroubleShootViewModelImpl(), services: services)
            tsVC.start()
        default: break
        }
    }
    
    internal func previewQuickLook(for url: URL) {
        self.tempClearFileURL = url
        let previewQL = QuickViewViewController()
        previewQL.dataSource = self
        previewQL.delegate = self
        self.controller.present(previewQL, animated: true, completion: nil)
    }
}

extension MessageContainerViewCoordinator: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    internal func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    internal func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.tempClearFileURL! as QLPreviewItem
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        try? FileManager.default.removeItem(at: self.tempClearFileURL!)
        self.tempClearFileURL = nil
    }
}

extension MessageContainerViewCoordinator: LablesViewControllerDelegate {
    func dismissed() {
        // FIXME: update header
    }
    
    func apply(type: LabelFetchType) {
        if type == .folder {
            self.dismiss()
        }
    }
}

extension ComposeMessageAction {
    init?(_ destination: MessageContainerViewCoordinator.Destinations) {
        switch destination {
        case .composerReply: self = ComposeMessageAction.reply
        case .composerReplyAll: self = ComposeMessageAction.replyAll
        case .composerForward: self = ComposeMessageAction.forward
        default: return nil
        }
    }
}
