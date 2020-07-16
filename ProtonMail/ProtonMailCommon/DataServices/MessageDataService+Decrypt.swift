//
//  MessageDataService.swift
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
import Groot
import AwaitKit
import PromiseKit


/// TODO:: global access need to be refactored //TODO::fixme
//let sharedMessageDataService = MessageDataService(api: APIService.shared)

/// Message data service
extension MessageDataService {
    func decryptBodyIfNeeded(message: Message) throws -> String? {
        PMLog.D("Flags: \(message.flag.description)")
        if let passphrase = self.userDataSource?.mailboxPassword ?? message.cachedPassphrase,
            var body = self.userDataSource!.newSchema ?
                try message.decryptBody(keys: self.userDataSource!.addressKeys,
                                userKeys: self.userDataSource!.userPrivateKeys,
                                passphrase: passphrase) :
                try message.decryptBody(keys: self.userDataSource!.addressKeys,
                                passphrase: passphrase) { //DONE
            //PMLog.D(body)
            if message.isPgpMime || message.isSignedMime {
                if let mimeMsg = MIMEMessage(string: body) {
                    if let html = mimeMsg.mainPart.part(ofType: Message.MimeType.html)?.bodyString {
                        body = html
                    } else if let text = mimeMsg.mainPart.part(ofType: Message.MimeType.plainText)?.bodyString {
                        body = text.encodeHtml()
                        body = "<html><body>\(body.ln2br())</body></html>"
                    }
                    
                    let cidParts = mimeMsg.mainPart.partCIDs()
                    
                    for cidPart in cidParts {
                        if var cid = cidPart.cid,
                            let rawBody = cidPart.rawBodyString {
                            cid = cid.preg_replace("<", replaceto: "")
                            cid = cid.preg_replace(">", replaceto: "")
                            let attType = "image/jpg" //cidPart.headers[.contentType]?.body ?? "image/jpg;name=\"unknow.jpg\""
                            let encode = cidPart.headers[.contentTransferEncoding]?.body ?? "base64"
                            body = body.stringBySetupInlineImage("src=\"cid:\(cid)\"", to: "src=\"data:\(attType);\(encode),\(rawBody)\"")
                        }
                    }
                    /// cache the decrypted inline attachments
                    let atts = mimeMsg.mainPart.findAtts()
                    var inlineAtts = [AttachmentInline]()
                    for att in atts {
                        if let filename = att.getFilename()?.clear {
                            let data = att.data
                            let path = FileManager.default.attachmentDirectory.appendingPathComponent(filename)
                            do {
                                try data.write(to: path, options: [.atomic])
                            } catch {
                                continue
                            }
                            inlineAtts.append(AttachmentInline(fnam: filename, size: data.count, mime: filename.mimeType(), path: path))
                        }
                    }
                    message.tempAtts = inlineAtts
                } else { //backup plan
                    body = body.multipartGetHtmlContent ()
                }
            } else if message.isPgpInline {
                if message.isPlainText {
                    body = body.encodeHtml()
                    body = body.ln2br()
                    return body
                } else if message.isMultipartMixed {
                    ///TODO:: clean up later
                    if let mimeMsg = MIMEMessage(string: body) {
                        if let html = mimeMsg.mainPart.part(ofType: Message.MimeType.html)?.bodyString {
                            body = html
                        } else if let text = mimeMsg.mainPart.part(ofType: Message.MimeType.plainText)?.bodyString {
                            body = text.encodeHtml()
                            body = "<html><body>\(body.ln2br())</body></html>"
                        }
                        
                        if let cidPart = mimeMsg.mainPart.partCID(),
                            var cid = cidPart.cid,
                            let rawBody = cidPart.rawBodyString {
                            cid = cid.preg_replace("<", replaceto: "")
                            cid = cid.preg_replace(">", replaceto: "")
                            let attType = "image/jpg" //cidPart.headers[.contentType]?.body ?? "image/jpg;name=\"unknow.jpg\""
                            let encode = cidPart.headers[.contentTransferEncoding]?.body ?? "base64"
                            body = body.stringBySetupInlineImage("src=\"cid:\(cid)\"", to: "src=\"data:\(attType);\(encode),\(rawBody)\"")
                        }
                        /// cache the decrypted inline attachments
                        let atts = mimeMsg.mainPart.findAtts()
                        var inlineAtts = [AttachmentInline]()
                        for att in atts {
                            if let filename = att.getFilename()?.clear {
                                let data = att.data
                                let path = FileManager.default.attachmentDirectory.appendingPathComponent(filename)
                                do {
                                    try data.write(to: path, options: [.atomic])
                                } catch {
                                    continue
                                }
                                inlineAtts.append(AttachmentInline(fnam: filename, size: data.count, mime: filename.mimeType(), path: path))
                            }
                        }
                        message.tempAtts = inlineAtts
                    } else { //backup plan
                        body = body.multipartGetHtmlContent ()
                    }
                } else {
                    return body
                }
            }
            if message.isPlainText {
                body = body.encodeHtml()
                return body.ln2br()
            }
            return body
        }
        return message.body
    }
    
    
    
    func copyMessage (message: Message, copyAtts : Bool) -> Message {
        let newMessage = Message(context: CoreDataService.shared.mainManagedObjectContext)
        newMessage.toList = message.toList
        newMessage.bccList = message.bccList
        newMessage.ccList = message.ccList
        newMessage.title = message.title
        newMessage.time = Date()
        newMessage.body = message.body
        
        //newMessage.flag = message.flag
        newMessage.sender = message.sender
        newMessage.replyTos = message.replyTos
        
        newMessage.orginalTime = message.time
        newMessage.orginalMessageID = message.messageID
        newMessage.expirationOffset = 0
        
        newMessage.addressID = message.addressID
        newMessage.messageStatus = message.messageStatus
        newMessage.mimeType = message.mimeType
        newMessage.setAsDraft()
        
        newMessage.userID = self.userID
        
        if let error = newMessage.managedObjectContext?.saveUpstreamIfNeeded() {
            PMLog.D("error: \(error)")
        }
        
        var key: Key?
        if let address_id = message.addressID,
            let userinfo = self.userDataSource?.userInfo,
            let addr = userinfo.userAddresses.indexOfAddress(address_id) {
            key = addr.keys.first
        }
        
        var body : String?
        do {
            body = try self.decryptBodyIfNeeded(message: newMessage)
        } catch _ {
            //ignore it
        }
        
        var newAttachmentCount : Int = 0
        for (index, attachment) in message.attachments.enumerated() {
            PMLog.D("index: \(index)")
            if let att = attachment as? Attachment {
                if att.inline() || copyAtts {
                    /// this logic to filter out the inline messages without cid in the message body
                    if let b = body { //if body is nil. copy att by default
                        if let cid = att.contentID(), b.contains(check: cid) { //if cid is nil that means this att is not inline don't copy. and if b doesn't contain cid don't copy
                            
                        } else {
                            if !copyAtts {
                                continue
                            }
                        }
                    }
                    
                    let attachment = Attachment(context: newMessage.managedObjectContext!)
                    attachment.attachmentID = att.attachmentID
                    attachment.message = newMessage
                    attachment.fileName = att.fileName
                    attachment.mimeType = "image/jpg"
                    attachment.fileData = att.fileData
                    attachment.fileSize = att.fileSize
                    attachment.headerInfo = att.headerInfo
                    attachment.localURL = att.localURL
                    attachment.keyPacket = att.keyPacket
                    attachment.isTemp = true
                    attachment.userID = self.userID
                    do {
                        if let k = key,
                            let sessionPack = self.userDataSource!.newSchema ?
                                try att.getSession(userKey: self.userDataSource!.userPrivateKeys,
                                                   keys: self.userDataSource!.addressKeys,
                                                   mailboxPassword: self.userDataSource!.mailboxPassword) :
                                try att.getSession(keys:  self.userDataSource!.addressPrivateKeys,
                                                   mailboxPassword: self.userDataSource!.mailboxPassword),//DONE
                            let session = sessionPack.key,
                            let newkp = try session.getKeyPackage(publicKey: k.publicKey, algo:  sessionPack.algo) {
                            let encodedkp = newkp.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                            attachment.keyPacket = encodedkp
                            attachment.keyChanged = true
                        }
                    } catch {
                        
                    }
                    
                    if let error = attachment.managedObjectContext?.saveUpstreamIfNeeded() {
                        PMLog.D("error: \(error)")
                    } else {
                        newAttachmentCount += 1
                    }
                }
                
            }
        }
//        newMessage.numAttachments = NSNumber(value: message.attachments.count)
        newMessage.numAttachments = NSNumber(value: newAttachmentCount)
        return newMessage
    }
}
