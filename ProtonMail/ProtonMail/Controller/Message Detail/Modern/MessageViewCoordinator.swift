//
//  MessageViewCoordinator.swift
//  ProtonMail - Created on 07/03/2019.
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
import QuickLook

protocol PdfPagePrintable {
    func printPageRenderer() -> UIPrintPageRenderer
}

class MessageViewCoordinator: NSObject {
    internal enum Destinations: String {
        case folders = "toMoveToFolderSegue"
        case labels = "toApplyLabelsSegue"
        case composerReply = "toComposeReply"
        case composerReplyAll = "toComposeReplyAll"
        case composerForward = "toComposeForward"
    }
    private weak var controller: MessageViewController!
    private var tempClearFileURL: URL?
    
    init(controller: MessageViewController) {
        self.controller = controller
    }
    
    internal func go(to destination: Destinations) {
        self.controller.performSegue(withIdentifier: destination.rawValue, sender: nil)
    }
    
    // Create controllers
    
    private var headerControllers: [UIViewController] = []
    private var bodyControllers: [UIViewController] = []
    private var attachmentsControllers: [UIViewController] = []

    typealias ChildViewModelPack = (head: MessageHeaderViewModel, body: MessageBodyViewModel, attachments: MessageAttachmentsViewModel)
    
    internal func createChildControllers(with children: [ChildViewModelPack]) {
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
        childController.set(coordinator: .init(controller: childController, enclosingScroller: self.controller) )
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

    internal func printableChildren() -> [PdfPagePrintable] {
        var children: [PdfPagePrintable] = self.headerControllers.compactMap { $0 as? PdfPagePrintable }
        children.append(contentsOf: self.attachmentsControllers.compactMap { $0 as? PdfPagePrintable })
        children.append(contentsOf: self.bodyControllers.compactMap { $0 as? PdfPagePrintable })
        return children
    }
    
    // Embed subviews
    
    internal func embedBody(index: Int, onto view: UIView) {
        self.embed(self.bodyControllers[index], onto: view)
    }
    internal func embedHeader(index: Int, onto view: UIView) {
        self.embed(self.headerControllers[index], onto: view)
    }
    internal func embedAttachments(index: Int, onto view: UIView) {
        self.embed(self.attachmentsControllers[index], onto: view)
    }
    
    private func embed(_ child: UIViewController, onto view: UIView) {
        assert(self.controller.isViewLoaded, "Attempt to embed child VC before parent's view was loaded - will cause glitches")
        
        // remove child from old parent
        if let parent = child.parent, parent != self.controller {
            child.willMove(toParent: nil)
            if child.isViewLoaded {
                child.view.removeFromSuperview()
            }
            child.removeFromParent()
        }
        
        // add child to new parent
        self.controller.addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view) 
        child.didMove(toParent: self.controller)
        
        // autolayout
        view.topAnchor.constraint(equalTo: child.view.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: child.view.bottomAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: child.view.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: child.view.trailingAnchor).isActive = true
    }
    
    internal func dismiss() {
        self.controller.navigationController?.popViewController(animated: true)
    }
    
    internal func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let messages = sender as? [Message] else { return }
        switch Destinations(rawValue: segue.identifier!) {
        case .some(let destination) where destination == .composerReply ||
                                            destination == .composerReplyAll ||
                                            destination == .composerForward:
            guard let tapped = ComposeMessageAction(destination) else { return }
            let composeViewController = segue.destination.children[0] as! ComposeViewController
            sharedVMService.newDraft(vmp: composeViewController)
            let viewModel = ComposeViewModelImpl(msg: messages.first!, action: tapped)
            let coordinator = ComposeCoordinator(vc: composeViewController,
                                                 vm: viewModel, services: ServiceFactory.default) //set view model
            coordinator.start()
            
        case .some(.labels):
            let popup = segue.destination as! LablesViewController
            popup.viewModel = LabelApplyViewModelImpl(msg: messages)
            popup.delegate = self
            self.controller.setPresentationStyleForSelfController(self.controller, presentingController: popup)
            
        case .some(.folders):
            let popup = segue.destination as! LablesViewController
            popup.delegate = self
            popup.viewModel = FolderApplyViewModelImpl(msg: messages)
            self.controller.setPresentationStyleForSelfController(self.controller, presentingController: popup)
            
        default: break
        }
    }
    
    internal func previewQuickLook(for url: URL) {
        self.tempClearFileURL = url
        let previewQL = QuickViewViewController()
        previewQL.dataSource = self
        self.controller.present(previewQL, animated: true, completion: nil)
    }
}

extension MessageViewCoordinator: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
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

extension MessageViewCoordinator: LablesViewControllerDelegate {
    func dismissed() {
        // FIXME: update header
    }
    
    func apply(type: LabelFetchType) {
        if type == .folder {
            self.dismiss()
        }
    }
}

extension MessageViewCoordinator: CoordinatorNew {
    func start() {
        // ?
    }
}

extension ComposeMessageAction {
    init?(_ destination: MessageViewCoordinator.Destinations) {
        switch destination {
        case .composerReply: self = ComposeMessageAction.reply
        case .composerReplyAll: self = ComposeMessageAction.replyAll
        case .composerForward: self = ComposeMessageAction.forward
        default: return nil
        }
    }
}



// composer stuff
extension MessageViewCoordinator {
    typealias ChildViewModelPack2 = (head: MessageHeaderViewModel, body: EditorViewModel, attachments: MessageAttachmentsViewModel)
    
    private func createEditorController(_ childViewModel: EditorViewModel) -> EditorViewController {
        guard let nav = UIStoryboard.init(name: "Composer", bundle: nil).instantiateInitialViewController() as? UINavigationController,
            let prenext = nav.firstViewController() as? ComposeViewController else
        {
            fatalError()
        }
        
        object_setClass(prenext, EditorViewController.self)
        guard let next = prenext as? EditorViewController else {
            fatalError()
        }
        next.enclosingScroller = self.controller
        let vmService = sharedServices.get() as ViewModelService
        vmService.newDraft(vmp: next)
        let coordinator = ComposeCoordinator(vc: next, vm: childViewModel, services: sharedServices)
        coordinator.start()
        return next
    }
    
}
