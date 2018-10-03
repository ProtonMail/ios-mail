//
//  AttachmentProvider.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 28/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

protocol AttachmentProvider {
    var alertAction: UIAlertAction { get }
    var controller: AttachmentController! { get }
}


protocol AttachmentController: class {
    func present(_ controller: UIViewController, animated: Bool, completion: (()->Void)?)
    func error(_ description: String)
    func finish(_ fileData: FileData)
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
    
    func finish(_ fileData: FileData) {
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
            guard let attachment = fileData.contents.toAttachment(self.message, fileName: fileData.name, type: fileData.ext) else {
                PMLog.D(" Error during copying size incorrect")
                self.error(LocalString._cant_copy_the_file)
                return
            }
    
            self.attachments.append(attachment)
            self.delegate?.attachments(self, didPickedAttachment: attachment)
        }
    }
}

