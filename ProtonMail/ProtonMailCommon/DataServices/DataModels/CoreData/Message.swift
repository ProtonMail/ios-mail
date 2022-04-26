//
//  Message.swift
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
import CoreData

final class Message: NSManagedObject {
    /// Mark -- new orders
    ///
    @NSManaged var action: NSNumber?

    /// "AddressID":"222",
    @NSManaged var addressID: String?
    /// Local use, to record the addressID when user change the sender address
    /// Before executing the updateAttKeyPacket action, this variable keep holding the addressID that should show
    /// after the action finish and the message.addressID is equal nextAddressID, this variable will be reset to nil
    @NSManaged var nextAddressID: String?
    /// "BCCList":[ { "Address":"", "Name":"", "Group": ""} ]
    @NSManaged var bccList: String
    /// "Body":"-----BEGIN PGP MESSAGE-----.*-----END PGP MESSAGE-----",
    @NSManaged var body: String

    /// local use and transient
    @NSManaged var cachedPassphraseRaw: NSData? // transient
    /// local use and transient
    @NSManaged var cachedPrivateKeysRaw: NSData? // transient
    /// local use and transient
    /// TODO: can this be kind of transient relatioship?
    @NSManaged var cachedAuthCredentialRaw: NSData? // transient
    /// local use and transient
    /// TODO: addresses can also be in db, currently they are received from UserInfo singleton via message.defaultAddress getter
    @NSManaged var cachedAddressRaw: NSData? // transient

    /// "CCList":[ { "Address":"", "Name":"", "Group": ""} ]
    @NSManaged var ccList: String
    /// local use for sending set expiration offset
    @NSManaged var expirationOffset: Int32
    /// "ExpirationTime":0,
    @NSManaged var expirationTime: Date?
    /// Flags : bitsets for maybe different flag. defined in [Message.Flag]
    @NSManaged public var flags: NSNumber
    @available(*, deprecated, message: "use `ParsedHeaders` instead")
    ///"Header":"(No Header)",
    @NSManaged public var header: String?
    @NSManaged public var parsedHeaders: String
    /// Local use flag to mark this conversation is deleted
    /// (usually caused by empty trash/ spam action)
    @NSManaged var isSoftDeleted: Bool

    /// local use, check if details downloaded
    @NSManaged var isDetailDownloaded: Bool

    //// local use, to check draft latest update time to decide pick cache or remote. should use the server time.
    @NSManaged var lastModified: Date?
    /// ID : message id -- "ASnfew8asds92SDnsakr=="
    @NSManaged var messageID: String
    /// local use, to check if message has metadata or not. some logic will fetch the metadata based on this
    @NSManaged var messageStatus: NSNumber  // bit 0x00000000 no metadata  0x00000001 has
    /// local use, 0 is normal messages. 1 is review/rating tempery message
    @NSManaged var messageType: NSNumber  // 0 message 1 rate
    /// "MIMEType": "text/html",
    @NSManaged var mimeType: String?
    /// "NumAttachments":0,
    @NSManaged var numAttachments: NSNumber
    /// local use, only when send/draft/reply/forward. to track the orginal message id
    @NSManaged var orginalMessageID: String?
    /// local use, for sending. orginal message time. sometimes need it in the body
    @NSManaged var orginalTime: Date?
    /// local use, the encrypted body encrypt by password
    @NSManaged var passwordEncryptedBody: String
    /// local use, the pwd
    @NSManaged var password: String
    /// local use, pwd hint
    @NSManaged var passwordHint: String

    /// "ReplyTos": [{"Address":"", "Name":""}]
    @NSManaged var replyTos: String?
    /// "Sender": { "Address":"", "Name":"" }
    @NSManaged var sender: String?
    /// "Size":6959782,
    @NSManaged var size: NSNumber
    /// "SpamScore": 101,  // 100 is PM spoofed, 101 is dmarc failed
    @NSManaged var spamScore: NSNumber
    /// "Time":1433649408,
    @NSManaged var time: Date?
    /// Subject : message subject -- "Fw: test"
    @NSManaged var title: String
    /// "ToList":[ { "Address":"", "Name":"", "Group": ""} ]
    @NSManaged var toList: String
    /// Unread : is message read / unread -- 0
    @NSManaged var unRead: Bool

    @NSManaged var userID: String

    // Check if the message is being sent now
    @NSManaged var isSending: Bool

    @NSManaged var conversationID: String

    @NSManaged var unsubscribeMethods: String?

    /// Mark -- relationship

    // "Attachments":[ { }, {} ]
    @NSManaged var attachments: NSSet
    // "LabelIDs":[ "1", "d3HYa3E394T_ACXDmTaBub14w==" ],
    @NSManaged var labels: NSSet

    @NSManaged var order: NSNumber

    /// ***Those values api returns them but client skip it
    /// "Order": 367
    /// ConversationID = "wgPpo3deVBrGwP3X8qZ-KSb0TtQ7_qy8TcISzCt2UQ==";
    /// ExternalID = "a34aa56f-150f-cffc-587b-83d7ca798277@emailprivacytester.com";
    /// Mark -- Remote values

    // @NSManaged var tag: String

    // temp cache memory only
    var checkedSign: Bool = false
    var pgpType: PGPType = .none

    var tempAtts: [MimeAttachment]?
}

// IsEncrypted = 2;
// IsForwarded = 0;
// IsReplied = 0;
// IsRepliedAll = 0;
