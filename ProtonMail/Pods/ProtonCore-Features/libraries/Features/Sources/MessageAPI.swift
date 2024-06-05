//
//  MessageAPI.swift
//  ProtonCore-Features - Created on 18.06.2015.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreLog
import ProtonCoreNetworking

/// Message API
struct MessageAPI {
    /// base message api path
    static let path: String = "/mail/v4/messages"
}

final class SendResponse: Response {
    var responseDict: [String: Any] = [:]

    override func ParseResponse(_ response: [String: Any]) -> Bool {
        self.responseDict = response
        return super.ParseResponse(response)
    }
}

/// send message reuqest -- SendResponse
final class SendCalEvent: Request {
    var messagePackage: [AddressPackageBase]  // message package
    var body: String
    var bodyData: String
    // let messageID: String
    let expirationTime: Int32

    //// new
    let subject: String
    let senderName: String
    let senderAddr: String
    let recipients: [String]
    let atts: [AttachmentContent]

    ///
    var clearBody: ClearBodyPackage?
    var clearAtts: [ClearAttachmentPackage]?

    var mimeDataPacket: String
    var clearMimeBody: ClearBodyPackage?

    var plainTextDataPacket: String
    var clearPlainTextBody: ClearBodyPackage?

    init(subject: String,
         body: String,
         bodyData: String,
         senderName: String,
         senderAddr: String,
         recipients: [String],
         atts: [AttachmentContent],

         messagePackage: [AddressPackageBase],
         clearBody: ClearBodyPackage?,
         clearAtts: [ClearAttachmentPackage]?,
         mimeDataPacket: String,
         clearMimeBody: ClearBodyPackage?,
         plainTextDataPacket: String,
         clearPlainTextBody: ClearBodyPackage?,
         authCredential: AuthCredential? = nil) {
        self.subject = subject
        self.body = body
        self.senderName = senderName
        self.senderAddr = senderAddr
        self.recipients = recipients
        self.atts = atts
        self.bodyData = bodyData

        self.messagePackage = messagePackage
        self.expirationTime = 0
        self.clearBody = clearBody
        self.clearAtts = clearAtts

        self.mimeDataPacket = mimeDataPacket
        self.clearMimeBody = clearMimeBody

        self.plainTextDataPacket = plainTextDataPacket
        self.clearPlainTextBody = clearPlainTextBody

        self.auth = authCredential
    }

    let auth: AuthCredential?
    var authCredential: AuthCredential? {
        return self.auth
    }

    var parameters: [String: Any]? {
        var out: [String: Any] = [String: Any]()

        /// messages
        var messsageDict: [String: Any] = [
            "Body": self.body,
            "Subject": self.subject
        ]

        messsageDict["Sender"] = [
            "Name": self.senderName,
            "Address": self.senderAddr
        ]

        var toList: [[String: String]] = []
        for email in self.recipients {
            let to: [String: String] = [
                "Address": email,
                "Name": email
            ]
            toList.append(to)
        }

        messsageDict["ToList"] = toList
        messsageDict["CCList"] = [String]()
        messsageDict["BCCList"] = [String]()
        messsageDict["MIMEType"] = "text/plain"

        var attsDict: [[String: String]] = []
        for att in atts {
            let attDict: [String: String] = [
                "Filename": att.fileName,
                "MIMEType": att.mimeType,
                "Contents": att.fileData
            ]
            attsDict.append(attDict)
        }
        messsageDict["Attachments"] = attsDict

        if self.atts.count > 0 {
            if let packet = atts.first?.keyPacket {
                out["AttachmentKeys"] = packet
            }

        }

        out["Message"] = messsageDict

        if self.expirationTime > 0 {
            out["ExpiresIn"] = self.expirationTime
        }
        // optional this will override app setting
        // out["AutoSaveContacts"] = "\(0 / 1)"

        let normalPackage = messagePackage.filter { $0.type.rawValue < 10 }
        let mimePackage = messagePackage.filter { $0.type.rawValue > 10 }

        let plainTextPackage = normalPackage.filter { $0.plainText == true }
        let htmlPackage = normalPackage.filter { $0.plainText == false }

        // packages object
        var packages: [Any] = [Any]()

        // plaintext
        if plainTextPackage.count > 0 {
            // not mime
            var plainTextAddress: [String: Any] = [String: Any]()
            var addrs = [String: Any]()
            var type = SendType()
            for mp in plainTextPackage {
                addrs[mp.email] = mp.parameters!
                type.insert(mp.type)
            }
            plainTextAddress["Addresses"] = addrs
            // "Type": 15, // 8|4|2|1, all types sharing this package, a bitmask
            plainTextAddress["Type"] = type.rawValue
            plainTextAddress["Body"] = self.plainTextDataPacket
            plainTextAddress["MIMEType"] = "text/plain"

            if let cb = self.clearPlainTextBody {
                // Include only if cleartext recipients
                plainTextAddress["BodyKey"] = [
                    "Key": cb.key,
                    "Algorithm": cb.algo
                ]
            }

            if let clearAttachments = clearAtts, clearAttachments.count > 0 {
                // Only include if cleartext recipients, optional if no attachments
                var attachments: [[String: Any]] = [[String: Any]]()
                for attachment in clearAttachments {
                    attachments.append([
                        "Key": attachment.encodedSession,
                        "Algorithm": attachment.algo == "3des" ? "tripledes" : attachment.algo
                    ])
                }
                plainTextAddress["AttachmentKeys"] = attachments
            }
            packages.append(plainTextAddress)
        }

        // html text
        if htmlPackage.count > 0 {
            // not mime
            var htmlAddress: [String: Any] = [String: Any]()
            var addrs = [String: Any]()
            var type = SendType()
            for mp in htmlPackage {
                addrs[mp.email] = mp.parameters!
                type.insert(mp.type)
            }
            htmlAddress["Addresses"] = addrs
            // "Type": 15, // 8|4|2|1, all types sharing this package, a bitmask
            htmlAddress["Type"] = type.rawValue
            htmlAddress["Body"] = self.bodyData
            htmlAddress["MIMEType"] = "text/html"

            if let cb = clearBody {
                // Include only if cleartext recipients
                htmlAddress["BodyKey"] = [
                    "Key": cb.key,
                    "Algorithm": cb.algo
                ]
            }

            if let clearAttachments = clearAtts, clearAttachments.count > 0 {
                var attachments: [[String: Any]] = [[String: Any]]()
                for attachment in clearAttachments {
                    attachments.append([
                        "Key": attachment.encodedSession,
                        "Algorithm": attachment.algo == "3des" ? "tripledes" : attachment.algo
                    ])
                }
                htmlAddress["AttachmentKeys"] = attachments
            }
            packages.append(htmlAddress)
        }

        if mimePackage.count > 0 {
            // mime
            var mimeAddress: [String: Any] = [String: Any]()

            var addrs = [String: Any]()
            var mimeType = SendType()
            for mp in mimePackage {
                addrs[mp.email] = mp.parameters!
                mimeType.insert(mp.type)
            }
            mimeAddress["Addresses"] = addrs
            mimeAddress["Type"] = mimeType.rawValue // 16|32 MIME sending cannot share packages with inline sending
            mimeAddress["Body"] = mimeDataPacket
            mimeAddress["MIMEType"] = "multipart/mixed"

            if let cb = clearMimeBody {
                // Include only if cleartext MIME recipients
                mimeAddress["BodyKey"] = [
                    "Key": cb.key,
                    "Algorithm": cb.algo
                ]
            }
            packages.append(mimeAddress)
        }
        out["Packages"] = packages
        PMLog.debug(out.json(prettyPrinted: true))
        // PMLog.D( "API toDict done" )
        return out
    }

    var path: String {
        return MessageAPI.path + "/send/direct"
    }

    var method: HTTPMethod {
        return .post
    }
}
