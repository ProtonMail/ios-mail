//
//  ContactsAPI.swift
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

import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_Networking

struct ContactsAPI {
    static let path: String = "/contacts"
}

// MARK: Get contacts part -- ContactsResponse
class ContactsRequest: Request {
    var path: String {
        return ContactsAPI.path
    }
}

class ContactsResponse: Response {
    var total: Int = -1
    var contacts: [[String: Any]] = []
    override func ParseResponse (_ response: [String: Any]!) -> Bool {
        self.total = response?["Total"] as? Int ?? -1
        self.contacts = response?["Contacts"] as? [[String: Any]] ?? []
        return true
    }
}

// MARK: Get messages part
class ContactEmailsRequest: Request {  // ContactEmailsResponse
    var page: Int = 0
    var max: Int = 100
    let labelID: String?

    init(page: Int, pageSize: Int, labelID: String? = nil) {
        self.page = page
        self.max = pageSize
        self.labelID = labelID
    }

    var path: String {
        return ContactsAPI.path + "/emails"
    }

    var parameters: [String: Any]? {
        if let ID = labelID {
            return ["Page": page, "PageSize": max, "LabelID": ID]
        }
        return ["Page": page, "PageSize": max]
    }
}

// TODO: performance enhancement?
class ContactEmailsResponse: Response {
    var total: Int = -1
    var contacts: [[String: Any]] = [] // [["ID": ..., "Name": ..., "ContactEmails": ..., "LastUsedTime": ...], ...]
    /// This field stores ContactID with Contact Data and is used to improve the search for the contact by contactID.
    private var contactsMap: [String: [String: Any]] = [:]
    override func ParseResponse (_ response: [String: Any]?) -> Bool {
        self.total = response?["Total"] as? Int ?? -1
        if let contactEmails = response?["ContactEmails"] as? [[String: Any]] {
            // setup emails
            for var email in contactEmails { // for every email in ContactEmails
                if let contactID = email["ContactID"] as? String,
                   let name = email["Name"] as? String,
                   let lastUpdateTime = email["LastUsedTime"] as? Int {
                    // convert the labelID strings into JSON dictionary
                    if let labelIDs = email["LabelIDs"] as? [String] {
                        let mapping: [[String: Any]] = labelIDs.map({
                            (labelID: String) -> [String: Any] in

                            // TODO: check if this will clear other fields or noang
                            return [
                                "ID": labelID,
                                "Type": 2 /* don'type forget about it... */
                            ]
                        })

                        email["LabelIDs"] = mapping
                    }

                    // we put emails that is under the same ContactID together
                    var contactFound = false
                    if var contact = contactsMap[contactID] {
                        contactFound = true
                        if var emails = contact["ContactEmails"] as? [[String: Any]] {
                            emails.append(email)
                            contact["ContactEmails"] = emails
                        } else {
                            contact["ContactEmails"] = [email]
                        }
                        contact["LastUsedTime"] = lastUpdateTime
                        contactsMap[contactID] = contact
                    }
                    if !contactFound {
                        let newContact: [String: Any] = [ // this is contact object
                            "ID": contactID, // contactID
                            "Name": name, // contact name (email don'type have their individual name, so it'signature contact'signature name?)
                            "ContactEmails": [email] // these are the email objects (contact has a relation to email)
                        ]
                        self.contactsMap[contactID] =  newContact
                    }
                }
            }
        }
        // Convert the map into contact array.
        contacts = contactsMap.map({ _, value in
            return value
        })
        return true
    }
}

// MARK: Get messages part
final class ContactDetailRequest: Request {  // ContactDetailResponse
    let contactID: String
    init(cid: String) {
        self.contactID = cid
    }

    var path: String {
        return ContactsAPI.path + "/" + self.contactID
    }
}

//
class ContactDetailResponse: Response {
    var contact: [String: Any]?
    override func ParseResponse (_ response: [String: Any]!) -> Bool {
        contact = response["Contact"] as? [String: Any]
        return true
    }
}

final class ContactEmail: Package {
    let id: String
    let email: String
    let type: String

    init(email: String, type: String) {
        self.email = email
        self.type = type
        self.id = ""
    }

    var parameters: [String: Any]? {
        return [
            "ID": self.id,
            "Email": self.email,
            "Type": self.type
        ]
    }
}

// 0, 1, 2, 3 // 0 for cleartext, 1 for encrypted only (not used), 2 for signed, 3 for both
enum CardDataType: Int, Codable {
    case PlainText = 0
    case EncryptedOnly = 1
    case SignedOnly = 2
    case SignAndEncrypt = 3
}

// add contacts Card object
final class CardData: Package, Codable, Equatable {
    let type: CardDataType
    let data: String
    let signature: String

    init(type: CardDataType, data: String, signature: String) {
        self.data = data
        self.signature = signature
        self.type = type
    }

    convenience init(type: CardDataType, data: String, signature: ArmoredSignature) {
        self.init(type: type, data: data, signature: signature.value)
    }

    var parameters: [String: Any]? {
        return [
            "Data": self.data,
            "Type": self.type.rawValue,
            "Signature": self.signature
        ]
    }

    enum CodingKeys: String, CodingKey {
        case data = "Data"
        case type = "Type"
        case signature = "Signature"
    }

    static func == (lhs: CardData, rhs: CardData) -> Bool {
        return lhs.type.rawValue == rhs.type.rawValue &&
            lhs.data == rhs.data &&
            lhs.signature == rhs.signature
    }
}

extension Array where Element: CardData {
    func toDictionary() -> [[String: Any]] {
        var dicts = [[String: Any]]()
        for element in self {
            if let e = element.parameters {
                dicts.append(e)
            }
        }
        return dicts
    }

    func toJSONString() throws -> String {
        let jsonData = try JSONEncoder().encode(self)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            let error = NSError(domain: "", code: -1,
                                localizedDescription: LocalString._error_no_object)
            throw error
        }
        return jsonString
    }
}

final class ContactAddRequest: Request {
    let cardsList: [[CardData]]
    let importedFromDevice: Bool
    init(cards: [[CardData]], authCredential: AuthCredential?, importedFromDevice: Bool = false) {
        self.cardsList = cards
        self.auth = authCredential
        self.importedFromDevice = importedFromDevice
    }

    let auth: AuthCredential?
    var authCredential: AuthCredential? {
        get {
            return self.auth
        }
    }

    var path: String {
        return ContactsAPI.path
    }

    var method: HTTPMethod {
        return .post
    }

    var parameters: [String: Any]? {
        var contacts: [Any] = [Any]()
        for cards in self.cardsList {
            var cards_dict: [Any] = [Any]()
            for c in cards {
                if let dict = c.parameters {
                    cards_dict.append(dict)
                }
            }
            let contact: [String: Any] = [
                "Cards": cards_dict
            ]
            contacts.append(contact)
        }

        var body: [String: Any] = [
            "Contacts": contacts,
            "Overwrite": 1, // when UID conflict, 0 = error, 1 = overwrite
            "Groups": 1, // import groups if present, will silently skip if group does not exist
            "Labels": 0 // import Notes: change to 0 for now , we need change to 1 later
        ]
        if importedFromDevice {
            body["Import"] = 1
        }
        return body
    }
}

final class ContactAddResponse: Response {
    var results: [Any?] = []
    override func ParseResponse (_ response: [String: Any]!) -> Bool {
        if let responses = response["Responses"] as? [[String: Any]] {
            for res in responses {
                if let response = res["Response"] as? [String: Any] {
                    let code = response["Code"] as? Int
                    let errorMessage = response["Error"] as? String
                    let errorDetails = errorMessage

                    if code != 1000 && code != 1001 {
                        results.append(NSError.protonMailError(code ?? 1000, localizedDescription: errorMessage ?? "", localizedFailureReason: errorDetails, localizedRecoverySuggestion: nil))
                    } else {
                        results.append(response["Contact"])
                    }
                }
            }
        }
        return true
    }
}

final class ContactUpdateRequest: Request { // ContactDetailResponse
    var contactID: String
    let Cards: [CardData]

    init(contactid: String, cards: [CardData]) {
        self.contactID = contactid
        self.Cards = cards
    }

    var path: String {
        return ContactsAPI.path + "/" + self.contactID
    }

    var method: HTTPMethod {
        return .put
    }

    var parameters: [String: Any]? {
        var cards_dict: [Any] = [Any]()
        for c in self.Cards {
            if let dict = c.parameters {
                cards_dict.append(dict)
            }
        }
        return [
            "Cards": cards_dict
        ]
    }
}

// Contact group APIs

/// Add designated contact emails into a certain contact group
final class ContactLabelAnArrayOfContactEmailsRequest: Request { // ContactLabelAnArrayOfContactEmailsResponse
    let labelID: LabelID
    let contactEmailIDs: [String]
    init(labelID: LabelID, contactEmailIDs: [EmailID]) {
        self.labelID = labelID
        self.contactEmailIDs = contactEmailIDs.map(\.rawValue)
    }

    var path: String {
        return ContactsAPI.path + "/emails/label"
    }

    var method: HTTPMethod {
        return .put
    }

    var parameters: [String: Any]? {
        return ["ContactEmailIDs": contactEmailIDs, "LabelID": labelID.rawValue]
    }
}

/// Process the response of ContactLabelAnArrayOfContactEmailsRequest
/// TODO: check return body
final class ContactLabelAnArrayOfContactEmailsResponse: Response {
    var emailIDs: [String] = []
    override func ParseResponse (_ response: [String: Any]!) -> Bool {
        if let responses = response["Responses"] as? [[String: Any]] {
            for data in responses {
                if let ID = data["ID"] as? String, let tmp = data["Response"] as? [String: Any] {
                    if let code = tmp["Code"] as? Int, code == 1000 {
                        emailIDs.append(ID)
                    }
                }
            }
        }
        return true
    }
}

/// Remove designated contact emails from a certain contact group
final class ContactUnlabelAnArrayOfContactEmailsRequest: Request { // ContactUnlabelAnArrayOfContactEmailsResponse
    let labelID: LabelID
    let contactEmailIDs: [String]
    init(labelID: LabelID, contactEmailIDs: [EmailID]) {
        self.labelID = labelID
        self.contactEmailIDs = contactEmailIDs.map(\.rawValue)
    }

    var path: String {
        return ContactsAPI.path + "/emails/unlabel"
    }

    var method: HTTPMethod {
        return .put
    }

    var parameters: [String: Any]? {
        return ["ContactEmailIDs": contactEmailIDs, "LabelID": labelID.rawValue]
    }
}

/// Process the response of ContactUnlabelAnArrayOfContactEmailsRequest
/// TODO: check return body
final class ContactUnlabelAnArrayOfContactEmailsResponse: Response {
    var emailIDs: [String] = []

    override func ParseResponse (_ response: [String: Any]!) -> Bool {
        if let responses = response["Responses"] as? [[String: Any]] {
            for data in responses {
                if let ID = data["ID"] as? String, let tmp = data["Response"] as? [String: Any] {
                    if let code = tmp["Code"] as? Int, code == 1000 {
                        emailIDs.append(ID)
                    }
                }
            }
        }

        return true
    }
}
