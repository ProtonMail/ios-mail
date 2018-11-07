//
//  MessageAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 Proton Reserch. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit


// MARK : apply label to message
final class ApplyLabelToMessages : ApiRequest<ApiResponse> {
    var labelID: String!
    var messages:[String]!
    
    init(labelID: String!, messages: [String]!) {
        self.labelID = labelID
        self.messages = messages
    }
    
    override func toDictionary() -> [String : Any]? {
        var out : [String : Any] = [String : Any]()
        out["LabelID"] = self.labelID
        out["IDs"] = messages
        return out
    }
    
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override func path() -> String {
        return MessageAPI.path + "/label" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_apply_label_to_messages
    }
}


// MARK : remove label from message
final class RemoveLabelFromMessages : ApiRequest<ApiResponse> {
    
    var labelID: String!
    var messages:[String]!
    
    init(labelID:String!, messages: [String]!) {
        self.labelID = labelID
        self.messages = messages
    }
    
    override func toDictionary() -> [String : Any]? {
        var out : [String : Any] = [String : Any]()
        out["LabelID"] = self.labelID
        out["IDs"] = messages
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override func path() -> String {
        return MessageAPI.path + "/unlabel" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_remove_label_from_message
    }
}


// MARK : Get messages part
final class MessageCount : ApiRequest<MessageCountResponse> {
    override func path() -> String {
        return MessageAPI.path + "/count" + AppConstants.DEBUG_OPTION
    }
    override func apiVersion() -> Int {
        return MessageAPI.v_message_count
    }
}

// MARK : Get messages part
final class FetchMessages : ApiRequest<ApiResponse> {
    let location : MessageLocation!
    let startTime : Int?
    let endTime : Int
    
    init(location:MessageLocation, endTime : Int = 0) {
        self.location = location
        self.endTime = endTime
        self.startTime = 0
    }
    
    override func toDictionary() -> [String : Any]? {
        var out : [String : Any] = ["Sort" : "Time"]
        let labelIDRaw = self.location.rawValue >= 0 ? self.location.rawValue : 0
        out["LabelID"] = "\(labelIDRaw)"
        if self.endTime > 0 {
            let newTime = self.endTime - 1
            out["End"] = newTime
        }
        PMLog.D( out.json(prettyPrinted: true) )
        return out
    }
    
    override func path() -> String {
        return MessageAPI.path + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_fetch_messages
    }
}

final class FetchMessagesByID : ApiRequest<ApiResponse> {
    let messages : [Message]!
    init(messages: [Message]) {
        self.messages = messages
    }
    
    internal func buildURL () -> String {
        var out = "";
        
        for message in self.messages {
            if message.managedObjectContext != nil {
                if !out.isEmpty {
                    out = out + "&"
                }
                out = out + "ID[]=\(message.messageID)"
            }
        }
        if !out.isEmpty {
            out = "?" + out
        }
        return out;
    }
    
    override func path() -> String {
        return MessageAPI.path + self.buildURL()
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_fetch_messages
    }
}

final class FetchMessagesByLabel : ApiRequest<ApiResponse> {
    let labelID : String!
    let startTime : Int?
    let endTime : Int
    
    init(labelID : String, endTime : Int = 0) {
        self.labelID = labelID
        self.endTime = endTime
        self.startTime = 0
    }
    
    override func toDictionary() -> [String : Any]? {
        var out : [String : Any] = ["Sort" : "Time"]
        out["LabelID"] = self.labelID
        if self.endTime > 0 {
            let newTime = self.endTime - 1
            out["End"] = newTime
        }
        PMLog.D( out.json(prettyPrinted: true) )
        return out
    }
    
    override func path() -> String {
        return MessageAPI.path + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_fetch_messages
    }
}

// MARK : Create/Update Draft Part
/// create draft message request class
class CreateDraft : ApiRequest<MessageResponse> {
    
    let message : Message!
    
    /// TODO:: here need remove refrence of Message should create a Draft builder and a seperate package
    ///
    /// - Parameter message: Message
    init(message: Message!) {
        self.message = message
    }
    
    override func toDictionary() -> [String : Any]? {
        var messsageDict : [String : Any] = [
            "Body" : message.body,
            "Subject" : message.title,
            "Unread" : message.unRead]
        
        let fromaddr = message.fromAddress ?? message.defaultAddress
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
        
        if let attachments = self.message?.attachments.allObjects as? [Attachment] {
            var atts : [String : String] = [:]
            for att in attachments {
                if att.keyChanged {
                    atts[att.attachmentID] = att.keyPacket
                }
            }
            out["AttachmentKeyPackets"] = atts
        }
        
        PMLog.D( out.json(prettyPrinted: true) )
        return out
    }
    
    override func path() -> String {
        return MessageAPI.path
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_create_draft
    }
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
}

/// message update draft api request
final class UpdateDraft : CreateDraft {
    
    override func path() -> String {
        return MessageAPI.path + "/" + message.messageID + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_update_draft
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
}

// MARK : Message actions part

/// mesaage action request PUT method
final class MessageActionRequest : ApiRequest<ApiResponse> {
    let messages : [Message]!
    let action : String!
    var ids : [String] = [String] ()
    
    init(action:String, messages: [Message]!) {
        self.messages = messages
        self.action = action
        for message in messages {
            if message.isDetailDownloaded {
                ids.append(message.messageID)
            }
        }
    }
    
    init(action:String, ids : [String]!) {
        self.action = action
        self.ids = ids
        self.messages = [Message]()
    }
    
    override func toDictionary() -> [String : Any]? {
        let out = ["IDs" : self.ids]
        return out
    }
    
    override func path() -> String {
        return MessageAPI.path + "/" + self.action + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.V_MessageActionRequest
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
}

/// empty trash or spam
final class EmptyMessage : ApiRequest <ApiResponse> {
    let labelID : String
    
    init(labelID: String) {
        self.labelID = labelID
    }
    
    override func toDictionary() -> [String : Any]? {
        return nil
    }
    
    override func path() -> String {
        return MessageAPI.path + "/empty?LabelID=" + self.labelID + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_empty_label_folder
    }
    
    override func method() -> APIService.HTTPMethod {
        return .delete
    }
}

// MARK : Message Send part
/// send message reuqest
final class SendMessage : ApiRequestNew<ApiResponse> {
    var messagePackage : [AddressPackageBase]!  // message package
    var body : String!
    let messageID : String!
    let expirationTime : Int32!
    
    var clearBody : ClearBodyPackage?
    var clearAtts : [ClearAttachmentPackage]?
    
    var mimeDataPacket : String!
    var clearMimeBody : ClearBodyPackage?
    
    var plainTextDataPacket : String!
    var clearPlainTextBody : ClearBodyPackage?
    
    init(messageID : String, expirationTime: Int32?,
         messagePackage: [AddressPackageBase]!, body : String,
         clearBody : ClearBodyPackage?, clearAtts: [ClearAttachmentPackage]?,
         mimeDataPacket : String, clearMimeBody : ClearBodyPackage?,
         plainTextDataPacket : String, clearPlainTextBody : ClearBodyPackage?) {
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
    }
    
    override func toDictionary() -> [String : Any]? {
        var out : [String : Any] = [String : Any]()
        out["ExpirationTime"] = self.expirationTime
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
                addrs[mp.email] = mp.toDictionary()!
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
                addrs[mp.email] = mp.toDictionary()!
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
                addrs[mp.email] = mp.toDictionary()!
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
        PMLog.D( out.json(prettyPrinted: true) )
        return out
    }
    
    override func path() -> String {
        return MessageAPI.path + "/" + self.messageID + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_send_message
    }
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
}
