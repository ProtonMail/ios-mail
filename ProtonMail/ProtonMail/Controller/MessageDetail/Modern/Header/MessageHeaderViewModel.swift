//
//  MessageHeaderViewModel.swift
//  ProtonMail - Created on 08/03/2019.
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
import PromiseKit

class MessageHeaderViewModel: NSObject {
    @objc dynamic var headerData: HeaderData
    @objc internal dynamic var contentsHeight: CGFloat = 0.0
    private var message: Message
    private(set) var parentViewModel: MessageViewModel 
    private var parentObservation: NSKeyValueObservation!
    private var messageObservation: NSKeyValueObservation!
    

    let messageService: MessageDataService
    let user : UserManager
    
    init(parentViewModel: MessageViewModel, message: Message) {
        self.message = message
        self.headerData = parentViewModel.header
        self.parentViewModel = parentViewModel
        self.messageService = parentViewModel.messageService
        self.user = parentViewModel.user
        super.init()
        
        self.parentObservation = parentViewModel.observe(\.header) { [weak self] parentViewModel, _ in
            self?.headerData = parentViewModel.header
        }
        self.messageObservation = message.observe(\.labels, options: [.old, .new]) { [weak self] message, change in
            guard change.newValue != change.oldValue else { return }
            self?.headerData = HeaderData(message: message)
        }
    }
    
    deinit {
        self.parentObservation = nil
        self.messageObservation = nil
    }
}

extension MessageHeaderViewModel {
    internal func star(_ isStarred: Bool) {
        self.messageService.label(message: self.message, label: Message.Location.starred.rawValue, apply: isStarred)
    }
    
    internal func notes(for model: ContactPickerModelProtocol) -> String {
        return model.notes(type: self.message.contains(label: .sent) ? 2 : 1)
    }
    
    // taken from old MessageViewController as-is
    internal func recipientView(lockCheck model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?) {
        if !self.message.isDetailDownloaded {
            progress()
        } else {
            //TODO:: put this to view model
            if let c = model as? ContactVO {
                if self.message.contains(label: .sent) {
                    c.pgpType = self.message.getSentLockType(email: c.displayEmail ?? "")
                    complete?(nil, -1)
                } else {
                    c.pgpType = self.message.getInboxType(email: c.displayEmail ?? "", signature: .notSigned)
                    if self.message.checkedSign {
                        c.pgpType = self.message.pgpType
                        complete?(nil, -1)
                    } else {
                        if self.message.checkingSign {
                            
                        } else {
                            self.message.checkingSign = true
                            guard let emial = model.displayEmail else {
                                self.message.checkingSign = false
                                complete?(nil, -1)
                                return
                            }
                            
                            let context = CoreDataService.shared.backgroundManagedObjectContext
                            let getEmail = UserEmailPubKeys(email: emial, api: user.apiService).run()
                            let contactService = self.user.contactService
                            let getContact = contactService.fetch(byEmails: [emial], context: context)
                            when(fulfilled: getEmail, getContact).done { keyRes, contacts in
                                //internal emails
                                if keyRes.recipientType == 1 {
                                    if let contact = contacts.first, let pgpKeys = contact.pgpKeys {
                                        let status = self.messageService.verifyBody(self.message, verifier: pgpKeys, passphrase: self.user.mailboxPassword)
                                        switch status {
                                        case .ok:
                                            c.pgpType = .internal_trusted_key
                                        case .notSigned:
                                            c.pgpType = .internal_normal
                                        case .noVerifier:
                                            c.pgpType = .internal_normal
                                        case .failed:
                                            c.pgpType = .internal_trusted_key_verify_failed
                                        }
                                    }
                                } else {
                                    if let contact = contacts.first, let pgpKeys = contact.pgpKeys {
                                        let status = self.messageService.verifyBody(self.message, verifier: pgpKeys, passphrase: self.user.mailboxPassword)
                                        switch status {
                                        case .ok:
                                            if c.pgpType == .zero_access_store {
                                                c.pgpType = .pgp_signed_verified
                                            } else {
                                                c.pgpType = .pgp_encrypt_trusted_key
                                            }
                                        case .notSigned, .noVerifier:
                                            break
                                        case .failed:
                                            if c.pgpType == .zero_access_store {
                                                c.pgpType = .pgp_signed_verify_failed
                                            } else {
                                                c.pgpType = .pgp_encrypt_trusted_key_verify_failed
                                            }
                                        }
                                    }
                                }
                                self.message.pgpType = c.pgpType
                                self.message.checkedSign = true
                                self.message.checkingSign = false
                                complete?(c.lock, c.pgpType.rawValue)
                            }.catch({ (error) in
                                self.message.checkingSign = false
                                PMLog.D(error.localizedDescription)
                                complete?(nil, -1)
                            })
                            
                        }
                    }
                }
            }
        }
    }
}
