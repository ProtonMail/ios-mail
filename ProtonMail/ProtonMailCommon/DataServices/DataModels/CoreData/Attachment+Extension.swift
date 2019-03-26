//
//  Attachment+Extension.swift
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
import PromiseKit
import AwaitKit
import Crypto
//TODO::fixme import header
extension Attachment {
    
    struct Attributes {
        static let entityName   = "Attachment"
        static let attachmentID = "attachmentID"
    }
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: Attributes.entityName, in: context)!, insertInto: context)
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        if let localURL = localURL {
            do {
                try FileManager.default.removeItem(at: localURL as URL)
            } catch let ex as NSError {
                PMLog.D("Could not delete \(localURL) with error: \(ex)")
            }
        }
    }
    
    // MARK: - This is private functions
    
    var downloaded: Bool {
        return localURL != nil
    }
    
    // Mark : public functions
    func encrypt(byAddrID sender_address_id: String, mailbox_pwd: String, key: String) -> ModelsEncryptedSplit? {
        do {
            if let clearData = self.fileData {
                return try clearData.encryptAttachment(sender_address_id, fileName: self.fileName, mailbox_pwd: mailbox_pwd, key: key)
            }
            
            guard let localURL = self.localURL,
                let totalSize = try FileManager.default.attributesOfItem(atPath: localURL.path)[.size] as? Int else
            {
                return nil
            }
            
            let encryptor = try Data.makeEncryptAttachmentProcessor(sender_address_id, fileName: self.fileName, totalSize: totalSize, key: key)
            let fileHandle = try FileHandle(forReadingFrom: localURL)
            
            let chunkSize = 1000000 // 1 mb
            var offset = 0
            while offset < totalSize {
                autoreleasepool() {
                    let currentChunkSize = offset + chunkSize > totalSize ? totalSize - offset : chunkSize
                    let currentChunk = fileHandle.readData(ofLength: currentChunkSize)
                    offset += currentChunkSize
                    fileHandle.seek(toFileOffset: UInt64(offset))
                    encryptor.process(currentChunk)
                }
            }
            fileHandle.closeFile()
            
            return try encryptor.finish()
        } catch {
            return nil
        }
    }
    
    func sign(byAddrID sender_address_id : String, mailbox_pwd: String, key: String) -> Data? {
        do {
            guard let out = try fileData?.signAttachment(sender_address_id, mailbox_pwd: mailbox_pwd, key: key) else {
                return nil
            }
            var error : NSError?
            let data = ArmorUnarmor(out, &error)
            if error != nil {
                return nil
            }
            
            return data
        } catch {
            return nil
        }
    }
    
    func getSession(keys: Data) throws -> ModelsSessionSplit? {
        guard let keyPacket = self.keyPacket,
            let passphrase = self.message.cachedPassphrase ?? sharedUserDataService.mailboxPassword else
        {
            return nil
        }
        
        let data: Data = Data(base64Encoded: keyPacket, options: NSData.Base64DecodingOptions(rawValue: 0))!
        let sessionKey = try data.getSessionFromPubKeyPackage(passphrase, privKeys: keys)
        return sessionKey
    }
    
    func fetchAttachment(_ downloadTask: ((URLSessionDownloadTask) -> Void)?, completion:((URLResponse?, URL?, NSError?) -> Void)?) {
        sharedMessageDataService.fetchAttachmentForAttachment(self, downloadTask: downloadTask, completion: completion)
    }
    
    
    typealias base64AttachmentDataComplete = (_ based64String : String) -> Void
    
    func base64AttachmentData(_ complete : @escaping base64AttachmentDataComplete) {
        
        if let localURL = self.localURL, FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) {
            complete( self.base64DecryptAttachment() )
            return
        }
        
        if let data = self.fileData, data.count > 0 {
            complete( self.base64DecryptAttachment() )
            return
        }
        
        self.localURL = nil
        sharedMessageDataService.fetchAttachmentForAttachment(self, downloadTask: { (taskOne : URLSessionDownloadTask) -> Void in }, completion: { (_, url, error) -> Void in
            self.localURL = url;
            complete( self.base64DecryptAttachment() )
            if error != nil {
                PMLog.D("\(String(describing: error))")
            }
        })
    }
    
    func fetchAttachmentBody() -> Promise<String> {
        return Promise { seal in
            async {
                if let localURL = self.localURL, FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) {
                    seal.fulfill(self.base64DecryptAttachment())
                    return
                }
                
                if let data = self.fileData, data.count > 0 {
                    seal.fulfill(self.base64DecryptAttachment())
                    return
                }
                
                self.localURL = nil
                sharedMessageDataService.fetchAttachmentForAttachment(self,
                                                                      customAuthCredential: self.message.cachedAuthCredential,
                                                                      downloadTask: { (taskOne : URLSessionDownloadTask) -> Void in },
                                                                      completion: { (_, url, error) -> Void in
                    self.localURL = url;
                    seal.fulfill(self.base64DecryptAttachment())
                    if error != nil {
                        PMLog.D("\(String(describing: error))")
                    }
                })
            }
            
        }
    }
    
    func base64DecryptAttachment() -> String {
        guard let passphrase = self.message.cachedPassphrase ?? sharedUserDataService.mailboxPassword,
            case let privKeys = self.message.cachedPrivateKeys ?? sharedUserDataService.addressPrivateKeys else
        {
            return ""
        }
        
        if let localURL = self.localURL {
            if let data : Data = try? Data(contentsOf: localURL as URL) {
                do {
                    if let key_packet = self.keyPacket {
                        if let keydata: Data = Data(base64Encoded:key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                            if let decryptData = try data.decryptAttachment(keydata,
                                                                            passphrase: passphrase,
                                                                            privKeys: privKeys) {
                                let strBase64:String = decryptData.base64EncodedString(options: .lineLength64Characters)
                                return strBase64
                            }
                        }
                    }
                } catch let ex as NSError{
                    PMLog.D("\(ex)")
                }
            } else if let data = self.fileData, data.count > 0 {
                do {
                    if let key_packet = self.keyPacket {
                        if let keydata: Data = Data(base64Encoded:key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                            if let decryptData = try data.decryptAttachment(keydata,
                                                                            passphrase: passphrase,
                                                                            privKeys: privKeys) {
                                let strBase64:String = decryptData.base64EncodedString(options: .lineLength64Characters)
                                return strBase64
                            }
                        }
                    }
                } catch let ex as NSError{
                    PMLog.D("\(ex)")
                }
            }
        }
        
        
        if let data = self.fileData {
            let strBase64:String = data.base64EncodedString(options: .lineLength64Characters)
            return strBase64
        }
        return ""
    }
    
    func inline() -> Bool {
        guard let headerInfo = self.headerInfo else {
            return false
        }
        
        let headerObject = headerInfo.parseObject()
        guard let inlineCheckString = headerObject["content-disposition"] else {
            return false
        }
        
        if inlineCheckString.contains("inline") || inlineCheckString.contains("attachment") { //"attachment" shouldn't be here but some outside inline messages only have attachment tag.
            return true
        }
        return false
    }
    
    func contentID() -> String? {
        guard let headerInfo = self.headerInfo else {
            return nil
        }
        
        let headerObject = headerInfo.parseObject()
        guard let inlineCheckString = headerObject["content-id"] else {
            return nil
        }
        
        let outString = inlineCheckString.preg_replace("[<>]", replaceto: "")
        
        return outString
    }
}

protocol AttachmentConvertible {
    var dataSize: Int { get }
    func toAttachment (_ message:Message, fileName : String, type:String) -> Attachment?
}

extension UIImage: AttachmentConvertible {
    var dataSize: Int {
        return self.toData().count
    }
    private func toData() -> Data! {
        return self.jpegData(compressionQuality: 0)
    }
    func toAttachment (_ message:Message, fileName : String, type:String) -> Attachment? {
        if let fileData = self.toData() {
            if let context = message.managedObjectContext {
                let attachment = Attachment(context: context)
                attachment.attachmentID = "0"
                attachment.fileName = fileName
                attachment.mimeType = "image/jpg"
                attachment.fileData = fileData
                attachment.fileSize = fileData.count as NSNumber
                attachment.isTemp = false
                attachment.keyPacket = ""
                attachment.localURL = nil
            
                attachment.message = message
                
                let number = message.numAttachments.int32Value
                let newNum = number > 0 ? number + 1 : 1
                message.numAttachments = NSNumber(value: newNum)
                
                var error: NSError? = nil
                error = context.saveUpstreamIfNeeded()
                if error != nil {
                    PMLog.D("toAttachment () with error: \(String(describing: error))")
                }
                return attachment
            }
        }
        
        return nil
    }
}

extension Data: AttachmentConvertible {
    var dataSize: Int {
        return self.count
    }
    func toAttachment (_ message:Message, fileName : String) -> Attachment? {
        return self.toAttachment(message, fileName: fileName, type: "image/jpg")
    }
    
    func toAttachment (_ message:Message, fileName : String, type:String) -> Attachment? {
        let attachment = Attachment(context: message.managedObjectContext!)//TODO:: need check context nil or not instead of !
        attachment.attachmentID = "0"
        attachment.fileName = fileName
        attachment.mimeType = type
        attachment.fileData = self
        attachment.fileSize = self.count as NSNumber
        attachment.isTemp = false
        attachment.keyPacket = ""
        attachment.localURL = nil
        
        attachment.message = message
        
        let number = message.numAttachments.int32Value
        let newNum = number > 0 ? number + 1 : 1
        message.numAttachments = NSNumber(value: newNum)
        
        var error: NSError? = nil
        error = attachment.managedObjectContext?.saveUpstreamIfNeeded()
        if error != nil {
            PMLog.D(" toAttachment () with error: \(String(describing: error))")
        }
        return attachment
        
    }
}

extension URL: AttachmentConvertible {
    func toAttachment(_ message: Message, fileName: String, type: String) -> Attachment? {
        guard let context = message.managedObjectContext else { return nil }
        let attachment = Attachment(context: context)
        attachment.attachmentID = "0"
        attachment.fileName = fileName
        attachment.mimeType = type
        attachment.fileData = nil
        attachment.fileSize = NSNumber(value: self.dataSize)
        attachment.isTemp = false
        attachment.keyPacket = ""
        attachment.localURL = self
        
        attachment.message = message
        
        let number = message.numAttachments.int32Value
        let newNum = number > 0 ? number + 1 : 1
        message.numAttachments = NSNumber(value: newNum)
        
        var error: NSError? = nil
        error = attachment.managedObjectContext?.saveUpstreamIfNeeded()
        if error != nil {
            PMLog.D(" toAttachment () with error: \(String(describing: error))")
        }
        return attachment
    }
    
    var dataSize: Int {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: self.path),
            let size = attributes[.size] as? NSNumber else
        {
            return 0
        }
        return size.intValue
    }
    
    
}

