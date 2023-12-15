//
//  MessageAPI.swift
//  Proton Mail - Created on 6/18/15.
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
import ProtonCoreDataModel
import ProtonCoreNetworking

// Message API
// Doc: V1 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_messages.md
// Doc: V3 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_messages_v3.md
struct MessageAPI {
    /// base message api path
    static let path: String = "/\(Constants.App.API_PREFIXED)/messages"
}

final class SearchMessageRequest: Request {
    var keyword: String
    var page: UInt

    init(keyword: String, page: UInt) {
        self.keyword = keyword
        self.page = page
    }

    var parameters: [String: Any]? {
        var out: [String: Any] = [String: Any]()
        out["Keyword"] = self.keyword
        out["Page"] = self.page
        return out
    }

    var method: HTTPMethod {
        return .get
    }

    var path: String {
        return MessageAPI.path
    }
}

// MARK: Get messages part --- MessageCountResponse
final class MessageCountRequest: Request {
    var path: String {
        return MessageAPI.path + "/count"
    }
}

final class FetchMessagesByID: Request {
    let msgIDs: [String]

    init(msgIDs: [String]) {
        self.msgIDs = msgIDs
    }

    var parameters: [String: Any]? {
        let out: [String: Any] = ["ID": msgIDs]
        return out
    }

    var path: String {
        return MessageAPI.path
    }
}

final class FetchMessagesByIDResponse: Response {
    private(set) var messages: [[String: Any]]?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        self.messages = response["Messages"] as? [[String: Any]]
        return true
    }
}

/// Response
final class FetchMessagesByLabelRequest: Request {
    let labelID: String!
    /// UNIX timestamp to filter messages at or earlier than timestamp
    let endTime: Int?
    /// UNIX timestamp to filter messages at or later than timestamp
    let beginTime: Int?
    let isUnread: Bool?
    let pageSize: Int?
    /// return only messages older, in creation time (NOT timestamp), than EndID
    let endID: String?
    let page: Int?
    let priority: APIPriority?
    let sort: Sort
    let descending: Bool

    enum Sort: String {
        case time = "Time"
        case snoozeTime = "SnoozeTime"
    }

    // For endTime and endID, they are used to filter response messages
    // The filter function considers endTime firstly, if time is equal compare endID

    init(
        labelID: String,
        endTime: Int?,
        sort: Sort = .time,
        beginTime: Int? = nil,
        isUnread: Bool? = nil,
        pageSize: Int? = 50,
        endID: String? = nil,
        page: Int? = nil,
        priority: APIPriority? = nil,
        descending: Bool = true
    ) {
        self.labelID = labelID
        self.endTime = endTime
        self.beginTime = beginTime
        self.isUnread = isUnread
        self.pageSize = pageSize
        self.endID = endID
        self.page = page
        self.priority = priority
        self.sort = sort
        self.descending = descending
    }

    var parameters: [String: Any]? {
        var out: [String: Any] = [
            "Sort": sort.rawValue,
            "Desc": descending ? 1 : 0
        ]
        out["LabelID"] = self.labelID
        if let endTime, endTime > 0 {
            let newTime = endTime - 1
            out["End"] = newTime
        }
        if let beginTime {
            out["Begin"] = beginTime
        }
        if let unread = self.isUnread, unread {
            out["Unread"] = 1
        }
        if let pagesize = self.pageSize {
            out["PageSize"] = pagesize
        }
        if let endId = self.endID {
            out["EndID"] = endId
        }
        if let page = self.page {
            out["Page"] = page
        }
        return out
    }

    var header: [String : Any] {
        var header: [String: Any] = [:]
        if let priority = priority {
            header["priority"] = priority.rawValue
        }
        return header
    }

    var path: String {
        return MessageAPI.path
    }
}

// MARK: Create/Update Draft Part
/// create draft message request class -- MessageResponse
class CreateDraftRequest: Request {

    let message: MessageEntity
    let fromAddress: Address?

    /// TODO:: here need remove refrence of Message should create a Draft builder and a seperate package
    ///
    /// - Parameter message: Message
    init(message: MessageEntity, fromAddr: Address?) {
        self.message = message
        self.fromAddress = fromAddr
    }

    var parameters: [String: Any]? {
        var messageDict: [String: Any] = [
            "Body": message.body,
            "Subject": message.title,
            "Unread": message.unRead ? 1 : 0]

        let fromAddress = fromAddress
        let name = fromAddress?.displayName ?? "unknown"
        var address = fromAddress?.email ?? "unknown"

        if let sender = try? message.parseSender() {
            address = sender.address
        }

        messageDict["Sender"] = [
            "Name": name,
            "Address": address
        ]

        messageDict["ToList"]  = message.rawTOList.parseJson()
        messageDict["CCList"]  = message.rawCCList.parseJson()
        messageDict["BCCList"] = message.rawBCCList.parseJson()

        var out: [String: Any] = ["Message": messageDict]

        if let originalMsgID = message.originalMessageID?.rawValue {
            if !originalMsgID.isEmpty {
                out["ParentID"] = originalMsgID
                out["Action"] = message.action ?? "0"  // {0|1|2} // Optional, reply = 0, reply all = 1, forward = 2 m
            }
        }

        var AttachmentKeyPackets: [String: String] = [:]
        for attachment in message.attachments where attachment.keyChanged {
            AttachmentKeyPackets[attachment.id.rawValue] = attachment.keyPacket
        }
        if !AttachmentKeyPackets.keys.isEmpty {
            out["AttachmentKeyPackets"] = AttachmentKeyPackets
        }
        return out
    }

    var authCredential: AuthCredential?

    var path: String {
        return MessageAPI.path
    }

    var method: HTTPMethod {
        return .post
    }
}

/// message update draft api request
final class UpdateDraftRequest: CreateDraftRequest {

    convenience init(message: MessageEntity, fromAddr: Address?, authCredential: AuthCredential? = nil) {
        self.init(message: message, fromAddr: fromAddr)
        self.authCredential = authCredential
    }

    override var path: String {
        return MessageAPI.path + "/" + message.messageID.rawValue
    }

    override var method: HTTPMethod {
        return .put
    }
}

// MARK: Message actions part

/// message action request PUT method   --- Response
final class MessageActionRequest: Request {
    let action: String
    var ids: [String] = [String]()

    init(action: String, ids: [String]) {
        self.action = action
        self.ids = ids
    }

    var parameters: [String: Any]? {
        ["IDs": self.ids]
    }

    var path: String {
        return MessageAPI.path + "/" + self.action
    }

    var method: HTTPMethod {
        return .put
    }
}

struct MessageActionResponse: Decodable {
    let responses: [Responses]

    struct Responses: Decodable {
        let id: String
        let response: Response

        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case response = "response"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            response = try container.decode(Response.self, forKey: .response)
        }
    }

    struct Response: Decodable {
        let code: Int
        let error: String?
    }
}

/// empty trash or spam -- Response
final class EmptyMessageRequest: Request {

    let labelID: String
    init(labelID: String) {
        self.labelID = labelID
    }

    var path: String {
        return MessageAPI.path + "/empty?LabelID=" + self.labelID
    }

    var method: HTTPMethod {
        return .delete
    }
}

// MARK: Message Send part

final class SendMessageRequest: Request {
    let messagePackage: [AddressPackageBase]  // message package
    let body: String
    let messageID: String
    let expirationTime: Int
    let delaySeconds: Int

    let clearBody: ClearBodyPackage?
    let clearAtts: [ClearAttachmentPackage]?

    let mimeDataPacket: String
    let clearMimeBody: ClearBodyPackage?

    let plainTextDataPacket: String
    let clearPlainTextBody: ClearBodyPackage?
    let deliveryTime: Date?

    init(messageID: String,
         expirationTime: Int?,
         delaySeconds: Int,
         messagePackage: [AddressPackageBase]!,
         body: String,
         clearBody: ClearBodyPackage?,
         clearAtts: [ClearAttachmentPackage]?,
         mimeDataPacket: String,
         clearMimeBody: ClearBodyPackage?,
         plainTextDataPacket: String,
         clearPlainTextBody: ClearBodyPackage?,
         authCredential: AuthCredential?,
         deliveryTime: Date?) {
        self.messageID = messageID
        self.messagePackage = messagePackage
        self.body = body
        self.expirationTime = expirationTime ?? 0
        self.delaySeconds = delaySeconds
        self.clearBody = clearBody
        self.clearAtts = clearAtts

        self.mimeDataPacket = mimeDataPacket
        self.clearMimeBody = clearMimeBody

        self.plainTextDataPacket = plainTextDataPacket
        self.clearPlainTextBody = clearPlainTextBody

        self.auth = authCredential
        self.deliveryTime = deliveryTime
    }

    let auth: AuthCredential?
    var authCredential: AuthCredential? {
        return self.auth
    }

    var parameters: [String: Any]? {
        var out: [String: Any] = [String: Any]()

        if self.expirationTime > 0 {
            out["ExpiresIn"] = self.expirationTime
        }
        out["DelaySeconds"] = self.delaySeconds
        if let deliveryTime = deliveryTime {
            out["DeliveryTime"] = Int(deliveryTime.timeIntervalSince1970)
        }
        // optional this will override app setting
        // out["AutoSaveContacts"] = "\(0 / 1)"

        // packages object
        var packages: [Any] = [Any]()
        let normalPackage = messagePackage.filter { $0.scheme.rawValue < 10 }

        let plainTextPackage = normalPackage.filter { $0.plainText == true }
        if let encodedPlainTextPackage = encode(addressPackages: plainTextPackage,
                                                mime: .plainText,
                                                body: plainTextDataPacket,
                                                clearBody: clearPlainTextBody,
                                                clearAttachments: clearAtts) {
            packages.append(encodedPlainTextPackage)
        }

        let htmlPackage = normalPackage.filter { $0.plainText == false }
        if let encodedHTMLPackage = encode(addressPackages: htmlPackage,
                                           mime: .html,
                                           body: body,
                                           clearBody: clearBody,
                                           clearAttachments: clearAtts) {
            packages.append(encodedHTMLPackage)
        }

        let mimePackage = messagePackage.filter { $0.scheme.rawValue > 10 }
        if let encodedMIMEPackage = encode(addressPackages: mimePackage,
                                           mime: .mime,
                                           body: mimeDataPacket,
                                           clearBody: clearMimeBody,
                                           clearAttachments: nil) {
            packages.append(encodedMIMEPackage)
        }
        out["Packages"] = packages
        return out
    }

    private func encode(
        addressPackages: [AddressPackageBase],
        mime: SendMIMEType,
        body: String,
        clearBody: ClearBodyPackage?,
        clearAttachments: [ClearAttachmentPackage]?
    ) -> [String: Any]? {
        if addressPackages.isEmpty { return nil }

        var dict = [String: Any]()
        var addresses = [String: Any]()
        var type = SendType()
        for package in addressPackages {
            guard let parameters = package.parameters else { continue }
            addresses[package.email] = parameters
            type.insert(package.scheme.sendType)
        }
        dict["Addresses"] = addresses
        // "Type": 15, // 8|4|2|1, all types sharing this package, a bitmask
        dict["Type"] = type.rawValue
        dict["Body"] = body
        dict["MIMEType"] = mime.rawValue

        if let clearBody = clearBody,
            addressPackages.contains(where: { $0.scheme == .cleartextInline || $0.scheme == .cleartextMIME }) {
            // Include only if cleartext recipients
            let bodyKey: [String: String] = [
                "Key": clearBody.key,
                "Algorithm": clearBody.algo.value
            ]
            dict["BodyKey"] = bodyKey
        }

        if let clearAttachments = clearAttachments,
           addressPackages.contains(where: { $0.scheme == .cleartextInline || $0.scheme == .cleartextMIME }) {
            // Only include if cleartext recipients, optional if no attachments
            var attachments = [String: [String: String]]()
            for item in clearAttachments {
                let info: [String: String] = [
                    "Key": item.encodedSession,
                    "Algorithm": item.algo.value
                ]
                attachments[item.ID] = info
            }
            dict["AttachmentKeys"] = attachments
        }
        return dict
    }

    var path: String {
        return MessageAPI.path + "/" + self.messageID
    }

    var method: HTTPMethod {
        return .post
    }
}
