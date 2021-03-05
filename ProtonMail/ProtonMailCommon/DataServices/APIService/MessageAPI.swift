//
//  MessageAPI.swift
//  ProtonMail - Created on 6/18/15.
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
import PromiseKit
import AwaitKit
import PMCommon



//Message API
//Doc: V1 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_messages.md
//Doc: V3 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_messages_v3.md
struct MessageAPI {
    /// base message api path
    static let path :String = "/\(Constants.App.API_PREFIXED)/messages"
    
    //Get a list of message metadata [GET]
    static let v_fetch_messages : Int = -1
    
    //Get grouped message count [GET]
    static let v_message_count : Int = -1
    
    static let v_create_draft : Int = -1
    
    static let v_update_draft : Int = -1
    
    // inlcude read/unread
    static let V_MessageActionRequest : Int = -1
    
    //Send a message [POST]
    static let v_send_message : Int = -1
    
    //Label/move an array of messages [PUT]
    static let v_label_move_msgs : Int = -1
    
    //Unlabel an array of messages [PUT]
    static let v_unlabel_msgs : Int = -1
    
    //Delete all messages with a label/folder [DELETE]
    static let v_empty_label_folder : Int = -1
    
    //Delete an array of messages [PUT]
    static let v_delete_msgs : Int = -1
    
    //Undelete Messages [/messages/undelete]
    static let v_undelete_msgs : Int = -1
    
    //Label/Move Messages [/messages/label] [PUT]
    static let v_apply_label_to_messages : Int = -1
    
    //Unlabel Messages [/messages/unlabel] [PUT]
    static let v_remove_label_from_message : Int = -1
}


 
// MARK : apply label to message  -- Response
final class ApplyLabelToMessages : Request {
    var labelID: String
    var messages:[String]
    
    init(labelID: String, messages: [String]) {
        self.labelID = labelID
        self.messages = messages
    }
    
    var parameters: [String : Any]? {
        var out : [String : Any] = [String : Any]()
        out["LabelID"] = self.labelID
        out["IDs"] = messages
        return out
    }
    
    var method: HTTPMethod {
        return .put
    }
    
    var path: String {
        return MessageAPI.path + "/label"
    }
}

final class SearchMessage: Request {
    var keyword: String
    var page: Int
    
    init(keyword: String, page: Int) {
        self.keyword = keyword
        self.page = page
    }
    
    var parameters: [String : Any]? {
        var out : [String : Any] = [String : Any]()
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


// MARK : remove label from message -- Response
final class RemoveLabelFromMessages : Request {
    
    var labelID: String
    var messages:[String]
    
    init(labelID:String, messages: [String]) {
        self.labelID = labelID
        self.messages = messages
    }
    
    var parameters: [String : Any]? {
        var out : [String : Any] = [String : Any]()
        out["LabelID"] = self.labelID
        out["IDs"] = messages
        return out
    }
    
    var method: HTTPMethod {
        return .put
    }
    
    var path: String {
        return MessageAPI.path + "/unlabel"
    }
}


// MARK : Get messages part --- MessageCountResponse
final class MessageCount : Request {
    var path: String {
        return MessageAPI.path + "/count"
    }
}

// MARK : Get messages part --- Response
final class FetchMessages : Request {
    let labelID : String
    let startTime : Int?
    let endTime : Int
    
    init(labelID : String, endTime : Int = 0) {
        self.labelID = labelID
        self.endTime = endTime
        self.startTime = 0
    }
    
    var parameters: [String : Any]? {
        var out : [String : Any] = ["Sort" : "Time"]
        out["LabelID"] = self.labelID
        if self.endTime > 0 {
            let newTime = self.endTime - 1
            out["End"] = newTime
        }
        PMLog.D( out.json(prettyPrinted: true) )
        return out
    }
    
    var path: String {
        return MessageAPI.path
    }
}

/// Response
final class FetchMessagesByID : Request {
    let msgIDs : [String]
    
    init(msgIDs: [String]) {
        self.msgIDs = msgIDs
    }
    
    internal func buildURL () -> String {
        var out = ""
        for msgID in self.msgIDs {
            if !out.isEmpty {
                out = out + "&"
            }
            out = out + "ID[]=\(msgID)"
        }
        if !out.isEmpty {
            out = "?" + out
        }
        return out
    }
    var path: String {
        return MessageAPI.path + self.buildURL()
    }
}


///Response
final class FetchMessagesByLabel : Request {
    let labelID : String
    let startTime : Int?
    let endTime : Int
    
    init(labelID : String, endTime : Int = 0) {
        self.labelID = labelID
        self.endTime = endTime
        self.startTime = 0
    }
    
    var parameters: [String : Any]? {
        var out : [String : Any] = ["Sort" : "Time"]
        out["LabelID"] = self.labelID
        if self.endTime > 0 {
            let newTime = self.endTime - 1
            out["End"] = newTime
        }
        PMLog.D( out.json(prettyPrinted: true) )
        return out
    }
    
    var path: String {
        return MessageAPI.path
    }
}

// MARK : Create/Update Draft Part
/// create draft message request class -- MessageResponse
class CreateDraft : Request {
    
    let message : Message
    let fromAddress: Address?
    
    /// TODO:: here need remove refrence of Message should create a Draft builder and a seperate package
    ///
    /// - Parameter message: Message
    init(message: Message, fromAddr: Address?) {
        self.message = message
        self.fromAddress = fromAddr
    }
    
    var parameters: [String : Any]? {
        var messsageDict : [String : Any] = [
            "Body" : message.body,
            "Subject" : message.title,
            "Unread" : message.unRead ? 1 : 0]
        
        let fromaddr = fromAddress
        let name = fromaddr?.display_name ?? "unknow"
        let address = fromaddr?.email ?? "unknow"
        
        messsageDict["Sender"] = [
            "Name": name,
            "Address": address
        ]
        
        messsageDict["ToList"]  = message.toList.parseJson()
        messsageDict["CCList"]  = message.ccList.parseJson()
        messsageDict["BCCList"] = message.bccList.parseJson()
        var out : [String : Any] = ["Message" : messsageDict]
        
        if let orginalMsgID = message.orginalMessageID {
            if !orginalMsgID.isEmpty {
                out["ParentID"] = message.orginalMessageID
                out["Action"] = message.action ?? "0"  //{0|1|2} // Optional, reply = 0, reply all = 1, forward = 2 m
            }
        }
        
        if let attachments = self.message.attachments.allObjects as? [Attachment] {
            var atts : [String : String] = [:]
            for att in attachments {
                if att.keyChanged {
                    atts[att.attachmentID] = att.keyPacket
                }
            }
            out["AttachmentKeyPackets"] = atts
        }
        
        //PMLog.D( out.json(prettyPrinted: true) )
        return out
    }
    
    //custom auth credentical
    var auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
    
    var path: String {
        return MessageAPI.path
    }
    
    var method: HTTPMethod {
        return .post
    }
}

/// message update draft api request
final class UpdateDraft : CreateDraft {
    
    convenience init(message: Message, fromAddr: Address?, authCredential: AuthCredential? = nil) {
        self.init(message: message, fromAddr: fromAddr)
        self.auth = authCredential
    }
    
    override var path: String {
        return MessageAPI.path + "/" + message.messageID
    }

    override var method: HTTPMethod {
        return .put
    }
}

// MARK : Message actions part

/// mesaage action request PUT method   --- Response
final class MessageActionRequest : Request {
    let messages : [Message]
    let action : String
    var ids : [String] = [String] ()
    private var currentLabelID: Int? = nil
    
    init(action: String, messages: [Message]) {
        self.messages = messages
        self.action = action
        for message in messages {
            if message.isDetailDownloaded {
                ids.append(message.messageID)
            }
        }
    }
    
    init(action: String, ids: [String], labelID: String? = nil) {
        self.action = action
        self.ids = ids
        self.messages = [Message]()
        
        if let num = Int(labelID ?? "") {
            self.currentLabelID = num
        }
    }
    
    var parameters: [String : Any]? {
        var out: [String: Any] = ["IDs" : self.ids]
        if let id = self.currentLabelID {
            out["CurrentLabelID"] = id
        }
        return out
    }
    
    var path: String {
        return MessageAPI.path + "/" + self.action
    }
    
    var method: HTTPMethod {
        return .put
    }
}

/// empty trash or spam -- Response
final class EmptyMessage : Request {
    
    let labelID : String
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

// MARK : Message Send part
/// send message reuqest -- SendResponse
final class SendMessage : Request {
    var messagePackage : [AddressPackageBase]  // message package
    var body : String
    let messageID : String
    let expirationTime : Int32
    
    var clearBody : ClearBodyPackage?
    var clearAtts : [ClearAttachmentPackage]?
    
    var mimeDataPacket : String
    var clearMimeBody : ClearBodyPackage?
    
    var plainTextDataPacket : String
    var clearPlainTextBody : ClearBodyPackage?
    
    init(messageID : String, expirationTime: Int32?,
         messagePackage: [AddressPackageBase]!, body : String,
         clearBody : ClearBodyPackage?, clearAtts: [ClearAttachmentPackage]?,
         mimeDataPacket : String, clearMimeBody : ClearBodyPackage?,
         plainTextDataPacket : String, clearPlainTextBody : ClearBodyPackage?,
         authCredential: AuthCredential?) {
        self.messageID = messageID
        self.messagePackage = messagePackage
        self.body = body
        self.expirationTime = expirationTime ?? 0
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
    
    var parameters: [String : Any]? {
        var out : [String : Any] = [String : Any]()
        
        if self.expirationTime > 0 {
            out["ExpiresIn"] = self.expirationTime
        }
        //optional this will override app setting
        //out["AutoSaveContacts"] = "\(0 / 1)"
        
        let normalPackage = messagePackage.filter { $0.type.rawValue < 10 }
        let mimePackage = messagePackage.filter { $0.type.rawValue > 10 }
        
        
        let plainTextPackage = normalPackage.filter { $0.plainText == true }
        let htmlPackage = normalPackage.filter { $0.plainText == false }
        
        //packages object
        var packages : [Any] = [Any]()
        
        //plaintext
        if plainTextPackage.count > 0 {
            //not mime
            var plainTextAddress : [String : Any] = [String : Any]()
            var addrs = [String: Any]()
            var type = SendType()
            for mp in plainTextPackage {
                addrs[mp.email] = mp.parameters!
                type.insert(mp.type)
            }
            plainTextAddress["Addresses"] = addrs
            //"Type": 15, // 8|4|2|1, all types sharing this package, a bitmask
            plainTextAddress["Type"] = type.rawValue
            plainTextAddress["Body"] = self.plainTextDataPacket
            plainTextAddress["MIMEType"] = "text/plain"
            
            if let cb = self.clearPlainTextBody {
                // Include only if cleartext recipients
                plainTextAddress["BodyKey"] = [
                    "Key" : cb.key,
                    "Algorithm" : cb.algo
                ]
            }
            
            if let cAtts = clearAtts {
                // Only include if cleartext recipients, optional if no attachments
                var atts : [String:Any] = [String:Any]()
                for it in cAtts {
                    atts[it.ID] = [
                        "Key" : it.encodedSession,
                        "Algorithm" : it.algo == "3des" ? "tripledes" : it.algo
                    ]
                }
                plainTextAddress["AttachmentKeys"] = atts
            }
            packages.append(plainTextAddress)
        }
        
        
        //html text
        if htmlPackage.count > 0 {
            //not mime
            var htmlAddress : [String : Any] = [String : Any]()
            var addrs = [String: Any]()
            var type = SendType()
            for mp in htmlPackage {
                addrs[mp.email] = mp.parameters!
                type.insert(mp.type)
            }
            htmlAddress["Addresses"] = addrs
            //"Type": 15, // 8|4|2|1, all types sharing this package, a bitmask
            htmlAddress["Type"] = type.rawValue
            htmlAddress["Body"] = self.body
            htmlAddress["MIMEType"] = "text/html"
            
            if let cb = clearBody {
                // Include only if cleartext recipients
                htmlAddress["BodyKey"] = [
                    "Key" : cb.key,
                    "Algorithm" : cb.algo
                ]
            }
            
            if let cAtts = clearAtts {
                // Only include if cleartext recipients, optional if no attachments
                var atts : [String:Any] = [String:Any]()
                for it in cAtts {
                    atts[it.ID] = [
                        "Key" : it.encodedSession,
                        "Algorithm" : it.algo == "3des" ? "tripledes" : it.algo
                    ]
                }
                htmlAddress["AttachmentKeys"] = atts
            }
            packages.append(htmlAddress)
        }
        
        if mimePackage.count > 0 {
            //mime
            var mimeAddress : [String : Any] = [String : Any]()
            
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
                    "Key" : cb.key,
                    "Algorithm" : cb.algo
                ]
            }
            packages.append(mimeAddress)
        }
        out["Packages"] = packages
        //PMLog.D( out.json(prettyPrinted: true) )
        PMLog.D( "API toDict done" )
        return out
    }
    
    var path: String {
        return MessageAPI.path + "/" + self.messageID
    }
    
    var method: HTTPMethod {
        return .post
    }
}

final class SendResponse: Response {
    var responseDict: [String: Any] = [:]
    
    override func ParseResponse(_ response: [String : Any]) -> Bool {
        self.responseDict = response
        return super.ParseResponse(response)
    }
}
