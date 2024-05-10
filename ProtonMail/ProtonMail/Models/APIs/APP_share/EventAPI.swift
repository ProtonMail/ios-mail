//
//  EventAPI.swift
//  Proton Mail - Created on 6/26/15.
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
import ProtonCoreNetworking

enum EventAPI {
    case v4
    case v5

    var path: String {
        switch self {
        case .v4:
            return "/core/v4/events"
        case .v5:
            return "/core/v5/events"
        }
    }
}

final class EventCheckRequest: Request {
    /*
     When `true`, contacts in the event loop response won't contain the contact object.
     Contacts details will be fetched for those contact events returned. The contactt detail
     fetch will be enqueued in the misc queue.
     **/
    static let isNoMetaDataForContactsEnabled: Bool = true

    let eventID: String
    let discardContactsMetadata: Bool

    init(eventID: String, discardContactsMetadata: Bool) {
        self.eventID = eventID
        self.discardContactsMetadata = discardContactsMetadata
    }

    var path: String {
        let url = "\(EventAPI.v5.path)/\(eventID)"
        var urlComponents = URLComponents(string: url)
        urlComponents?.queryItems = [
            URLQueryItem(name: "ConversationCounts", value: "1"),
            URLQueryItem(name: "MessageCounts", value: "1")
        ]
        if discardContactsMetadata {
            urlComponents?.queryItems?.append(URLQueryItem(name: "NoMetaData[]", value: "Contact"))
        }
        return urlComponents?.url?.absoluteString ?? .empty
    }
}

// -- EventLatestIDResponse
final class EventLatestIDRequest: Request {
    var path: String {
        return "\(EventAPI.v4.path)/latest"
    }
}

final class EventLatestIDResponse: Response {
    var eventID: String = ""
    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        self.eventID = response["EventID"] as? String ?? ""
        return true
    }
}

// periphery:ignore
struct RefreshStatus: OptionSet {
    let rawValue: Int
    // 255 means throw out client cache and reload everything from server, 1 is mail, 2 is contacts
    static let ok       = RefreshStatus([])
    /// When the user was delinquent and is not anymore
    static let mail     = RefreshStatus(rawValue: 1 << 0)
    /// When the user cleared his contacts
    static let contacts = RefreshStatus(rawValue: 1 << 1)
    /// When given ID < lowest ID stored (3 weeks old)
    static let all      = RefreshStatus(rawValue: 0xFF)
}

final class EventCheckResponse: Response {
    var eventID: String = ""
    var refresh: Int = 0
    var more: Int = 0
    var refreshStatus: RefreshStatus {
        .init(rawValue: self.refresh)
    }

    var messages: [[String: Any]]?
    var contacts: [[String: Any]]?
    var contactEmails: [[String: Any]]?
    var labels: [[String: Any]]?

    var subscription: [String: Any]? // TODO:: we will use this when we impl in app purchase

    var user: [String: Any]?
    var userSettings: [String: Any]?
    var mailSettings: [String: Any]?

    var addresses: [[String: Any]]?
    var incomingDefaults: [[String: Any]]?

    var organization: [String: Any]? // TODO:: use when we add org setting in the app

    var messageCounts: [[String: Any]]?

    var conversations: [[String: Any]]?

    var conversationCounts: [[String: Any]]?

    var usedSpace: Int64?
    var notices: [String]?

    override func ParseResponse(_ response: [String: Any]) -> Bool {
        self.eventID = response["EventID"] as? String ?? ""
        self.refresh = response["Refresh"] as? Int ?? 0
        self.more    = response["More"] as? Int ?? 0

        self.messages      = response["Messages"] as? [[String: Any]]
        self.contacts      = response["Contacts"] as? [[String: Any]]
        self.contactEmails = response["ContactEmails"] as? [[String: Any]]
        self.labels        = response["Labels"] as? [[String: Any]]

        // self.subscription = response["Subscription"] as? [String : Any]

        self.user         = response["User"] as? [String: Any]
        self.userSettings = response["UserSettings"] as? [String: Any]
        self.mailSettings = response["MailSettings"] as? [String: Any]

        self.addresses = response["Addresses"] as? [[String: Any]]
        self.incomingDefaults = response["IncomingDefaults"] as? [[String: Any]]

        // self.organization = response["Organization"] as? [String : Any]

        self.messageCounts = response["MessageCounts"] as? [[String: Any]]

        self.conversations = response["Conversations"] as? [[String: Any]]
        // TODO: - V4 Wait for BE fix
        self.conversationCounts = response["ConversationCounts"] as? [[String: Any]]

        self.usedSpace = response["UsedSpace"] as? Int64
        self.notices = response["Notices"] as? [String]

        return true
    }
}

/// TODO:: refactor the events they have same format

enum EventAction: Int {
    /// Contains the item ID to delete an item in a collection.
    case delete = 0
    /// Contains all properties to add an item in a collection
    case create = 1
    /// Contains all properties to update an item in a collection.
    case update = 2
    /// `UpdateFlags` doesn't contain all properties
    /// So the client has to merge the data received with the model already stored in the cache
    case updateFlags = 3

    case unknown = 255
}

class Event {
    var action: EventAction
    var ID: String?

    init(id: String?, action: EventAction) {
        self.ID = id
        self.action = action
    }

}

// TODO:: remove the hard convert
final class MessageEvent {
    var Action: Int!
    var ID: String!
    var message: [String: Any]?
    init(event: [String: Any]) {
        self.Action = (event["Action"] as! Int)
        self.message = event["Message"] as? [String: Any]
        self.ID = (event["ID"] as! String)
        self.message?["ID"] = self.ID
        self.message?["needsUpdate"] = false
    }
}

extension MessageEvent {
    var isDraft: Bool {
        let draftID = LabelLocation.draft.rawLabelID
        let hiddenDraftID = LabelLocation.hiddenDraft.rawLabelID

        if let location = self.message?["Location"] as? Int,
           location == Int(draftID) || location == Int(hiddenDraftID) {
            return true
        }

        if let labelIDs = self.message?["LabelIDs"] as? NSArray,
           labelIDs.contains(draftID) || labelIDs.contains(hiddenDraftID) {
            return true
        }

        return false
    }

    var parsedTime: Date? {
        guard let value = self.message?["Time"] else { return nil }
        var time: TimeInterval = 0
        if let stringValue = value as? NSString {
            time = stringValue.doubleValue as TimeInterval
        } else if let numberValue = value as? NSNumber {
            time = numberValue.doubleValue as TimeInterval
        }
        return time == 0 ? nil: time.asDate()
    }
}

struct ConversationEvent {
    var action: Int
    var ID: String
    var conversation: [String: Any]
    init?(event: [String: Any]) {
        if let action = event["Action"] as? Int, let id = event["ID"] as? String {
            self.action = action
            self.ID = id
            self.conversation = event["Conversation"] as? [String: Any] ?? [:]
        } else {
            return nil
        }
    }
}

final class ContactEvent {
    enum UpdateType: Int {
        case delete = 0
        case insert = 1
        case update = 2

        case unknown = 255
    }
    var action: UpdateType

    var ID: String!
    var contact: [String: Any]?
    var contacts: [[String: Any]] = []
    init(event: [String: Any]!) {
        let actionInt = event["Action"] as? Int ?? 255
        self.action = UpdateType(rawValue: actionInt) ?? .unknown
        self.contact = event["Contact"] as? [String: Any]
        self.ID = (event["ID"] as! String)

        guard let contact = self.contact else {
            return
        }

        self.contacts.append(contact)
    }
}

final class EmailEvent {
    enum UpdateType: Int {
        case delete = 0
        case insert = 1
        case update = 2

        case unknown = 255
    }

    var action: UpdateType
    var ID: String!  // emailID
    var email: [String: Any]?
    var contacts: [[String: Any]] = []
    init(event: [String: Any]!) {
        let actionInt = event["Action"] as? Int ?? 255
        self.action = UpdateType(rawValue: actionInt) ?? .unknown
        self.email = event["ContactEmail"] as? [String: Any]
        self.ID = event["ID"] as? String ?? ""

        guard let email = self.email else {
            return
        }

        guard let contactID = email["ContactID"],
            let name = email["Name"] else {
            return
        }

        let newContact: [String: Any] = [
            "ID": contactID,
            "Name": name,
            "ContactEmails": [email]
        ]
        self.contacts.append(newContact)
    }

}

final class LabelEvent {
    var Action: Int!
    var ID: String!
    var label: [String: Any]?

    init(event: [String: Any]!) {
        self.Action = (event["Action"] as! Int)
        self.label = event["Label"] as? [String: Any]
        self.ID = (event["ID"] as! String)
    }
}

final class AddressEvent: Event {
    let address: AddressesResponse?

    init(event: [String: Any]) {
        if let addressDict = event["Address"] as? [String: Any] {
            address = AddressesResponse()
            _ = address?.parseAddr(res: addressDict)
        } else {
            address = nil
        }
        
        let actionInt = event["Action"] as? Int ?? 255
        super.init(
            id: event["ID"] as? String,
            action: EventAction(rawValue: actionInt) ?? .unknown
        )
    }
}


final class IncomingDefaultEvent: Event {
    private(set) var incomingDefault: [String: Any]?

    init(event: [String: Any]!) {
        let actionInt = event["Action"] as? Int ?? 255
        super.init(id: event["ID"] as? String,
                   action: EventAction(rawValue: actionInt) ?? .unknown)
        self.incomingDefault = event["IncomingDefault"] as? [String: Any]
    }
}
