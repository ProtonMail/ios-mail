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
    
    
    public class MessageDraftRequest {
        let message : Message!;
        
        init(message: Message!) {
            self.message = message
        }
        
        func toJSON() -> Dictionary<String,AnyObject> {
            return [
                "Name" : ""]
            
            //            var parameterStrings: [String : String] = [
            //                "MessageID" : messageID,
            //                "RecipientList" : recipientList,
            //                "BCCList" : bccList,
            //                "CCList" : ccList,
            //                "MessageTitle" : title,
            //                "PasswordHint" : passwordHint]
            //
            //            var parameters: [String : AnyObject] = filteredMessageStringParameters(parameterStrings)
            //
            //            if expirationDate != nil {
            //                parameters["ExpirationTime"] = Double(expirationDate?.timeIntervalSince1970 ?? 0)
            //            }
            //
            //            parameters["IsEncrypted"] =  isEncrypted.isEncrypted() ? 1 : 0
            //            parameters["MessageBody"] = body
            //
            //            if !attachments.isEmpty {
            //                var attachmentsArray: [[String : AnyObject]] = []
            //
            //                for attachment in attachments {
            //                    attachmentsArray.append(attachment.asJSON())
            //                }
            //                
            //                parameters["Attachments"] = attachmentsArray
            //            }
            //            
            
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



