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
    func getInboxType(email : String, signature : SignType) -> PGPType {

        guard self.isDetailDownloaded  else {
            return .none
        }
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
        
        if isEncrypted == 1 {
            return .internal_normal
        }
        
        if isEncrypted == 2 {
            //return a different value if signed
            return .none
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
        
        if self.senderAddress == email {
            return .internal_normal
        }
        
        guard self.isDetailDownloaded  else {
            return .none
        }
        
        guard let header = self.header, let parsedMime = MIMEMessage(string: header) else {
            return .none
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
        
        
        if authtype == "pgp-inline" {
            if enctype == "pgp-inline-pinned" {
                return .pgp_encrypt_trusted_key
            }
            return .pgp_signed
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
            }
            return .pgp_encrypted
        }
        
        return .none
        
        
    }
    


}
