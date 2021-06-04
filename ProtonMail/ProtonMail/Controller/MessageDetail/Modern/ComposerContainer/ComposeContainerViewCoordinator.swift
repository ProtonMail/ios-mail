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
    
    private(set) var header: ComposeHeaderViewController!
    internal var editor: ContainableComposeViewController!
    private(set) var attachmentView: ComposerAttachmentVC?
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
        viewModel.uiDelegate = self.controller
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
        return self.header
    }
    
    func createAttachmentView(childViewModel: ContainableComposeViewModel) -> ComposerAttachmentVC {
        
        #if APP_EXTENSION
        let cachedMessage = childViewModel.message
        self.messageObservation = childViewModel.observe(\.message, options: [.initial]) { [weak self] childViewModel, _ in
            self?.attachmentsObservation = childViewModel.message?.observe(\.attachments, options: [.new, .old]) { [weak self] message, change in
                guard change.oldValue?.count != change.newValue?.count,
                      let attachments = cachedMessage?.attachments.allObjects as? [Attachment] else {
                    return
                }
                attachments.forEach { attachment in
                    self?.addAttachment(attachment, shouldUpload: false)
                }
                self?.controller.getSharedFiles()
            }
        }
        #endif

        let attachments = childViewModel.getAttachments() ?? []
        let component = ComposerAttachmentVC(attachments: attachments, delegate: self)
        self.attachmentView = component
        self.controller.updateAttachmentCount(number: component.datas.count)
        component.addNotificationObserver()
        return component
    }
    
    func getAttachmentSize() -> Int {
        var attachmentSize: Int = 0
        let semaphore = DispatchSemaphore(value: 0)
        self.attachmentView?.getSize(completeHandler: { size in
            attachmentSize = size
            semaphore.signal()
        })
        _ = semaphore.wait(timeout: .distantFuture)
        return attachmentSize
    }
    
    override func embedChild(indexPath: IndexPath, onto cell: UITableViewCell) {
        switch indexPath.row {
        case 0:
            self.embed(self.header, onto: cell.contentView, ownedBy: self.controller)
        case 1:
            self.embed(self.editor, onto: cell.contentView, layoutGuide: cell.contentView.layoutMarginsGuide, ownedBy: self.controller)
        case 2:
            guard let component = self.attachmentView else { return }
            self.embed(component, onto: cell.contentView, ownedBy: self.controller)
        default:
            assert(false, "Children number misalignment")
            return
        }
    }
    
    func navigateToPassword() {
        self.editor.autoSaveTimer()

        let password = self.editor.encryptionPassword
        let confirm = self.editor.encryptionConfirmPassword
        let hint = self.editor.encryptionPasswordHint
        let passwordVC = ComposePasswordVC.instance(password: password, confirmPassword: confirm, hint: hint, delegate: self)
        guard let navigationController = self.controller.navigationController else {
            return
        }
        navigationController.show(passwordVC, sender: nil)
    }
    
    func navigateToExpiration() {
        self.editor.autoSaveTimer()

        let time = self.header.expirationTimeInterval
        let expirationVC = ComposeExpirationVC(expiration: time, delegate: self)
        guard let navigationController = self.controller.navigationController else {
            return
        }
        navigationController.show(expirationVC, sender: nil)
    }
    
    func addAttachment(_ attachment: Attachment, shouldUpload: Bool = true) {
        guard let message = self.editor.viewModel.message else { return }
        let coreDataService: CoreDataService = sharedServices.get(by: CoreDataService.self)
        let context = coreDataService.operationContext
        context.performAndWait {
            attachment.message = message
            _ = context.saveUpstreamIfNeeded()
        }
        guard let component = self.attachmentView else { return }
        component.add(attachments: [attachment]) { [weak self] in
            DispatchQueue.main.async {
                let number = component.datas.count
                self?.controller.updateAttachmentCount(number: number)
            }
        }
        
        guard shouldUpload else { return }
        _ = self.editor.attachments(pickup: attachment).done { [weak self] in
            let number = self?.attachmentView?.datas.count ?? 0
            self?.controller.updateAttachmentCount(number: number)
        }
    }
}

extension ComposeContainerViewCoordinator: ComposePasswordDelegate {
    func apply(password: String, confirmPassword: String, hint: String) {
        self.editor.encryptionPassword = password
        self.editor.encryptionConfirmPassword = confirmPassword
        self.editor.encryptionPasswordHint = hint
        self.editor.updateEO()
        self.controller.setLockStatus(isLock: true)
    }
    
    func removedPassword() {
        self.editor.encryptionPassword = ""
        self.editor.encryptionConfirmPassword = ""
        self.editor.encryptionPasswordHint = ""
        self.editor.updateEO()
        self.controller.setLockStatus(isLock: false)
    }
}

extension ComposeContainerViewCoordinator: ComposeExpirationDelegate {
    func update(expiration: TimeInterval) {
        self.header.expirationTimeInterval = expiration
        self.controller.setExpirationStatus(isSetting: expiration > 0)
    }
}

extension ComposeContainerViewCoordinator: ComposerAttachmentVCDelegate {
    func delete(attachment: Attachment) {
        self.editor.view.endEditing(true)
        self.header.view.endEditing(true)
        self.controller.view.endEditing(true)
        _ = self.editor.attachments(deleted: attachment).done { [weak self] in
            let number = self?.attachmentView?.datas.count ?? 0
            self?.controller.updateAttachmentCount(number: number)
            self?.controller.updateCurrentAttachmentSize()
        }
    }
}
