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
    /// remote values
    @NSManaged public var bccList: String
    @NSManaged public var bccNameList: String
    @NSManaged public var body: String
    @NSManaged public var ccList: String
    @NSManaged public var ccNameList: String
    @NSManaged public var expirationTime: Date?
    @available(*, deprecated, message: "removed")
    @NSManaged public var hasAttachments: Bool   //removed
    @NSManaged public var numAttachments: NSNumber
    @NSManaged public var header: String?
    @NSManaged public var isDetailDownloaded: Bool
    
    @available(*, deprecated, message: "use flag instead")
    @NSManaged public var isEncrypted: NSNumber
    @NSManaged public var isForwarded: Bool
    @NSManaged public var unRead: Bool
    @NSManaged public var isReplied: Bool
    @NSManaged public var isRepliedAll: Bool
    @available(*, deprecated, message: "use labelIDs instead")
    @NSManaged public var isStarred: Bool    //Deprecated, use LabelIDs instead
    @NSManaged public var lastModified: Date?
    @available(*, deprecated, message: "use labelIDs instead")
    @NSManaged public var locationNumber: NSNumber  //Deprecated, use LabelIDs instead
    @NSManaged public var messageID: String
    @NSManaged public var passwordEncryptedBody: String
    @NSManaged public var password: String
    @NSManaged public var passwordHint: String
    @available(*, deprecated, message: "use replyTos instead")
    @NSManaged public var replyTo: String?
    @NSManaged public var replyTos: String?
    @NSManaged public var senderObject: String?
    @NSManaged public var recipientList: String
    @NSManaged public var recipientNameList: String
    @NSManaged public var senderAddress: String
    @NSManaged public var senderName: String
    @NSManaged public var spamScore: NSNumber
    @NSManaged public var tag: String
    @NSManaged public var time: Date?
    @NSManaged public var title: String
    @NSManaged public var totalSize: NSNumber
    @NSManaged public var latestUpdateType : NSNumber
    @NSManaged public var needsUpdate : Bool
    @NSManaged public var orginalMessageID: String?
    @NSManaged public var orginalTime: Date?
    @NSManaged public var action: NSNumber?
    @NSManaged public var isSoftDelete: Bool
    @NSManaged public var expirationOffset : Int32
    //
    @NSManaged public var addressID : String?
    @NSManaged public var mimeType : String?
    
    /// loacal only
    @NSManaged public var messageType : NSNumber  // 0 message 1 rate
    @NSManaged public var messageStatus : NSNumber  // bit 0x00000000 no metadata  0x00000001 has
    
    @NSManaged public var isShowedImages : Bool
    @NSManaged public var attachments: NSSet
    @NSManaged public var labels: NSSet
    
    /// temp cache memory only
    var checkingSign : Bool = false
    var checkedSign : Bool = false
    var pgpType : PGPType = .none
    var unencrypt_outside : Bool = false
}

