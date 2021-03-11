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

final public class Message: NSManagedObject {
    ///Mark -- new orders
    ///
    @NSManaged public var action: NSNumber?
    
    ///"AddressID":"222",
    @NSManaged public var addressID : String?
    ///"BCCList":[ { "Address":"", "Name":"", "Group": ""} ]
    @NSManaged public var bccList: String
    ///"Body":"-----BEGIN PGP MESSAGE-----.*-----END PGP MESSAGE-----",
    @NSManaged public var body: String
    
    
    ///local use and transient
    @NSManaged public var cachedPassphraseRaw: NSData? // transient
    ///local use and transient
    @NSManaged public var cachedPrivateKeysRaw: NSData? // transient
    ///local use and transient
    ///TODO: can this be kind of transient relatioship?
    @NSManaged public var cachedAuthCredentialRaw: NSData? // transient
    ///local use and transient
    ///TODO: addresses can also be in db, currently they are received from UserInfo singleton via message.defaultAddress getter
    @NSManaged public var cachedAddressRaw: NSData? // transient
    
    
    ///"CCList":[ { "Address":"", "Name":"", "Group": ""} ]
    @NSManaged public var ccList: String
    ///local use for sending set expiration offset
    @NSManaged public var expirationOffset : Int32
    ///"ExpirationTime":0,
    @NSManaged public var expirationTime: Date?
    /// Flags : bitsets for maybe different flag. defined in [Message.Flag]
    @NSManaged public var flags: NSNumber
    ///"Header":"(No Header)",
    @NSManaged public var header: String?
    
    ///local use, check if details downloaded
    @NSManaged public var isDetailDownloaded: Bool
    @available(*, deprecated, message: "use flag instead")
    @NSManaged public var isEncrypted: NSNumber
    
    ////local use, to check draft latest update time to decide pick cache or remote. should use the server time.
    @NSManaged public var lastModified: Date?
    /// ID : message id -- "ASnfew8asds92SDnsakr=="
    @NSManaged public var messageID: String
    /// local use, to check if message has metadata or not. some logic will fetch the metadata based on this
    @NSManaged public var messageStatus : NSNumber  // bit 0x00000000 no metadata  0x00000001 has
    /// local use, 0 is normal messages. 1 is review/rating tempery message
    @NSManaged public var messageType : NSNumber  // 0 message 1 rate
    ///"MIMEType": "text/html",
    @NSManaged public var mimeType : String?
    ///"NumAttachments":0,
    @NSManaged public var numAttachments: NSNumber
    ///local use, only when send/draft/reply/forward. to track the orginal message id
    @NSManaged public var orginalMessageID: String?
    ///local use, for sending. orginal message time. sometimes need it in the body
    @NSManaged public var orginalTime: Date?
    ///local use, the encrypted body encrypt by password
    @NSManaged public var passwordEncryptedBody: String
    ///local use, the pwd
    @NSManaged public var password: String
    ///local use, pwd hint
    @NSManaged public var passwordHint: String
    
    ///"ReplyTos": [{"Address":"", "Name":""}]
    @NSManaged public var replyTos: String?
    ///"Sender": { "Address":"", "Name":"" }
    @NSManaged public var sender: String?
    ///"Size":6959782,
    @NSManaged public var size: NSNumber
    ///"SpamScore": 101,  // 100 is PM spoofed, 101 is dmarc failed
    @NSManaged public var spamScore: NSNumber
    ///"Time":1433649408,
    @NSManaged public var time: Date?
    /// Subject : message subject -- "Fw: test"
    @NSManaged public var title: String
    ///"ToList":[ { "Address":"", "Name":"", "Group": ""} ]
    @NSManaged public var toList: String
    /// Unread : is message read / unread -- 0
    @NSManaged public var unRead: Bool
    
    @NSManaged public var userID: String
    
    //Check if the message is being sent now
    @NSManaged public var isSending: Bool
    
    /// Mark -- relationship
    
    //"Attachments":[ { }, {} ]
    @NSManaged public var attachments: NSSet
    //"LabelIDs":[ "1", "d3HYa3E394T_ACXDmTaBub14w==" ],
    @NSManaged public var labels: NSSet
    
    

    ///***Those values api returns them but client skip it
    ///"Order": 367
    ///ConversationID = "wgPpo3deVBrGwP3X8qZ-KSb0TtQ7_qy8TcISzCt2UQ==";
    ///ExternalID = "a34aa56f-150f-cffc-587b-83d7ca798277@emailprivacytester.com";
    ///Mark -- Remote values
    
    
    //@NSManaged public var tag: String
    
    //temp cache memory only
    var checkingSign : Bool = false
    var checkedSign : Bool = false
    var pgpType : PGPType = .none
    var unencrypt_outside : Bool = false
    typealias ObjectIDContainer = ObjectBox<Message>
    
    var tempAtts: [AttachmentInline]? = nil
}

//IsEncrypted = 2;
//IsForwarded = 0;
//IsReplied = 0;
//IsRepliedAll = 0;

