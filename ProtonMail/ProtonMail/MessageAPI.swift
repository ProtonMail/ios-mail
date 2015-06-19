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
            var messsageDict : [String : AnyObject] = [ "AddressID" : "0",
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



