//
//  Message.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import CoreData

final public class Message: NSManagedObject {
    ///***Those values api returns them but client skip it
    //"Order": 367
    //ConversationID = "wgPpo3deVBrGwP3X8qZ-KSb0TtQ7_qy8TcISzCt2UQ==";
    //ExternalID = "a34aa56f-150f-cffc-587b-83d7ca798277@emailprivacytester.com";

    /// Mark -- Remote values
    
    /// ID : message id -- "ASnfew8asds92SDnsakr=="
    @NSManaged public var messageID: String
    /// Subject : message subject -- "Fw: test"
    @NSManaged public var title: String
    /// Unread : is message read / unread -- 0
    @NSManaged public var unRead: Bool
    /// Flags : bitsets for maybe different flag. defined in [Message.Flag]
    @NSManaged public var flags: NSNumber
    //"Sender": { "Address":"", "Name":"" }
    @NSManaged public var sender: String?
    @available(*, deprecated, message: "double check if ok to remove")
    @NSManaged public var senderAddress: String
    @available(*, deprecated, message: "double check if ok to remove")
    @NSManaged public var senderName: String
    //"ReplyTos": [{"Address":"", "Name":""}]
    @NSManaged public var replyTos: String?
    //"ToList":[ { "Address":"", "Name":"", "Group": ""} ]
    @NSManaged public var toList: String
    //"Time":1433649408,
    @NSManaged public var time: Date?
    //"Size":6959782,
    @NSManaged public var size: NSNumber
    //"NumAttachments":0,
    @NSManaged public var numAttachments: NSNumber
    //"ExpirationTime":0,
    @NSManaged public var expirationTime: Date?
    //"SpamScore": 101,  // 100 is PM spoofed, 101 is dmarc failed
    @NSManaged public var spamScore: NSNumber
    //"AddressID":"222",
    @NSManaged public var addressID : String?
    //"Body":"-----BEGIN PGP MESSAGE-----.*-----END PGP MESSAGE-----",
    @NSManaged public var body: String
    //"MIMEType": "text/html",
    @NSManaged public var mimeType : String?
    //"CCList":[ { "Address":"", "Name":"", "Group": ""} ]
    @NSManaged public var ccList: String
    //"BCCList":[ { "Address":"", "Name":"", "Group": ""} ]
    @NSManaged public var bccList: String
    //"Header":"(No Header)",
    @NSManaged public var header: String?
    
    /// Mark -- relationship
    
    //"Attachments":[ { }, {} ]
    @NSManaged public var attachments: NSSet
    //"LabelIDs":[ "1", "d3HYa3E394T_ACXDmTaBub14w==" ],
    @NSManaged public var labels: NSSet

    
    ///

    @NSManaged public var isDetailDownloaded: Bool
    @available(*, deprecated, message: "use flag instead")
    @NSManaged public var isEncrypted: NSNumber
    @available(*, deprecated, message: "use labelIDs instead")
    @NSManaged public var isStarred: Bool    //Deprecated, use LabelIDs instead
    @NSManaged public var lastModified: Date?
    @available(*, deprecated, message: "use labelIDs instead")
    @NSManaged public var locationNumber: NSNumber  //Deprecated, use LabelIDs instead
    
    @NSManaged public var passwordEncryptedBody: String
    @NSManaged public var password: String
    @NSManaged public var passwordHint: String

    @NSManaged public var tag: String
    @NSManaged public var latestUpdateType : NSNumber
    @NSManaged public var needsUpdate : Bool
    @NSManaged public var orginalMessageID: String?
    @NSManaged public var orginalTime: Date?
    @NSManaged public var action: NSNumber?
    @NSManaged public var isSoftDelete: Bool
    @NSManaged public var expirationOffset : Int32
    //
    
    /// loacal only
    @NSManaged public var messageType : NSNumber  // 0 message 1 rate
    @NSManaged public var messageStatus : NSNumber  // bit 0x00000000 no metadata  0x00000001 has
    
    @NSManaged public var isShowedImages : Bool
    
    /// temp cache memory only
    var checkingSign : Bool = false
    var checkedSign : Bool = false
    var pgpType : PGPType = .none
    var unencrypt_outside : Bool = false
}

//IsEncrypted = 2;
//IsForwarded = 0;
//IsReplied = 0;
//IsRepliedAll = 0;
