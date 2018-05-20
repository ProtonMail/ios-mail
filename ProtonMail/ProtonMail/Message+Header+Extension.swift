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
