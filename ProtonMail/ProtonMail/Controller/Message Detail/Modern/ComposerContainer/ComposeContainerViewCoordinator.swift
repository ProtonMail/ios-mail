//
//  ComposeContainerViewCoordinator.swift
//  ProtonMail - Created on 15/04/2019.
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

class ComposeContainerViewCoordinator: TableContainerViewCoordinator {
    typealias VC = ComposeContainerViewController
    var viewController: UINavigationController?
    var configuration: ((ComposeContainerViewCoordinator.VC) -> ())?
    
    
    private weak var controller: ComposeContainerViewController!
    private weak var services: ServiceFactory!
    
    private var header: ComposeHeaderViewController!
    internal var editor: ContainableComposeViewController!
    
    private var attachmentsObservation: NSKeyValueObservation!
    private var messageObservation: NSKeyValueObservation!
    
    internal weak var navigationController: UINavigationController?
    
    deinit {
        self.attachmentsObservation = nil
        self.messageObservation = nil
    }
    
    init(controller: ComposeContainerViewController, services: ServiceFactory) {
        self.controller = controller
        self.services = services
        super.init()
    }
    
    init(nav: UINavigationController, viewModel: ComposeContainerViewModel, services: ServiceFactory) {
        self.navigationController = nav
        self.services = services
        let vc = UIStoryboard.Storyboard.composer.storyboard.instantiateInitialViewController() as? UINavigationController
        self.viewController = vc
        self.controller = vc?.viewControllers.first as? ComposeContainerViewController
        self.controller?.set(viewModel: viewModel)
    }
    
    func follow(_ deeplink: DeepLink) {
        // TODO
    }
    
    override func start() {
        guard let viewController = viewController else {
            return
        }
        self.controller?.set(coordinator: self)
        navigationController?.present(viewController, animated: true, completion: nil)
    }
    
    #if !APP_EXTENSION
    init(controller: ComposeContainerViewController) {
        self.controller = controller
        self.services = sharedServices
        super.init()
    }
    #endif
    
    internal func cancelAction(_ sender: UIBarButtonItem) {
        self.editor.cancelAction(sender)
    }
    @IBAction func sendAction(_ sender: UIBarButtonItem) {
        self.editor.sendAction(sender)
    }
    
    internal func headerFrame() -> CGRect {
        return self.header.view.frame
    }
    
    internal func inject(_ picker: UIPickerView) {
        self.editor.injectExpirationPicker(picker)
    }
    
    internal func createEditor(_ childViewModel: ContainableComposeViewModel) {
        let child = UIStoryboard(name: "Composer", bundle: nil).make(ContainableComposeViewController.self)
        child.injectHeader(self.header)
        child.enclosingScroller = self.controller
        
        let coordinator = ComposeCoordinator(vc: child, vm: childViewModel, services: self.services)
        coordinator.start()
        self.editor = child
    }
    
    internal func createHeader(_ childViewModel: ContainableComposeViewModel) -> ComposeHeaderViewController {
        self.header = ComposeHeaderViewController(nibName: String(describing: ComposeHeaderViewController.self), bundle: nil)
        
        self.messageObservation = childViewModel.observe(\.message, options: [.initial]) { [weak self] childViewModel, _ in
            self?.attachmentsObservation = childViewModel.message?.observe(\.numAttachments, options: [.new, .old]) { [weak self] message, change in
                DispatchQueue.main.async {
                    self?.header.updateAttachmentButton(message.numAttachments.intValue != 0)
                    if change.oldValue?.intValue != change.newValue?.intValue, change.newValue?.intValue != 0 {
                        self?.header.attachmentButton.shake(5, offset: 5.0)
                    }
                }
            }
        }
        
        return self.header
    }
    
    override func embedChild(indexPath: IndexPath, onto cell: UITableViewCell) {
        switch indexPath.row {
        case 0:
            self.embed(self.header, onto: cell.contentView, ownedBy: self.controller)
        case 1:
            self.embed(self.editor, onto: cell.contentView, layoutGuide: cell.contentView.layoutMarginsGuide, ownedBy: self.controller)
        default:
            assert(false, "Children number misalignment")
            return
        }
    }
}
