//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

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
    case none = 0 /// normal outgoing
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
}

public class ContactVO: NSObject, ContactPickerModelProtocol {

    public struct Attributes {
        static public let email = "email"
    }

    public var title: String
    public var subtitle: String
    public var contactId: String
    public var name: String!
    @objc public var email: String!
    public var isProtonMailContact: Bool = false
    
    
    //
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
                return UIImage(named: "pgp_clear_sign_failed")
            case .internal_trusted_key_verify_failed:
                return UIImage(named: "internal_sign_failed")
            case .internal_normal_verify_failed:
                return UIImage(named: "internal_sign_failed")
            case .pgp_encrypted:
                return UIImage(named: "pgp_encrypted")
            case .none:
                return nil
            }
        }
    }
    
    
    var hasPGPPined : Bool {
        get {
            switch self.pgpType {
            case .pgp_encrypt_trusted_key,
                 .pgp_encrypted,
                 .eo,
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
                 .none:
                return ""
            }
        }
    }
    
    var sentNotes: String {
        get {
            switch self.pgpType {
            case .none, .eo:
                return LocalString._stored_with_zero_access_encryption
                
            case .internal_normal: //PM --> PM (encrypted+signed)
                return LocalString._sent_by_you_with_end_to_end_encryption
            case .internal_trusted_key: //PM --> PM (encrypted+signed/pinned)
                return LocalString._sent_by_you_with_end_to_end_encryption
                
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
            }
        }
    }
    
    var inboxNotes: String {
        get {
            switch self.pgpType {
            case .none:
                return LocalString._stored_with_zero_access_encryption
            case .eo:
                return LocalString._encrypted_outside
                
            case .internal_normal: //PM --> PM (encrypted+signed)
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
                complete?(nil)
            }.catch({ (error) in
                PMLog.D(error.localizedDescription)
                complete?(nil)
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
        return "\(name) \(email)"
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? ContactVO else {
            return false
        }
        let lhs = self
        
        return lhs.email == rhs.email
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
