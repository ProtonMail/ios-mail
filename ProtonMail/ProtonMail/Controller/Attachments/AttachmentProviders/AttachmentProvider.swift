//
//  AttachmentProvider.swift
//  ProtonMail - Created on 28/06/2018.
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

protocol AttachmentProvider {
    var alertAction: UIAlertAction { get }
    var controller: AttachmentController! { get }
}


protocol AttachmentController: class {
    func present(_ controller: UIViewController, animated: Bool, completion: (()->Void)?)
    func error(_ description: String)
    func fileSuccessfullyImported(as fileData: FileData)
    
    @available(iOS, deprecated: 11.0, message: "ios 10 and below required sourceView&sourceRect or barButtonItem")
    var barItem : UIBarButtonItem? {get}
}

extension AttachmentsTableViewController {
    func error(_ description: String) {
        self.showErrorAlert(description)
        self.delegate?.attachments(self, error: description)
    }
    
    func sizeError(_ size: Int) {
        self.showSizeErrorAlert(size)
        self.delegate?.attachments(self, didReachedSizeLimitation: size)
    }
    
    func fileSuccessfullyImported(as fileData: FileData) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            let size = fileData.contents.dataSize
            guard size < (self.kDefaultAttachmentFileSize - self.currentAttachmentSize) else {
                self.sizeError(0)
                PMLog.D(" Size too big Orig: \(size) -- Limit: \(self.kDefaultAttachmentFileSize)")
                return
            }
        
            guard self.message.managedObjectContext != nil else {
                PMLog.D(" Error during copying size incorrect")
                self.error(LocalString._system_cant_copy_the_file)
                return
            }
            let stripMetadata = userCachedStatus.metadataStripping == .stripMetadata
            guard let attachment = fileData.contents.toAttachment(self.message, fileName: fileData.name, type: fileData.ext, stripMetadata: stripMetadata) else {
                PMLog.D(" Error during copying size incorrect")
                self.error(LocalString._cant_copy_the_file)
                return
            }
    
            self.attachments.append(attachment)
            self.delegate?.attachments(self, didPickedAttachment: attachment)
        }
    }
}

