//
//  MessageAttachmentsViewModel.swift
//  ProtonMail - Created on 15/03/2019.
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

class MessageAttachmentsViewModel: NSObject {
    @objc internal dynamic var attachments: [AttachmentInfo] = []
    @objc internal dynamic var contentsHeight: CGFloat = 0.0
    private var observation: NSKeyValueObservation!
    private var parentViewModel: Standalone // to keep it alive while observation is valid (otherwise iOS 10 crashes)
    
    init(parentViewModel: Standalone) {
        self.parentViewModel = parentViewModel
        self.attachments = parentViewModel.attachments
        
        super.init()
        
        self.observation = parentViewModel.observe(\.attachments) { [weak self] parentViewModel, _ in
            self?.attachments = parentViewModel.attachments
        }
    }
    
    deinit {
        self.observation = nil
    }
}

extension MessageAttachmentsViewModel {
    private enum Errors: Error {
        case _cant_find_this_attachment
        case _cant_decrypt_this_attachment
        
        var localizedDescription: String {
            switch self {
            case ._cant_find_this_attachment: return LocalString._cant_find_this_attachment
            case ._cant_decrypt_this_attachment: return LocalString._cant_decrypt_this_attachment
            }
        }
    }
    
    internal func open(_ attachmentInfo: AttachmentInfo,
                       _ pregressUpdate: @escaping (Float) -> Void,
                       _ fail: @escaping (NSError)->Void,
                       _ opener: @escaping (URL)->Void)
    {
        guard let attachment = attachmentInfo.att else {
            // two attachment types. inline and normal att in core data
            // inline att doesn't need to decrypt and it saved in cache temporarily when decrypting the message
            // in this case just try to open it directly
            if let url = attachmentInfo.localUrl {
                opener(url)
            }
            return
        }

        let decryptor: (Attachment, URL)->Void = {
            try! self.decrypt($0, encryptedFileURL: $1, clearfile: opener)
        }
        
        guard attachmentInfo.isDownloaded, let localURL = attachmentInfo.localUrl else {
            self.downloadAttachment(attachmentInfo.att!, progressUpdate: pregressUpdate, success: decryptor, fail: fail)
            return
        }
        
        guard FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) else {
            attachment.localURL = nil
            if let context = attachment.managedObjectContext,
                let error = context.saveUpstreamIfNeeded()
            {
                PMLog.D(" error: \(String(describing: error))")
            }
            
            self.downloadAttachment(attachment, progressUpdate: pregressUpdate, success: decryptor, fail: fail)
            return
        }
        
        decryptor(attachment, localURL)
    }
    
    private func downloadAttachment(_ attachment: Attachment,
                                    progressUpdate setProgress: @escaping (Float)->Void,
                                    success: @escaping ((Attachment, URL) ->Void ),
                                    fail: @escaping (NSError)->Void)
    {
        let totalValue = attachment.fileSize.floatValue
        sharedMessageDataService.fetchAttachmentForAttachment(attachment, downloadTask: { taskOne in
            setProgress(0.0)
            sharedAPIService.getSession().setDownloadTaskDidWriteDataBlock { _, taskTwo, _, totalBytesWritten, _ in
                guard taskOne == taskTwo else { return }
                let progress = Float(totalBytesWritten) / totalValue
                setProgress(progress)
            }
        }, completion: { _, url, networkingError in
            setProgress(1.0)
            guard networkingError == nil, let url = url else {
                fail(networkingError!)
                return
            }
            success(attachment, url)
        })
    }
    
    private func decrypt(_ attachment: Attachment,
                         encryptedFileURL: URL,
                         clearfile: (URL)->Void) throws
    {
        guard let key_packet = attachment.keyPacket,
            let keyPackage: Data = Data(base64Encoded:key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) else
        {
            assert(false, "what can cause this?")
            return
        }
        
        guard let data: Data = try? Data(contentsOf: encryptedFileURL) else {
            throw Errors._cant_find_this_attachment
        }

        // FIXME: no way we should store this file cleartext any longer than absolutely needed
        let tempClearFileURL = FileManager.default.temporaryDirectoryUrl.appendingPathComponent(attachment.fileName.clear)
        guard let decryptData = try data.decryptAttachment(keyPackage,
                                                           passphrase: sharedUserDataService.mailboxPassword!,
                                                           privKeys: sharedUserDataService.addressPrivateKeys),
            let _ = try? decryptData.write(to: tempClearFileURL, options: [.atomic]) else
        {
            throw Errors._cant_decrypt_this_attachment
        }
        
        clearfile(tempClearFileURL)
    }
}
