//
//  MessageHeaderViewCoordinator.swift
//  ProtonMail - Created on 15/03/2019.
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

class MessageHeaderViewCoordinator {
    private let kToComposerSegue : String    = "toCompose"
    private let kToAddContactSegue : String  = "toAddContact"
    
    private weak var controller: MessageHeaderViewController!
    private let user: UserManager
    private let coreDataService: CoreDataService
    
    init(controller: MessageHeaderViewController, coreDataService: CoreDataService) {
        self.controller = controller
        self.user = controller.viewModel.user
        self.coreDataService = coreDataService
    }
    
    func recipientView(at cell: RecipientCell, arrowClicked arrow: UIButton, model: ContactPickerModelProtocol) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        
        alertController.addAction(UIAlertAction(title: LocalString._copy_address, style: .default, handler: { (action) -> Void in
            UIPasteboard.general.string = model.displayEmail
        }))
        alertController.addAction(UIAlertAction(title: LocalString._copy_name, style: .default, handler: { (action) -> Void in
            UIPasteboard.general.string = model.displayName
        }))
        alertController.addAction(UIAlertAction(title: LocalString._compose_to, style: .default, handler: { (action) -> Void in
            let contactVO = ContactVO(id: "",
                                      name: model.displayName,
                                      email: model.displayEmail,
                                      isProtonMailContact: false)
            self.controller.performSegue(withIdentifier: self.kToComposerSegue, sender: contactVO)
        }))
        alertController.addAction(UIAlertAction(title: LocalString._add_to_contacts, style: .default, handler: { (action) -> Void in
            let contactVO = ContactVO(id: "",
                                      name: model.displayName,
                                      email: model.displayEmail,
                                      isProtonMailContact: false)
            self.controller.performSegue(withIdentifier: self.kToAddContactSegue, sender: contactVO)
        }))
        alertController.popoverPresentationController?.sourceView = arrow
        alertController.popoverPresentationController?.sourceRect = arrow.frame
        
        self.controller.present(alertController, animated: true, completion: nil)
    }
    
    func recipientView(at cell: RecipientCell, lockClicked lock: UIButton, model: ContactPickerModelProtocol) {
        self.controller.viewModel.notes(for: model).alertToastBottom()
    }
    
    internal func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kToComposerSegue, let contact = sender as? ContactVO {
            let viewModel = ContainableComposeViewModel(msg: nil, action: .newDraft,
                                                        msgService: self.user.messageService,
                                                        user: self.user,
                                                        coreDataService: self.coreDataService)
            viewModel.addToContacts(contact)
            
            guard let navigator = segue.destination as? UINavigationController,
                let next = navigator.viewControllers.first as? ComposeContainerViewController else
            {
                assert(false, "Wrong root view controller in Compose storyboard")
                return
            }
            next.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel))
            next.set(coordinator: ComposeContainerViewCoordinator(controller: next))
            
        } else if segue.identifier == kToAddContactSegue {
            if let contact = sender as? ContactVO {
                let addContactViewController = segue.destination.children[0] as! ContactEditViewController
                sharedVMService.contactAddViewModel(addContactViewController, user: self.user, contactVO: contact)
            }
        }
    }
}

extension MessageHeaderViewCoordinator: CoordinatorNew {
    func start() {
        // ?
    }
}
