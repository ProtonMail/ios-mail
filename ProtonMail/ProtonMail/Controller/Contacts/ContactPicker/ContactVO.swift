//
//  ContractVO.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import PromiseKit
import ProtonCore_Services

enum SignatureVerificationResult: Int {
    case ok = 0 /// normal outgoing
    case notSigned = 1
    case noVerifier = 2
    case failed = 3
}

enum PGPTypeErrorCode: Int {
    case recipientNotFound = 33102
    case emailAddressFailedValidation = 33101
}

class ContactVO: NSObject, ContactPickerModelProtocol {
    let title: String
    let subtitle: String
    let contactId: String
    let name: String
    let email: String
    let isProtonMailContact: Bool

    var modelType: ContactPickerModelState {
        get {
            return .contact
        }
    }

    @objc var contactTitle: String {
        get {
            return title
        }
    }
    @objc var contactSubtitle: String? {
        get {
            return subtitle
        }
    }
    var contactImage: UIImage? {
        get {
            return nil
        }
    }

    var color: String? {
        get {
            return nil
        }
    }

    var displayName: String? {
        get {
            return name
        }
    }

    var displayEmail: String? {
        get {
            return email
        }
    }

    var encryptionIconStatus: EncryptionIconStatus?

    var hasPGPPined: Bool {
        return encryptionIconStatus?.isPGPPinned ?? false
    }

    var hasNonePM: Bool {
        return encryptionIconStatus?.isNonePM ?? true
    }

    init(id: String = "", name: String, email: String, isProtonMailContact: Bool = false) {
        self.contactId = id
        self.name = name
        self.email = email
        self.isProtonMailContact = isProtonMailContact

        self.title = !name.isEmpty && name != " " ? name : email
        self.subtitle = email
    }

    override var description: String {
        return "\(name) \(email)"
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? ContactVO else {
            return false
        }
        let lhs = self

        return lhs.name + lhs.email == rhs.name + rhs.email
    }

    func equals(_ other: ContactPickerModelProtocol) -> Bool {
        return self.isEqual(other)
    }

    override var hash: Int {
        return (name + email).hashValue
    }
}

extension ContactVO {
    func copy(with zone: NSZone? = nil) -> Any {
        let contact = ContactVO(id: contactId, name: name, email: email, isProtonMailContact: isProtonMailContact)
        return contact
    }
}
