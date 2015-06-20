//
//  MessageAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


public class MessageAPI {
    static let MessageAPIVersion : Int = 1
    
    static let MessageAPIPath = "/messages"
    
    
    public class MessageDraftRequest : ApiRequest {
        let message : Message!;
        
        init(message: Message!) {
            self.message = message
        }
        
        public override func toJSON() -> Dictionary<String,AnyObject> {
            
            let address_id : String = sharedUserDataService.userAddresses.first?.address_id ?? "1000";
            
            var messsageDict : [String : AnyObject] = [ "AddressID" : address_id,
                "Body" : message.body,
                "Subject" : message.title]
            messsageDict["ToList"] = message.recipientList.parseJson()
            messsageDict["CCList"] = message.ccList.parseJson()
            messsageDict["BCCList"] = message.bccList.parseJson()
            
            let out = ["Message" : messsageDict]
            
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
    
    
    public class MessageUpdateDraftRequest : MessageDraftRequest {
        
        override public func getRequestPath() -> String {
            return MessageAPIPath + "/draft/" + message.messageID + AppConstants.getDebugOption
        }
        
        override public func getVersion() -> Int {
            return MessageAPIVersion
        }
    }
    
    
    public class MessageActionRequest : ApiRequest {
        let messages : [Message]!
        let action : String!
        
        var ids : [String] = [String] ()
        
        init(action:String, messages: [Message]!) {
            self.messages = messages
            self.action = action
            for message in messages {
                if (message.isDetailDownloaded)
                {
                    ids.append(message.messageID)
                }
            }

        }
        
        init(action:String, ids : [String]!) {
            self.action = action
            self.ids = ids
            self.messages = [Message]()
        }
        
        public override func toJSON() -> Dictionary<String,AnyObject> {
            let out = ["IDs" : self.ids]
            
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
    
    
    

    public struct Contacts {
        let email: String
        let name: String
        
        init(email: String, name: String) {
            self.name = name
            self.email = email
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
            self.fileName = fileName
            self.mimeType = mimeType
            self.fileData = fileData
            self.fileSize = fileSize
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



