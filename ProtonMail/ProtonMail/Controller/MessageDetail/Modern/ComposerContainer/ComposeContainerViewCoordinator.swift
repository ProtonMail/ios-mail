//
//  ComposeContainerViewCoordinator.swift
//  ProtonMail - Created on 15/04/2019.
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
        viewController.modalPresentationStyle = .fullScreen
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
            self?.attachmentsObservation = childViewModel.message?.observe(\.attachments, options: [.new, .old]) { [weak self] message, change in
                DispatchQueue.main.async {
                    self?.header.updateAttachmentButton(message.attachments.count != 0)
                    if change.oldValue?.count != change.newValue?.count, change.newValue?.count != 0 {
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
