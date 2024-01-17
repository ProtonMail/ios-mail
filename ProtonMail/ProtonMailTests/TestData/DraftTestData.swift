// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
@testable import ProtonMail

struct DraftTestData {
    static func mockCreateDraftResponse(
        messageID: String = String.randomString(88),
        conversationID: String = String.randomString(88),
        addressID: String = String.randomString(88),
        body: String = String.randomString(100),
        attachmentKeyPackets: [String] = [],
        time: Date = Date(),
        sender: Sender
    ) -> (String, String, String, [String: Any]) {
        let subject = String.randomString(10)
        let inReplyTo = "<\(String.randomString(108))@protonmail.com>"
        let senderDict = [
            "Name": sender.name,
            "Address": sender.address,
            "IsProton": sender.isFromProton ? 1 : 0,
            "DisplaySenderImage": sender.shouldDisplaySenderImage ? 1 : 0,
            "IsSimpleLogin": 0
        ] as [String : Any]
        let attachments = generateAttachmentInfo(attachmentKeyPackets: attachmentKeyPackets)
        let dateString = dateString(from: time)
        let response: [String: Any] = [
            "Code": 1000,
            "Message": [
                "ID": messageID,
                "Order": 503105379763,
                "ConversationID": conversationID,
                "Subject": subject,
                "Unread": 0,
                "Sender": senderDict,
                "SenderAddress": sender.address,
                "SenderName": sender.name,
                "Flags": 12,
                "Type": 1,
                "IsEncrypted": 5,
                "IsReplied": 0,
                "IsRepliedAll": 0,
                "IsForwarded": 0,
                "IsProton": 0,
                "DisplaySenderImage": 0,
                "ToList": [] as [[String: Any]],
                "CCList": [] as [[String: Any]],
                "BCCList": [] as [[String: Any]],
                "Time": time.timeIntervalSince1970,
                "Size": 24931,
                "NumAttachments": 2,
                "ExpirationTime": 0,
                "SpamScore": 0,
                "AddressID": addressID,
                "Body": body,
                "MIMEType": "text/html",
                "Header": "In-Reply-To: \(inReplyTo)\r\nReferences: \(inReplyTo)\r\nX-Pm-Origin: internal\r\nX-Pm-Content-Encryption: end-to-end\r\nSubject: \(subject)\r\nFrom: =?utf-8?B?5Zif5ZifIOWYn+WYn8Olw7bDpCDlmJ/lpKflpKflpKdQw6Ry4pq+77iP?=\r\n =?utf-8?B?8J+ljvCfj4nwn6qA8J+lovCfpaHwn4208J+NvfCfjb7wn6eKIDxpbXRoZWJv?=\r\n =?utf-8?B?dDFAcHJvdG9ubWFpbC5jb20+?=\r\nDate: \(dateString)\r\nMime-Version: 1.0\r\nContent-Type: text/html\r\nX-Attached: image.png\r\nX-Attached: image.png\r\n",
                "ParsedHeaders": [
                    "In-Reply-To": inReplyTo,
                    "References": inReplyTo,
                    "X-Pm-Origin": "internal",
                    "X-Pm-Content-Encryption": "end-to-end",
                    "Subject": subject,
                    "From": "\(sender.name) <\(sender.address)>",
                    "Date": "\(dateString)",
                    "Mime-Version": "1.0",
                    "Content-Type": "text/html",
                    "X-Attached": attachments.compactMap { $0["Name"] }
                ] as [String : Any],
                "ReplyTo": senderDict,
                "ReplyTos": [senderDict],
                "LabelIDs": ["1", "5", "8", "15"],
                "Attachments": attachments
            ] as [String : Any]
        ]

        return (messageID, conversationID, subject, response)
    }

    private static func generateAttachmentInfo(attachmentKeyPackets: [String]) -> [[String: Any]] {
        var attachments: [[String: Any]] = []
        for keyPacket in attachmentKeyPackets {
            let info: [String: Any] = [
                "ID": String.randomString(88),
                "Name": "\(String.randomString(6)).png",
                "Size": Int.random(in: 10...999),
                "MIMEType": "image/png",
                "Disposition": "attachment",
                "KeyPackets": keyPacket,
                "Headers": [
                    "content-disposition": "attachment",
                    "x-pm-content-encryption": "end-to-end"
                ]
            ]
            attachments.append(info)
        }
        return attachments
    }

    private static func dateString(from time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy hh:mm:ss Z"
        formatter.locale = LocaleEnvironment.locale()
        return formatter.string(from: time)
    }
}
