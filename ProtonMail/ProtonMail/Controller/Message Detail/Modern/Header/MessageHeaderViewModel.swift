//
//  MessageHeaderViewModel.swift
//  ProtonMail - Created on 08/03/2019.
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
import PromiseKit

class MessageHeaderViewModel: NSObject {
    @objc dynamic var headerData: HeaderData
    @objc internal dynamic var contentsHeight: CGFloat = 0.0
    private var message: Message
    private var observation: NSKeyValueObservation!
    
    init(parentViewModel: Standalone, message: Message) {
        self.message = message
        self.headerData = parentViewModel.header
        
        super.init()
        
        self.observation = parentViewModel.observe(\.header) { [weak self] parentViewModel, _ in
            self?.headerData = parentViewModel.header
        }
    }
}

extension MessageHeaderViewModel {
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
                            let context = sharedCoreDataService.backgroundManagedObjectContext
                            let getEmail = UserEmailPubKeys(email: emial).run()
                            let getContact = sharedContactDataService.fetch(byEmails: [emial], context: context)
                            when(fulfilled: getEmail, getContact).done { keyRes, contacts in
                                //internal emails
                                if keyRes.recipientType == 1 {
                                    if let contact = contacts.first, let pgpKeys = contact.pgpKeys {
                                        let status = self.message.verifyBody(verifier: pgpKeys, passphrase: sharedUserDataService.mailboxPassword!)
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
                                        let status = self.message.verifyBody(verifier: pgpKeys, passphrase: sharedUserDataService.mailboxPassword!)
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
