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
    private var tempFileUri: URL?
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
    // TODO: taken from old EmailHeaderView, should make readable
    internal func openOrDownload(_ attachment: AttachmentInfo, _ pregressUpdate: @escaping (Float) -> Void) {
        if !attachment.isDownloaded {
            if let att = attachment.att {
                self.downloadAttachment(att, progressUpdate: pregressUpdate)
            }
        } else if let localURL = attachment.localUrl {
            if FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) {
                if let att = attachment.att {
                    if let key_packet = att.keyPacket {
                        if let data: Data = Data(base64Encoded:key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                            let fixedFilename = attachment.fileName.clear
                            self.openLocalURL(localURL, keyPackage: data, fileName: fixedFilename, type: attachment.mimeType)
                        }
                    }
                } else {
                    let fixedFilename = attachment.fileName.clear
                    self.openLocalURL(localURL, fileName: fixedFilename, type: attachment.mimeType)
                }
            } else {
                if let att = attachment.att {
                    att.localURL = nil
                    if let context = att.managedObjectContext {
                        let error = context.saveUpstreamIfNeeded()
                        if error != nil  {
                            PMLog.D(" error: \(String(describing: error))")
                        }
                    }
                    self.downloadAttachment(att, progressUpdate: pregressUpdate)
                }
            }
        }
    }
    
    private func downloadAttachment(_ attachment: Attachment,
                                    progressUpdate setProgress: @escaping (Float)->Void)
    {
        sharedMessageDataService.fetchAttachmentForAttachment(attachment, downloadTask: { (taskOne : URLSessionDownloadTask) -> Void in
            let totalValue = attachment.fileSize.floatValue
            setProgress(0.0)
            sharedAPIService.getSession().setDownloadTaskDidWriteDataBlock { session, taskTwo, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                guard taskOne == taskTwo else { return }
                var progressPercentage = Float(totalBytesWritten) / totalValue
                if progressPercentage >= 1.0 {
                    progressPercentage = 1.0
                }
                setProgress(progressPercentage)
            }
        }, completion: { _, url, error in
            setProgress(1.0)
            guard error == nil else {
                self.downloadFailed(error!)
                return
            }
            guard let localURL = attachment.localURL,
                FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil),
                let key_packet = attachment.keyPacket,
                let data: Data = Data(base64Encoded:key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) else
            {
                return
            }
            let fixedFilename = attachment.fileName.clear
            self.openLocalURL(localURL, keyPackage: data, fileName: fixedFilename, type: attachment.mimeType)
        })
    }
    
    private func openLocalURL(_ localURL: URL, keyPackage:Data, fileName:String, type: String) {
        self.quickLook(attachment: localURL, keyPackage: keyPackage, fileName: fileName, type: type)
    }
    
    
    private func openLocalURL(_ localURL: URL, fileName:String, type: String) {
        self.quickLook(file: localURL, fileName: fileName, type: type)
    }
    
    private func downloadFailed(_ error : NSError) {
//        self.delegate?.downloadFailed(error: error)
    }
}

extension MessageAttachmentsViewModel {
    func quickLook(attachment tempfile: URL, keyPackage: Data, fileName: String, type: String) {
        guard let data: Data = try? Data(contentsOf: tempfile) else {
            let alert = LocalString._cant_find_this_attachment.alertController()
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        do {
            tempFileUri = FileManager.default.attachmentDirectory.appendingPathComponent(fileName)
            guard let decryptData = try data.decryptAttachment(keyPackage, passphrase: sharedUserDataService.mailboxPassword!, privKeys: sharedUserDataService.addressPrivKeys),
                let _ = try? decryptData.write(to: tempFileUri!, options: [.atomic]) else
            {
                throw NSError()
            }
            
            //TODO:: the hard code string need change it to enum later
            guard (type == "application/vnd.apple.pkpass" || fileName.contains(check: ".pkpass") == true),
                let pkfile = try? Data(contentsOf: tempFileUri!) else
            {
                let previewQL = QuickViewViewController()
                previewQL.dataSource = self
                self.present(previewQL, animated: true, completion: nil)
                return
            }
            
            //TODO:: I add some change here for conflict but not sure if it is ok -- from Feng
            guard let pass = try? PKPass(data: pkfile),
                let vc = PKAddPassesViewController(pass: pass),
                // as of iOS 12.0 SDK, PKAddPassesViewController will not be initialized on iPads without any warning 🤯
                (vc as UIViewController?) != nil else
            {
                let previewQL = QuickViewViewController()
                previewQL.dataSource = self
                self.present(previewQL, animated: true, completion: nil)
                return
            }
            
            self.present(vc, animated: true, completion: nil)
        } catch _ {
            let alert = LocalString._cant_decrypt_this_attachment.alertController();
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func quickLook(file : URL, fileName:String, type: String) {
        tempFileUri = file
        //TODO:: the hard code string need change it to enum later
        guard (type == "application/vnd.apple.pkpass" || fileName.contains(check: ".pkpass") == true),
            let pkfile = try? Data(contentsOf: tempFileUri!) else
        {
            let previewQL = QuickViewViewController()
            previewQL.dataSource = self
            self.present(previewQL, animated: true, completion: nil)
            return
        }
        
        //TODO:: I add some change here for conflict but not sure if it is ok -- from Feng
        guard let pass = try? PKPass(data: pkfile),
            let vc = PKAddPassesViewController(pass: pass),
            // as of iOS 12.0 SDK, PKAddPassesViewController will not be initialized on iPads without any warning 🤯
            (vc as UIViewController?) != nil else
        {
            let previewQL = QuickViewViewController()
            previewQL.dataSource = self
            self.present(previewQL, animated: true, completion: nil)
            return
        }
        
        self.present(vc, animated: true, completion: nil)
    }
    
    private func present(_ vc: UIViewController, animated: Bool, completion: Bool?) {
        fatalError("mock cuz should be done by coordinator")
    }
}

extension MessageAttachmentsViewModel: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        //TODO :: fix here
        return tempFileUri! as QLPreviewItem
    }
}
