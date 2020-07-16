//
//  AttachmentProvider.swift
//  ProtonMail - Created on 28/06/2018.
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
    
            self.updateAttachments()
            self.delegate?.attachments(self, didPickedAttachment: attachment)
        }
    }
}

