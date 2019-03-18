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
import QuickLook
import PassKit

class MessageAttachmentsViewModel: NSObject {
    @objc internal dynamic var attachments: [AttachmentInfo] = []
    @objc internal dynamic var contentsHeight: CGFloat = 0.0
    private var tempClearFileURL: URL?
    private var observation: NSKeyValueObservation!
    
    init(parentViewModel: Standalone) {
        self.attachments = parentViewModel.attachments
        
        super.init()
        
        self.observation = parentViewModel.observe(\.attachments) { [weak self] parentViewModel, _ in
            self?.attachments = parentViewModel.attachments
        }
    }
}

extension MessageAttachmentsViewModel {
    internal func open(_ attachmentInfo: AttachmentInfo,
                                 _ pregressUpdate: @escaping (Float) -> Void,
                                 _ fail: @escaping (NSError)->Void,
                                 _ success: @escaping (UIViewController)->Void)
    {
        guard attachmentInfo.isDownloaded, let localURL = attachmentInfo.localUrl else {
            self.downloadAttachment(attachmentInfo.att!,
                                    progressUpdate: pregressUpdate,
                                    success: { self.openEncrypted($0, localURL: $1, presenter: success) },
                                    fail: fail)
            return
        }
        
        guard FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) else {
            if let attachment = attachmentInfo.att {
                attachment.localURL = nil
                if let context = attachment.managedObjectContext,
                    let error = context.saveUpstreamIfNeeded()
                {
                    PMLog.D(" error: \(String(describing: error))")
                }
                
                self.downloadAttachment(attachment,
                                        progressUpdate: pregressUpdate,
                                        success: { self.openEncrypted($0, localURL: $1, presenter: success) },
                                        fail: fail)
            } else {
                assert(false, "can this happen at all?")
            }
            return
        }
        
        // Should this work for inline attachments maybe?
        guard let att = attachmentInfo.att else {
            self.quickLook(clearfileURL: localURL, fileName: attachmentInfo.fileName.clear, type: attachmentInfo.mimeType, presenter: success)
            assert(false, "can this happen at all?")
            return
        }
        
        self.openEncrypted(att, localURL: localURL, presenter: success)
    }
    
    private func downloadAttachment(_ attachment: Attachment,
                                    progressUpdate setProgress: @escaping (Float)->Void,
                                    success: @escaping (Attachment, URL)->Void,
                                    fail: @escaping (NSError)->Void)
    {
        let totalValue = attachment.fileSize.floatValue
        sharedMessageDataService.fetchAttachmentForAttachment(attachment, downloadTask: { taskOne in
            setProgress(0.0)
            sharedAPIService.getSession().setDownloadTaskDidWriteDataBlock { _, taskTwo, _, totalBytesWritten, _ in
                guard taskOne == taskTwo else { return }
                var progress = Float(totalBytesWritten) / totalValue
                if progress >= 1.0 {
                    progress = 1.0
                }
                setProgress(progress)
            }
        }, completion: { _, url, error in
            setProgress(1.0)
            guard error == nil, let url = url else {
                fail(error!)
                return
            }
            success(attachment, url)
        })
    }
    
    private func openEncrypted(_ attachment: Attachment,
                               localURL: URL,
                               presenter: (UIViewController)->Void)
    {
        guard let key_packet = attachment.keyPacket,
            let data: Data = Data(base64Encoded:key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) else
        {
            assert(false, "what can cause this?")
            return
        }
        self.quickLook(encryptedFileURL: localURL, keyPackage: data, fileName: attachment.fileName.clear, type: attachment.mimeType, presenter: presenter)
    }
}

// Quick look - should this be done by coordinator?
extension MessageAttachmentsViewModel: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    private func quickLook(encryptedFileURL: URL,
                           keyPackage: Data,
                           fileName: String,
                           type: String,
                           presenter: (UIViewController)->Void)
    {
        guard let data: Data = try? Data(contentsOf: encryptedFileURL) else {
            let alert = LocalString._cant_find_this_attachment.alertController()
            alert.addOKAction()
            presenter(alert)
            return
        }
        
        do {
            self.tempClearFileURL = FileManager.default.attachmentDirectory.appendingPathComponent(fileName)
            guard let decryptData = try data.decryptAttachment(keyPackage, passphrase: sharedUserDataService.mailboxPassword!, privKeys: sharedUserDataService.addressPrivKeys) else
            {
                throw NSError()
            }
            try decryptData.write(to: self.tempClearFileURL!, options: [.atomic])
            self.quickLook(clearfileURL: self.tempClearFileURL!, fileName: fileName, type: type, presenter: presenter)
        } catch _ {
            let alert = LocalString._cant_decrypt_this_attachment.alertController();
            alert.addOKAction()
            presenter(alert)
        }
    }
    
    private func quickLook(clearfileURL: URL,
                           fileName:String,
                           type: String,
                           presenter: (UIViewController)->Void)
    {
        self.tempClearFileURL = clearfileURL // will use it in DataSource
        
        // FIXME: use UTI here
        guard (type == "application/vnd.apple.pkpass" || fileName.contains(check: ".pkpass") == true),
            let pkfile = try? Data(contentsOf: clearfileURL) else
        {
            let previewQL = QuickViewViewController()
            previewQL.dataSource = self
            presenter(previewQL)
            return
        }
        
        guard let pass = try? PKPass(data: pkfile),
            let vc = PKAddPassesViewController(pass: pass),
            // as of iOS 12.0 SDK, PKAddPassesViewController will not be initialized on iPads without any warning 🤯
            (vc as UIViewController?) != nil else
        {
            let previewQL = QuickViewViewController()
            previewQL.dataSource = self
            presenter(previewQL)
            return
        }
        
        presenter(vc)
    }
    
    // delegate, datasource

    internal func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    internal func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.tempClearFileURL! as QLPreviewItem
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        /* Should we remove the clearfile here? */
//        try? FileManager.default.removeItem(at: self.tempClearFileURL!)
//        self.tempClearFileURL = nil
    }
}
