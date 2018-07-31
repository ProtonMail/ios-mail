//
//  Message+Header.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/20/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


extension Message {
    //
    //        case plain = 0          //Plain text
    //        case inner = 1       // ProtonMail encrypted emails
    //        case external = 2       // Encrypted from outside
    //        case outEnc = 3         // Encrypted for outside
    //        case outPlain = 4       // Send plain but stored enc
    //        case draftStoreEnc = 5  // Draft
    //        case outEncReply = 6    // Encrypted for outside reply
    //
    //        case outPGPInline = 7    // out side pgp inline
    //        case outPGPMime = 8    // out pgp mime
    //        case outSignedPGPMime = 9 //PGP/MIME signed message
    
    func getInboxType(email : String, signature : SignStatus) -> PGPType {
        guard self.isDetailDownloaded  else {
            return .none
        }
        
        if isEncrypted == 1 {
            return .internal_normal
        }
        
        if isEncrypted == 2 {
            //return a different value if signed
            return .zero_access_store
        }
        
        if isEncrypted == 7 {
            return .pgp_encrypted
        }
        
        if isEncrypted == 8 {
            return .pgp_encrypted
        }
        
        if isEncrypted == 9 {
            return .pgp_signed
        }
        
        return .none
    }
    
    func getSentLockType(email : String) -> PGPType {
        guard self.isDetailDownloaded  else {
            return .none
        }
        
        guard let header = self.header, let parsedMime = MIMEMessage(string: header) else {
            return .none
        }
        
        let autoReply = parsedMime.mainPart.headers.first { (left) -> Bool in
            return left.name == "X-Autoreply"
        }
        
        if self.senderAddress == email {
            
            var autoreply = false
            if let body = autoReply?.body, body == "yes" {
                autoreply = true
            }
            if autoreply {
                return .sent_sender_server
            }
            if self.unencrypt_outside {
                return .sent_sender_out_side
            }
            return .sent_sender_encrypted
        }
        
        let authentication = parsedMime.mainPart.headers.first { (left) -> Bool in
            return left.name == "X-Pm-Recipient-Authentication"
        }
        
        let encryption = parsedMime.mainPart.headers.first { (left) -> Bool in
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
