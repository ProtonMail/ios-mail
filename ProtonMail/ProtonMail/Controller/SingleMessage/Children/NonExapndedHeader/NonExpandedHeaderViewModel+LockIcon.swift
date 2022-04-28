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
        guard let c = message.sender else { return }
        
        if self.message.contains(location: .sent) {
            c.pgpType = self.message.getSentLockType(email: c.displayEmail ?? "")
            self.senderContact = c
            complete?(c.pgpType.lockImage, c.pgpType.rawValue)
            return
        }

        c.pgpType = self.message.getInboxType()
        if self.message.checkedSign {
            c.pgpType = self.message.pgpType
            self.senderContact = c
            complete?(c.pgpType.lockImage, c.pgpType.rawValue)
            return
        }

        guard let emial = c.displayEmail else {
            complete?(nil, -1)
            return
        }

        let getEmail: Promise<KeysResponse> = user.apiService.run(route: UserEmailPubKeys(email: emial))
        let contactService = self.user.contactService
        let getContact = contactService.fetch(byEmails: [emial])
        when(fulfilled: getEmail, getContact).done { [weak self] keyRes, contacts in
            guard let self = self else { return }
            var status: SignatureVerificationResult?
            if let contact = contacts.first {
                status = self.user.messageService
                    .messageDecrypter
                    .verify(message: self.message, verifier: contact.pgpKeys)
            }
            defer {
                // todo, think a way to cached the verified value
    //            self.message.pgpType = c.pgpType
    //            self.message.checkedSign = true
                self.senderContact = c
                complete?(c.pgpType.lockImage, c.pgpType.rawValue)
            }
            guard let status = status else { return }

            if keyRes.recipientType == 1 {
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
            } else {
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
        }.catch(policy: .allErrors) { error in
            complete?(nil, -1)
        }
    }
}
