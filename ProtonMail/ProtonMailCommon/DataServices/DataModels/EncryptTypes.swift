//
//  EncryptTypes.swift
//  ProtonMail - Created on 3/26/15.
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
