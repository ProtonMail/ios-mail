//
//  MessageHeaderViewCoordinator.swift
//  ProtonMail - Created on 15/03/2019.
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

class MessageHeaderViewCoordinator {
    private let kToComposerSegue : String    = "toCompose"
    private let kToAddContactSegue : String  = "toAddContact"
    
    private weak var controller: MessageHeaderViewController!
    
    init(controller: MessageHeaderViewController) {
        self.controller = controller
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
                let composeViewController = segue.destination.children[0] as! ComposeViewController
                sharedVMService.newDraft(vmp: composeViewController)
                let viewModel = ComposeViewModelImpl(msg: nil, action: ComposeMessageAction.newDraft)
                viewModel.addToContacts(contact)
                let coordinator = ComposeCoordinator(vc: composeViewController,
                                                     vm: viewModel, services: ServiceFactory.default) //set view model
                coordinator.start()
            
        } else if segue.identifier == kToAddContactSegue {
            if let contact = sender as? ContactVO {
                let addContactViewController = segue.destination.children[0] as! ContactEditViewController
                sharedVMService.contactAddViewModel(addContactViewController, contactVO: contact)
            }
        }
    }
}

extension MessageHeaderViewCoordinator: CoordinatorNew {
    func start() {
        // ?
    }
}
