//
//  NonExpandedHeaderViewModel+LockIcon.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

import PromiseKit

extension NonExpandedHeaderViewModel { // FIXME: - To refactor MG

    func lockIcon(complete: LockCheckComplete?) {
        if let c = message.sender?.toContact() {
            if self.message.contains(label: .sent) {
                c.pgpType = self.message.getSentLockType(email: c.displayEmail ?? "")
                self.senderContact = c
                complete?(c.lock, c.pgpType.rawValue)
            } else {
                c.pgpType = self.message.getInboxType(email: c.displayEmail ?? "", signature: .notSigned)
                if self.message.checkedSign {
                    c.pgpType = self.message.pgpType
                    self.senderContact = c
                    complete?(c.lock, c.pgpType.rawValue)
                } else {
                    if self.message.checkingSign {

                    } else {
                        self.message.checkingSign = true
                        guard let emial = c.displayEmail else {
                            self.message.checkingSign = false
                            complete?(nil, -1)
                            return
                        }

                        let getEmail: Promise<KeysResponse> = user.apiService.run(route: UserEmailPubKeys(email: emial))
                        let contactService = self.user.contactService
                        let getContact = contactService.fetch(byEmails: [emial])
                        when(fulfilled: getEmail, getContact).done { [weak self] keyRes, contacts in
                            guard let self = self else { return }
                            if keyRes.recipientType == 1 {
                                if let contact = contacts.first {
                                    let status = self.user.messageService.verifyBody(
                                        self.message,
                                        verifier: contact.pgpKeys,
                                        passphrase: self.user.mailboxPassword
                                    )
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
                                if let contact = contacts.first {
                                    let status = self.user.messageService.verifyBody(
                                        self.message,
                                        verifier: contact.pgpKeys,
                                        passphrase: self.user.mailboxPassword
                                    )
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
                            self.senderContact = c
                            complete?(c.lock, c.pgpType.rawValue)
                        }.catch(policy: .allErrors) { error in
                            self.message.checkingSign = false
                            PMLog.D(error.localizedDescription)
                            complete?(nil, -1)
                        }
                    }
                }
            }
        }
    }

}
