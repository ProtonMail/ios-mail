//
//  ContractVO.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
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


import Foundation
import PMCommon
import PromiseKit
import AwaitKit


enum SignStatus : Int {
    case ok = 0 /// normal outgoing
    case notSigned = 1
    case noVerifier = 2
    case failed = 3
}

 enum PGPType : Int {
    //Do not use -1, this value will break the locker check function
    case failed_validation = -3 // not pass FE validation
    case failed_server_validation = -2 // not pass BE validation
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
    
    @objc var contactTitle : String {
        get {
            return title
        }
    }
    @objc var contactSubtitle : String? {
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
            case .none, .failed_server_validation, .failed_validation:
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
                 .none,
                 .failed_server_validation,
                 .failed_validation:
                return ""
            }
        }
    }
    
    var sentNotes: String {
        get {
            switch self.pgpType {
            case .none, .failed_server_validation, .failed_validation:
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
            case .none, .failed_server_validation, .failed_validation:
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
    func lockCheck(api: APIService, contactService: ContactDataService, progress: () -> Void, complete: LockCheckComplete?) {
        progress()
        async {
            let getEmail: Promise<KeysResponse> = api.run(route: UserEmailPubKeys(email: self.email))
            let getContact = contactService.fetch(byEmails: [self.email], context: nil)
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
            }.catch(policy: .allErrors) { (error) in
                PMLog.D(error.localizedDescription)
                complete?(nil, -1)
            }
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
    
    override public var hash: Int {
        return (name + email).hashValue
    }
}

//Extension::Array - contact vo
extension Array where Element: ContactVO {
    mutating func distinctMerge(_ check : [Element]) {
        var objectToIgnore: [Element] = []
        for element in self {
            objectToIgnore.append(contentsOf: check.filter { $0 == element })
        }

        for element in check {
            if !objectToIgnore.contains(element) {
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
