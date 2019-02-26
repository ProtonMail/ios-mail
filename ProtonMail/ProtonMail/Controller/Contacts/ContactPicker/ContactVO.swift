//
//  ContractVO.swift
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

import PromiseKit
import AwaitKit


enum SignStatus : Int {
    case ok = 0 /// normal outgoing
    case notSigned = 1
    case noVerifier = 2
    case failed = 3
}

 enum PGPType : Int {
    case none = 0 /// default none
    case pgp_signed = 1 /// external pgp signed only
    case pgp_encrypt_trusted_key = 2 /// external encrypted and signed with trusted key
    case internal_normal = 3 /// protonmail normal keys
    case internal_trusted_key = 4  /// trusted key
    case pgp_encrypt_trusted_key_verify_failed = 6
    case internal_trusted_key_verify_failed = 7
    case internal_normal_verify_failed = 8
    case pgp_signed_verify_failed = 9
    case eo = 10
    case pgp_encrypted = 11
    case sent_sender_out_side = 12
    case sent_sender_encrypted = 13
    case zero_access_store = 14
    case sent_sender_server = 15
    case pgp_signed_verified = 16
}

public class ContactVO: NSObject, ContactPickerModelProtocol {

    public struct Attributes {
        static public let email = "email"
    }

    public var title: String
    public var subtitle: String
    public var contactId: String
    public var name: String
    @objc public var email: String!
    public var isProtonMailContact: Bool = false
    
    var modelType: ContactPickerModelState {
        get {
            return .contact
        }
    }
    
    var contactTitle : String {
        get {
            return title
        }
    }
    var contactSubtitle : String? {
        get {
            return subtitle
        }
    }
    var contactImage : UIImage? {
        get {
            return nil
        }
    }
    
    var color: String? {
        get {
            return nil
        }
    }
    

    var displayName : String? {
        get {
            return name
        }
    }
    
    var displayEmail : String? {
        get {
            return email
        }
    }
    
    var pgpType: PGPType = .none
    
    func setType(type: Int) {
        if let pgp_type = PGPType(rawValue: type) {
            self.pgpType = pgp_type
        }
    }
    
    func notes(type: Int) -> String {
        //0 composer, 1 inbox 2 sent
        if type == 1 {
            return self.inboxNotes
        } else if type == 2 {
            return self.sentNotes
        }
        return self.composerNotes
    }
    
    var lock: UIImage? {
        get {
            switch self.pgpType {
            case .internal_normal, .eo:
                return UIImage(named: "internal_normal")
            case .internal_trusted_key:
                return UIImage(named: "internal_trusted_key")
            case .pgp_encrypt_trusted_key:
                return UIImage(named: "pgp_encrypt_trusted_key")
            case .pgp_signed:
                return UIImage(named: "pgp_signed")
            case .pgp_encrypt_trusted_key_verify_failed:
                return UIImage(named: "pgp_trusted_sign_failed")
            case .pgp_signed_verify_failed:
                return UIImage(named: "pgp_signed_verify_failed")
            case .internal_trusted_key_verify_failed:
                return UIImage(named: "internal_sign_failed")
            case .internal_normal_verify_failed:
                return UIImage(named: "internal_sign_failed")
            case .pgp_encrypted:
                return UIImage(named: "pgp_encrypted")
            case .none:
                return nil
            case .sent_sender_out_side,
                 .zero_access_store:
                return UIImage(named: "zero_access_encryption")
            case .sent_sender_encrypted:
                return UIImage(named: "internal_normal")
            case .sent_sender_server:
                return UIImage(named: "internal_normal")
            case .pgp_signed_verified:
                return UIImage(named: "pgp_signed_verified")
            }
        }
    }
    
    
    var hasPGPPined : Bool {
        get {
            switch self.pgpType {
            case .pgp_encrypt_trusted_key,
                 .pgp_encrypted,
                 .pgp_encrypt_trusted_key_verify_failed:
                return true
            default:
                return false
            }
        }
    }
    var hasNonePM : Bool {
        get {
            switch self.pgpType {
            case .internal_normal,
                 .internal_trusted_key,
                 .internal_normal_verify_failed,
                 .internal_trusted_key_verify_failed:
                return false
            case .pgp_encrypt_trusted_key,
                 .pgp_encrypted,
                 .pgp_encrypt_trusted_key_verify_failed:
                return false
            default:
                return true
            }
        }
    }

    var composerNotes: String {
        get {
            switch self.pgpType {
            case .eo:
                return LocalString._end_to_end_encrypted
            case .pgp_encrypt_trusted_key: //PM --> non-PM PGP (encrypted+signed/pinned)
                return LocalString._pgp_encrypted
            case .pgp_signed://PM --> non-PM PGP (signed)
                return LocalString._pgp_signed
            case .pgp_encrypted: //not for composer but in case
                return LocalString._pgp_encrypted
                
            case .internal_normal: //PM --> PM (encrypted+signed)
                return LocalString._end_to_end_encrypted
            case .internal_trusted_key: //PM --> PM (encrypted+signed/pinned)
                return LocalString._end_to_end_encrypted_to_verified_address
                
            case .pgp_encrypt_trusted_key_verify_failed,
                 .internal_trusted_key_verify_failed,
                 .internal_normal_verify_failed,
                 .pgp_signed_verify_failed,
                 .sent_sender_out_side,
                 .sent_sender_encrypted,
                 .zero_access_store,
                 .sent_sender_server,
                 .pgp_signed_verified,
                 .none:
                return ""
            }
        }
    }
    
    var sentNotes: String {
        get {
            switch self.pgpType {
            case .none:
                return LocalString._stored_with_zero_access_encryption
            case .eo:
                return LocalString._end_to_end_encrypted
            case .internal_normal: //PM --> PM (encrypted+signed)
                return LocalString._end_to_end_encrypted
            case .internal_trusted_key: //PM --> PM (encrypted+signed/pinned)
                return LocalString._end_to_end_encrypted_to_verified_address
            case .pgp_encrypted:
                return LocalString._pgp_encrypted_message
            case .pgp_encrypt_trusted_key:
                return LocalString._pgp_encrypted
            case .pgp_signed://non-PM signed PGP --> PM (pinned)
                return LocalString._pgp_signed
            case .pgp_encrypt_trusted_key_verify_failed,
                 .internal_trusted_key_verify_failed,
                 .internal_normal_verify_failed,
                 .pgp_signed_verify_failed:
                return LocalString._sender_verification_failed
            case .sent_sender_out_side:
                return LocalString._stored_with_zero_access_encryption
            case .sent_sender_encrypted:
                return LocalString._sent_by_you_with_end_to_end_encryption
            case .zero_access_store:
                return LocalString._stored_with_zero_access_encryption
            case .sent_sender_server:
                return LocalString._sent_by_protonMail_with_zero_access_encryption
            case .pgp_signed_verified:
                return LocalString._pgp_signed_message_from_verified_address
            }
        }
    }
    
    var inboxNotes: String {
        get {
            switch self.pgpType {
            case .none:
                return LocalString._stored_with_zero_access_encryption
            case .eo, .internal_normal: //PM --> PM (encrypted+signed)
                return LocalString._end_to_end_encrypted_message
            case .internal_trusted_key: //PM --> PM (encrypted+signed/pinned)
                return LocalString._end_to_end_encrypted_message_from_verified_address
                
            case .pgp_encrypted:
                return LocalString._pgp_encrypted_message
            case .pgp_encrypt_trusted_key:
                return LocalString._pgp_encrypted_message_from_verified_address
            case .pgp_signed://non-PM signed PGP --> PM (pinned)
                return LocalString._pgp_signed_message_from_verified_address
                
            case .pgp_encrypt_trusted_key_verify_failed,
                 .internal_trusted_key_verify_failed,
                 .internal_normal_verify_failed,
                 .pgp_signed_verify_failed:
                return LocalString._sender_verification_failed
            case .sent_sender_out_side:
                return LocalString._end_to_end_encrypted_message
            case .sent_sender_encrypted:
                return LocalString._end_to_end_encrypted_message
            case .zero_access_store:
                return LocalString._stored_with_zero_access_encryption
            case .sent_sender_server:
                return LocalString._sent_by_protonMail_with_zero_access_encryption
            case .pgp_signed_verified:
                return LocalString._pgp_signed_message_from_verified_address
            }
        }
    }

    
    /**
     This is a temp function here. the fetch action or network should be in a model manager class. TODO:: later
     
     - Parameter progress: in progress ()-> Void
     - Parameter complete: complete ()-> Void
     **/
    func lockCheck(progress: () -> Void, complete: LockCheckComplete?) {
        progress()
        async {
            let getEmail = UserEmailPubKeys(email: self.email).run()
            let getContact = sharedContactDataService.fetch(byEmails: [self.email], context: nil)
            when(fulfilled: getEmail, getContact).done { keyRes, contacts in
                //internal emails
                if keyRes.recipientType == 1 {
                    if let contact = contacts.first, contact.firstPgpKey != nil {
                        self.pgpType = .internal_trusted_key
                    } else {
                        self.pgpType = .internal_normal
                    }
                } else {
                    if let contact = contacts.first, contact.firstPgpKey != nil {
                        if contact.encrypt {
                            self.pgpType = .pgp_encrypt_trusted_key
                        } else if contact.sign {
                            self.pgpType = .pgp_signed
                        }
                    }
                }
                complete?(nil, -1)
            }.catch({ (error) in
                PMLog.D(error.localizedDescription)
                complete?(nil, -1)
            })
        }
        
    }
    
    public init(id: String! = "", name: String!, email: String!, isProtonMailContact: Bool = false) {
        self.contactId = id
        self.name = name
        self.email = email
        self.isProtonMailContact = isProtonMailContact
        
        self.title = !name.isEmpty && name != " " ? name : email
        self.subtitle = email
    }
    
    override public var description: String {
        return "\(name) \(email ?? "")"
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? ContactVO else {
            return false
        }
        let lhs = self
        
        return lhs.email == rhs.email
    }
    
    func equals(_ other: ContactPickerModelProtocol) -> Bool {
        return self.isEqual(other)
    }
}

//Extension::Array - contact vo
extension Array where Element: ContactVO {
    mutating func distinctMerge(_ check : [Element]) {
        for element in check {
            if self.contains(element) {
                
            } else {
                self.append(element)
            }
        }
    }
    
    public func uniq() -> [Element] {
        var arrayCopy = self
        arrayCopy.uniqInPlace()
        return arrayCopy
    }
    
    mutating internal func uniqInPlace() {
        var seen = [Element]()
        var index = 0
        for element in self {
            if seen.contains(element) {
                remove(at: index)
            } else {
                seen.append(element)
                index+=1
            }
        }
    }
}
