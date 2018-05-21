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


struct SignType : OptionSet {
    let rawValue: Int
    
    static let no_sign       = SignType(rawValue: 0)
    static let verify_failed = SignType(rawValue: 1 << 0)
    static let verify_ok     = SignType(rawValue: 1 << 1)
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
            case .none:
                return nil
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
            }
        }
    }

    var composerNotes: String {
        get {
            switch self.pgpType {
            case .none:
                return ""
            case .eo:
                return "End-to-end encrypted"
            case .internal_normal: //PM --> PM (encrypted+signed)
                return "End-to-end encrypted"
            case .internal_trusted_key: //PM --> PM (encrypted+signed/pinned)
                return "End-to-end encrypted to verified address"
            case .pgp_encrypt_trusted_key:
                return "PGP-encrypted"
            case .pgp_signed://PM --> non-PM PGP (signed)
                return "PGP-signed"
            case .pgp_encrypt_trusted_key_verify_failed: //PM --> non-PM PGP (encrypted+signed/pinned)
                return "PGP-encrypted"
            case .internal_trusted_key_verify_failed:
                return "Sender Verification Failed"
            case .internal_normal_verify_failed:
                return "Sender Verification Failed"
            case .pgp_signed_verify_failed:
                return "Sender Verification Failed"
            case .pgp_encrypted:
                return ""
            }
        }
    }
    
    var sentNotes: String {
        get {
            switch self.pgpType {
            case .internal_normal: //PM --> PM (encrypted+signed)
                return "End-to-end encrypted"
            case .internal_trusted_key: //PM --> PM (encrypted+signed/pinned)
                return "End-to-end encrypted to verified address"
            case .pgp_encrypt_trusted_key:
                return "PGP-encrypted"
            case .pgp_signed://non-PM signed PGP --> PM (pinned)
                return "PGP-signed message from verified address"
            case .none:
                return "Stored with zero access encryption"
            case .pgp_encrypt_trusted_key_verify_failed: //non-PM signed+encrypted PGP --> PM (pinned)
                return "PGP-encrypted message from verified address"
            case .internal_trusted_key_verify_failed:
                return "Sender Verification Failed"
            case .internal_normal_verify_failed:
                return "Sender Verification Failed"
            case .pgp_signed_verify_failed:
                return "Sender Verification Failed"
            case .eo:
                return "Encrypted outside"
            case .pgp_encrypted:
                return ""
            }
        }
    }
    
    var inboxNotes: String {
        get {
            switch self.pgpType {
            case .internal_normal: //PM --> PM (encrypted+signed)
                return "End-to-end encrypted"
            case .internal_trusted_key: //PM --> PM (encrypted+signed/pinned)
                return "End-to-end encrypted to verified address"
            case .pgp_encrypt_trusted_key:
                return "PGP-encrypted"
            case .pgp_signed://non-PM signed PGP --> PM (pinned)
                return "PGP-signed message from verified address"
            case .none:
                return "Stored with zero access encryption"
            case .pgp_encrypt_trusted_key_verify_failed: //non-PM signed+encrypted PGP --> PM (pinned)
                return "PGP-encrypted message from verified address"
            case .internal_trusted_key_verify_failed:
                return "Sender Verification Failed"
            case .internal_normal_verify_failed:
                return "Sender Verification Failed"
            case .pgp_signed_verify_failed:
                return "Sender Verification Failed"
            case .eo:
                return "Encrypted outside"
            case .pgp_encrypted:
                return ""
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
                    if let contact = contacts.first, contact.pgpKey != nil {
                        self.pgpType = .internal_trusted_key
                    } else {
                        self.pgpType = .internal_normal
                    }
                } else {
                    if let contact = contacts.first, contact.pgpKey != nil {
                        if contact.encrypt {
                            self.pgpType = .pgp_encrypt_trusted_key
                        } else if contact.sign {
                            self.pgpType = .pgp_signed
                        }
                    }
                }
                complete?()
            }.catch({ (error) in
                complete?()
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
