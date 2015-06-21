//
//  MessageAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 Proton Reserch. All rights reserved.
//

import Foundation


/// Message api request class
public class MessageAPI {
    
    /// current message api version
    static let MessageAPIVersion : Int      = 1
    /// base message api path
    static let MessageAPIPath :String       = "/messages"
    
    
    // MARK : Create/Update Draft Part
    
    /// create draft message request class
    public class MessageDraftRequest : ApiRequest {
        
        let message : Message!;
        
        init(message: Message!) {
            self.message = message
        }
        
        public override func toDictionary() -> Dictionary<String,AnyObject> {
            
            let address_id : String                 = sharedUserDataService.userAddresses.first?.address_id ?? "1000";
            
            var messsageDict : [String : AnyObject] = [ "AddressID" : address_id,
                "Body" : message.body,
                "Subject" : message.title]
            
            messsageDict["ToList"]                  = message.recipientList.parseJson()
            messsageDict["CCList"]                  = message.ccList.parseJson()
            messsageDict["BCCList"]                 = message.bccList.parseJson()
            
            let out                                 = ["Message" : messsageDict]
            
            println(self.JSONStringify(out, prettyPrinted: true))
            
            return out
        }
        
        override public func getRequestPath() -> String {
            
            return MessageAPIPath + "/draft"
        }
        
        override public func getVersion() -> Int {
            return MessageAPIVersion
        }
    }
    
    /// message update draft api request
    public class MessageUpdateDraftRequest : MessageDraftRequest {
        
        override public func getRequestPath() -> String {
            return MessageAPIPath + "/draft/" + message.messageID + AppConstants.getDebugOption
        }
        
        override public func getVersion() -> Int {
            return MessageAPIVersion
        }
    }
    
    
    // MARK : Message actions part
    
    
    /// mesaage action request PUT method
    public class MessageActionRequest : ApiRequest {
        let messages : [Message]!
        let action : String!
        
        var ids : [String]                      = [String] ()
        
        init(action:String, messages: [Message]!) {
            self.messages                           = messages
            self.action                             = action
            for message in messages {
                if (message.isDetailDownloaded)
                {
                    ids.append(message.messageID)
                }
            }
        }
        
        init(action:String, ids : [String]!) {
            self.action                             = action
            self.ids                                = ids
            self.messages                           = [Message]()
        }
        public override func toDictionary() -> Dictionary<String,AnyObject> {
            let out                                 = ["IDs" : self.ids]
            
            println(self.JSONStringify(out, prettyPrinted: true))
            
            return out
        }
        
        override public func getRequestPath() -> String {
            return MessageAPIPath + "/" + self.action + AppConstants.getDebugOption
        }
        
        override public func getVersion() -> Int {
            return MessageAPIVersion
        }
    }
    
    
    // MARK : Message Send part
    
    /// send message reuqest
    public class MessageSendRequest : ApiRequest {
        let messagePackage : [MessagePackages]!     // message package
        let attPackets : [AttachmentKeyPackage]!    //  for optside encrypt att.
        let clearBody : String!                     //  optional for out side user
        
        init(messagePackage: [MessagePackages]!, clearBody : String! = "", attPackages:[AttachmentKeyPackage]! = nil) {
            self.messagePackage = messagePackage
            self.clearBody = clearBody
            self.attPackets = attPackages
        }
        
        public override func toDictionary() -> Dictionary<String,AnyObject> {
            
            var out : [String : AnyObject] = [String : AnyObject]()
            
            if !self.clearBody.isEmpty {
                out["ClearBody"] = self.clearBody
            }
            
            if self.attPackets != nil {
                var attPack : [AnyObject] = [AnyObject]()
                for pack in self.attPackets {
                    attPack.append(pack.toDictionary())
                }
                out["AttachmentKeys"] = attPack
            }
            
            var package : [AnyObject] = [AnyObject]()
            if self.messagePackage != nil {
                for pack in self.messagePackage {
                    package.append(pack.toDictionary())
                }
            }
            out["Packages"] = package
            
            println(self.JSONStringify(out, prettyPrinted: true))
            return out
        }
        
        override public func getRequestPath() -> String {
            
            return MessageAPIPath + "/draft"
        }
        
        override public func getVersion() -> Int {
            return MessageAPIVersion
        }
    }
    
    /// message packages
    public class MessagePackages : ApiRequest {
        
        /// default sender address id
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
        init(address:String, type : Int, body :String!, token : String! = "", encToken : String! = "", passwordHint : String! = "", attPackets:[AttachmentKeyPackage]=[AttachmentKeyPackage]()) {
            
            self.address = address
            self.type = type
            self.body = body
            self.token = token
            self.encToken = encToken
            self.passwordHint = passwordHint
            self.attPackets = attPackets
        }
        
        // Mark : override class functions
        public override func toDictionary() -> Dictionary<String,AnyObject> {
            var atts : [AnyObject] = [AnyObject]()
            for attPacket in attPackets {
                atts.append(attPacket.toDictionary())
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
            
            //println(self.JSONStringify(out, prettyPrinted: true))
            return out
        }
    }
    
    /// message attachment key package
    public class AttachmentKeyPackage : ApiRequest {
        let ID : String!
        let keyPacket : String!
        let algo : String!
        init(attID:String!, attKey:String!, Algo : String! = "") {
            self.ID = attID
            self.keyPacket = attKey
            self.algo = Algo
        }
        
        public override func toDictionary() -> Dictionary<String,AnyObject> {
            var out = [
                "ID" : self.ID,
                "KeyPackets" : self.keyPacket]
            
            if !self.algo.isEmpty {
                out["Algo"] = self.algo
            }
            
            //println(self.JSONStringify(out, prettyPrinted: true
            return out
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
    
    public struct Attachment {
        let fileName: String
        let mimeType: String
        let fileData: Dictionary<String,String>
        let fileSize: Int
        
        init(fileName: String, mimeType: String, fileData: Dictionary<String,String>, fileSize: Int) {
            self.fileName                           = fileName
            self.mimeType                           = mimeType
            self.fileData                           = fileData
            self.fileSize                           = fileSize
        }
        
        func asJSON() -> Dictionary<String,AnyObject> {
            return [
                "FileName" : fileName,
                "MIMEType" : mimeType,
                "FileData" : fileData,
                "FileSize" : String(fileSize)]
        }
    }
    
}



