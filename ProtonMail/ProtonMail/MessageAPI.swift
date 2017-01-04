//
//  MessageAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 Proton Reserch. All rights reserved.
//

import Foundation


// MARK : Get messages part
public class MessageCountRequest<T : ApiResponse> : ApiRequest<T> {
    override public func getRequestPath() -> String {
        return MessageAPI.Path + "/count" + AppConstants.getDebugOption
    }
    override public func getVersion() -> Int {
        return MessageAPI.V_MessageFetchRequest
    }
}

public class MessageCountResponse : ApiResponse {
    var counts : [Dictionary<String, AnyObject>]?
    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {
        self.counts = response?["Counts"] as? [Dictionary<String, AnyObject>]
        return true
    }
}


// MARK : Get messages part
public class MessageFetchRequest<T : ApiResponse> : ApiRequest<T> {
    let location : MessageLocation!
    let startTime : Int?
    let endTime : Int
    
    init(location:MessageLocation, endTime : Int = 0) {
        self.location = location
        self.endTime = endTime
        self.startTime = 0
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        var out : [String : AnyObject] = ["Sort" : "Time"]
        if self.location == MessageLocation.starred {
            out["Starred"] = 1
        } else {
            out["Location"] = self.location.rawValue
        }
        if(self.endTime > 0)
        {
            let newTime = self.endTime - 1
            out["End"] = newTime
        }
        
        PMLog.D(self.JSONStringify(out, prettyPrinted: true))
        return out
    }
    
    override public func getRequestPath() -> String {
        return MessageAPI.Path + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return MessageAPI.V_MessageFetchRequest
    }
}

public class MessageFetchByIDsRequest<T : ApiResponse> : ApiRequest<T> {
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
    
    override public func getRequestPath() -> String {
        return MessageAPI.Path + self.buildURL()
    }
    
    override public func getVersion() -> Int {
        return MessageAPI.V_MessageFetchRequest
    }
}


public class MessageByLabelRequest<T : ApiResponse> : ApiRequest<T> {
    let labelID : String!
    let startTime : Int?
    let endTime : Int
    
    init(labelID : String, endTime : Int = 0) {
        self.labelID = labelID
        self.endTime = endTime
        self.startTime = 0
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        var out : [String : AnyObject] = ["Sort" : "Time"]
        out["Label"] = self.labelID
        if(self.endTime > 0)
        {
            let newTime = self.endTime - 1
            out["End"] = newTime
        }
        
        PMLog.D(self.JSONStringify(out, prettyPrinted: true))
        return out
    }
    
    override public func getRequestPath() -> String {
        return MessageAPI.Path + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return MessageAPI.V_MessageFetchRequest
    }
}

// MARK : Create/Update Draft Part

/// create draft message request class
public class MessageDraftRequest<T: ApiResponse>  : ApiRequest<T> {
    
    let message : Message!;
    
    init(message: Message!) {
        self.message = message
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        let address_id : String                 = message.getAddressID
        var messsageDict : [String : AnyObject] = [
            "AddressID" : address_id,
            "Body" : message.body,
            "Subject" : message.title,
            "IsRead" : message.isRead]
        messsageDict["ToList"]                  = message.recipientList.parseJson()
        messsageDict["CCList"]                  = message.ccList.parseJson()
        messsageDict["BCCList"]                 = message.bccList.parseJson()
        var out : [String : AnyObject] = ["Message" : messsageDict]
        
        if let orginalMsgID = message.orginalMessageID {
            if !orginalMsgID.isEmpty {
                out["ParentID"] = message.orginalMessageID
                out["Action"] = message.action ?? "0"   //{0|1|2} // Optional, reply = 0, reply all = 1, forward = 2
            }
        }
        
        PMLog.D(self.JSONStringify(out, prettyPrinted: true))
        return out
        
    }
    
    override public func getRequestPath() -> String {
        return MessageAPI.Path + "/draft"
    }
    
    override public func getVersion() -> Int {
        return MessageAPI.V_MessageDraftRequest
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .POST
    }
}

/// message update draft api request
public class MessageUpdateDraftRequest<T: ApiResponse> : MessageDraftRequest<T> {
    override init(message: Message!) {
        super.init(message: message)
    }
    
    override public func getRequestPath() -> String {
        return MessageAPI.Path + "/draft/" + message.messageID + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return MessageAPI.V_MessageUpdateDraftRequest
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .PUT
    }
}


public class MessageResponse : ApiResponse {
    var message : Dictionary<String, AnyObject>?
    
    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {
        self.message = response?["Message"] as? Dictionary<String, AnyObject>
        return true
    }
}


// MARK : Message actions part

/// mesaage action request PUT method
public class MessageActionRequest<T : ApiResponse>  : ApiRequest <T> {
    let messages : [Message]!
    let action : String!
    var ids : [String] = [String] ()
    
    
    public init(action:String, messages: [Message]!) {
        self.messages = messages
        self.action = action
        for message in messages {
            if message.isDetailDownloaded {
                ids.append(message.messageID)
            }
        }
    }
    
    public init(action:String, ids : [String]!) {
        self.action = action
        self.ids = ids
        self.messages = [Message]()
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        let out = ["IDs" : self.ids]
        // PMLog.D(self.JSONStringify(out, prettyPrinted: true))
        return out
    }
    
    override public func getRequestPath() -> String {
        return MessageAPI.Path + "/" + self.action + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return MessageAPI.V_MessageActionRequest
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .PUT
    }
}

/// empty trash or spam
public class MessageEmptyRequest<T : ApiResponse> : ApiRequest <T> {
    let location : String!
    
    public init(location: String! ) {
        self.location = location
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        return nil
    }
    
    override public func getRequestPath() -> String {
        return MessageAPI.Path + "/" + location + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return MessageAPI.V_MessageEmptyRequest
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .DELETE
    }
}

// MARK : Message Send part

/// send message reuqest
public class MessageSendRequest<T: ApiResponse>  : ApiRequest<T> {
    var messagePackage : [MessagePackage]!     // message package
    var attPackets : [AttachmentKeyPackage]!    //  for optside encrypt att.
    var clearBody : String!                     //  optional for out side user
    let messageID : String!
    let expirationTime : Int32?
    
    init(messageID : String!, expirationTime: Int32?, messagePackage: [MessagePackage]!, clearBody : String! = "", attPackages:[AttachmentKeyPackage]! = nil) {
        self.messageID = messageID
        self.messagePackage = messagePackage
        self.clearBody = clearBody
        self.attPackets = attPackages
        self.expirationTime = expirationTime
    }
    
    override func toDictionary() -> Dictionary<String,AnyObject>? {
        
        var out : [String : AnyObject] = [String : AnyObject]()
        
        if !self.clearBody.isEmpty {
            out["ClearBody"] = self.clearBody
        }
        
        if self.attPackets != nil {
            var attPack : [AnyObject] = [AnyObject]()
            for pack in self.attPackets {
                attPack.append(pack.toDictionary()!)
            }
            out["AttachmentKeys"] = attPack
        }
        
        if let expTime = expirationTime {
            if expTime > 0 {
                out["ExpirationTime"] = "\(expTime)"
            }
        }
        
        var package : [AnyObject] = [AnyObject]()
        if self.messagePackage != nil {
            for pack in self.messagePackage {
                package.append(pack.toDictionary()!)
            }
        }
        out["Packages"] = package
        
        PMLog.D(self.JSONStringify(out, prettyPrinted: true))
        return out
    }
    
    override public func getRequestPath() -> String {
        return MessageAPI.Path + "/send/" + self.messageID + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return MessageAPI.V_MessageSendRequest
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .POST
    }
}

/// message packages
public class MessagePackage : Package {
    
    /// default sender email address
    let address : String!
    /** send encrypt message package type
    *   1 internal
    *   2 external
    */
    let type : Int!
    /// encrypt message body
    let body : String!
    /// optional for outside
    let token : String!
    /// optional for outside
    let encToken : String!
    /// optional encrypt password hint
    let passwordHint : String!
    /// optional attachment package
    let attPackets : [AttachmentKeyPackage]
    
    /**
    message packages
    
    :param: address    addresses
    :param: type       package type
    :param: body       package encrypt body
    :param: token      eo token optional only for encrypt outside
    :param: encToken   eo encToken optional only for encrypt outside
    :param: attPackets attachment package
    
    :returns: self
    */
    init(address:String, type : Int, body :String!, attPackets:[AttachmentKeyPackage]=[AttachmentKeyPackage](), token : String! = "", encToken : String! = "", passwordHint : String! = "") {
        
        self.address = address
        self.type = type
        self.body = body
        self.token = token
        self.encToken = encToken
        self.passwordHint = passwordHint
        self.attPackets = attPackets
    }
    
    // Mark : override class functions
    func toDictionary() -> Dictionary<String,AnyObject>? {
        var atts : [AnyObject] = [AnyObject]()
        for attPacket in attPackets {
            atts.append(attPacket.toDictionary()!)
        }
        var out : Dictionary<String, AnyObject> = [
            "Address" : self.address,
            "Type" : self.type,
            "Body" : self.body,
            "KeyPackets" : atts]
        
        if !self.token!.isEmpty {
            out["Token"] = self.token
        }
        
        if !self.encToken.isEmpty {
            out["EncToken"] = self.encToken
        }
        
        if !self.passwordHint.isEmpty {
            out["PasswordHint"] = self.passwordHint
        }
        
        return out
    }
}


// message attachment key package
public class AttachmentKeyPackage : Package {
    let ID : String!
    let keyPacket : String!
    let algo : String!
    init(attID:String!, attKey:String!, Algo : String! = "") {
        self.ID = attID
        self.keyPacket = attKey
        self.algo = Algo
    }
    
    public func toDictionary() -> Dictionary<String,AnyObject>? {
        var out = [ "ID" : self.ID ]
        if !self.algo.isEmpty {
            out["Algo"] = self.algo
            out["Key"] = self.keyPacket
        } else {
            out["KeyPackets"] = self.keyPacket
        }
        
        return out
    }
}


/**
*  temporary table for formating the message send package
*/
public class TempAttachment {
    let ID : String!
    let Key : NSData?
    
    public init(id: String, key: NSData?) {
        self.ID = id
        self.Key = key
    }
}



/**
* MARK : down all the old code
*/

/**
*  contact
*/
public struct Contacts {
    let email: String
    let name: String
    
    init(email: String, name: String) {
        self.name                               = name
        self.email                              = email
    }
    
    func asJSON() -> Dictionary<String,AnyObject> {
        return [
            "Name" : self.name,
            "Email" : self.email]
    }
}

//    public struct Attachment {
//        let fileName: String
//        let mimeType: String
//        let fileData: Dictionary<String,String>
//        let fileSize: Int
//
//        init(fileName: String, mimeType: String, fileData: Dictionary<String,String>, fileSize: Int) {
//            self.fileName                           = fileName
//            self.mimeType                           = mimeType
//            self.fileData                           = fileData
//            self.fileSize                           = fileSize
//        }
//
//        func asJSON() -> Dictionary<String,AnyObject> {
//            return [
//                "FileName" : fileName,
//                "MIMEType" : mimeType,
//                "FileData" : fileData,
//                "FileSize" : String(fileSize)]
//        }
//    }





