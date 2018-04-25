//
//  EncryptTypes.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/26/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

enum EncryptTypes: Int, CustomStringConvertible {
    case plain = 0          //Plain text
    case inner = 1       // ProtonMail encrypted emails
    case external = 2       // Encrypted from outside
    case outEnc = 3         // Encrypted for outside
    case outPlain = 4       // Send plain but stored enc
    case draftStoreEnc = 5  // Draft
    case outEncReply = 6    // Encrypted for outside reply
    
    case outPGPInline = 7    // out side pgp inline
    case outPGPMime = 8    // out pgp mime
    case outSignedPGPMime = 9 //PGP/MIME signed message
    
    // didn't in localizable string because no place show this yet
    var description : String {
        switch(self){
        case .plain:
            return LocalString._general_enc_type_plain_text
        case .inner:
            return LocalString._general_enc_pm_emails
        case .external:
            return LocalString._general_enc_from_outside
        case .outEnc:
            return LocalString._general_enc_for_outside
        case .outPlain:
            return LocalString._general_send_plain_but_stored_enc
        case .draftStoreEnc:
            return LocalString._general_draft_action
        case .outEncReply:
            return LocalString._general_encrypted_for_outside_reply
        case .outPGPInline:
            return LocalString._general_enc_from_outside_pgp_inline
        case .outPGPMime:
            return LocalString._general_enc_from_outside_pgp_mime
        case .outSignedPGPMime:
            return LocalString._general_enc_from_outside_signed_pgp_mime
        }
    }
    
    var isEncrypted: Bool {
        switch(self) {
        case .plain:
            return false
        default:
            return true
        }
    }
    
    var lockType : LockTypes {
        switch(self) {
        case .plain, .outPlain, .external:
            return .plainTextLock
        case .inner, .outEnc, .draftStoreEnc, .outEncReply:
            return .encryptLock
        case .outPGPInline, .outPGPMime, .outSignedPGPMime:
            return .pgpLock
        }
    }
}

enum LockTypes : Int {
    case plainTextLock = 0
    case encryptLock = 1
    case pgpLock = 2
}


extension NSNumber {
    
    func isEncrypted() -> Bool {
        let enc_type = EncryptTypes(rawValue: self.intValue) ?? .inner
        let checkIsEncrypted:Bool = enc_type.isEncrypted

        return checkIsEncrypted
    }
    
}
