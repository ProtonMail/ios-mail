//
//  Message+Header.swift
//  ProtonMail
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

extension Message {

    //case plain = 0            //Plain text
    //case inner = 1            // ProtonMail encrypted emails
    //case external = 2         // Encrypted from outside
    //case outEnc = 3           // Encrypted for outside
    //case outPlain = 4         // Send plain but stored enc
    //case draftStoreEnc = 5    // Draft
    //case outEncReply = 6      // Encrypted for outside reply
    //
    //case outPGPInline = 7     // out side pgp inline
    //case outPGPMime = 8       // out pgp mime
    //case outSignedPGPMime = 9 //PGP/MIME signed message
    
    func getInboxType(email : String, signature : SignStatus) -> PGPType {
        guard self.isDetailDownloaded else {
            return .none
        }
        
        if self.isInternal {
            return .internal_normal
        }
        
        if isE2E { //outPGPInline, outPGPMime
            return .pgp_encrypted
        }
        
        if isSignedMime { //outSignedPGPMime
            return .zero_access_store
        }
        
        if self.isExternal {
            return .zero_access_store
        }
        
        return .none
    }
    
    func getSentLockType(email : String) -> PGPType {
        PMLog.D(self.flag.description)
        
        guard self.isDetailDownloaded  else {
            return .none
        }
        
        guard let header = self.header, let raw = header.data(using: .utf8), let mainPart = Part(header: raw) else {
            return .none
        }
        
        PMLog.D(header)
        
        let autoReply = mainPart.headers.first { (left) -> Bool in
            return left.name == "X-Autoreply"
        }
        
        if self.senderContactVO.email == email {
            //TODO:: use flags to check auto reply
            var autoreply = false
            if let body = autoReply?.body, body == "yes" {
                autoreply = true
            }
            if autoreply {
                return .sent_sender_server
            }
            
            if !self.unencrypt_outside {
                let encryption = mainPart.headers.first { (left) -> Bool in
                    return left.name == "X-Pm-Recipient-Encryption"
                }
                if let enc = encryption {
                    for (_, enctype) in enc.headerKeyValues {
                        if enctype == "none" {
                            self.unencrypt_outside = true
                            break
                        }
                    }
                }
            }
            
            if self.unencrypt_outside {
                return .sent_sender_out_side
            }
            return .sent_sender_encrypted
        }
        
        let authentication = mainPart.headers.first { (left) -> Bool in
            return left.name == "X-Pm-Recipient-Authentication"
        }
        
        let encryption = mainPart.headers.first { (left) -> Bool in
            return left.name == "X-Pm-Recipient-Encryption"
        }

        guard let auth = authentication, let enc = encryption else {
            return .none
        }
        
        guard let authtype = auth.headerKeyValues[email], let enctype = enc.headerKeyValues[email] else {
            return .none
        }
        
        if enctype == "none" {
            self.unencrypt_outside = true
        }
        
        
        if authtype == "pgp-inline" {
            if enctype == "pgp-inline-pinned" {
                return .pgp_encrypt_trusted_key
            } else if enctype == "none" {
                return .pgp_signed
            }
            return .pgp_encrypted
        }
        
        if authtype == "pgp-pm" {
            if enctype == "pgp-pm-pinned" {
                return .internal_trusted_key
            }
            return .internal_normal
        }
        
        if authtype == "pgp-mime" {
            if enctype == "pgp-mime-pinned" {
                return .pgp_encrypt_trusted_key
            } else if enctype == "none" {
                return .pgp_signed
            }
            return .pgp_encrypted
        }
        
        if authtype == "pgp-eo" {
            return .eo
        }
        
        if authtype == "none" {
            if enctype == "pgp-pm" {
                return .internal_normal
            }
            if enctype == "pgp-mime" || enctype == "pgp-inline" {
                return .pgp_encrypted
            }
            if enctype == "pgp-mime-pinned" || enctype == "pgp-inline-pinned" {
                return .pgp_encrypt_trusted_key
            }
            if enctype == "pgp-pm-pinned" {
                return .internal_trusted_key
            }
            
            return .none
        }
        
        return .none
        
        
    }
    


}
