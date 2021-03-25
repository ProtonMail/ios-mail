//
//  MessageAttachmentsViewModel.swift
//  ProtonMail - Created on 15/03/2019.
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
import PMCommon

class MessageAttachmentsViewModel: NSObject {
    @objc internal dynamic var attachments: [AttachmentInfo] = []
    @objc internal dynamic var contentsHeight: CGFloat = 0.0
    private var observation: NSKeyValueObservation!
    private(set) var parentViewModel: MessageViewModel
    
    init(parentViewModel: MessageViewModel) {
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

        let decryptor: (Attachment, URL)->Void = { [weak self] in
            guard let self = self else { return }
            self.attachments = self.parentViewModel.attachments // this will reload tableView and therefore update download icons
            try? self.decrypt($0, encryptedFileURL: $1, clearfile: opener)
        }
        
        guard attachmentInfo.isDownloaded, let localURL = attachmentInfo.localUrl else {
            self.downloadAttachment(attachmentInfo.att!, progressUpdate: pregressUpdate, success: decryptor, fail: fail)
            return
        }
        
        guard FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) else {
            if let context = attachment.managedObjectContext {
                context.performAndWait {
                    attachment.localURL = nil
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D(" error: \(String(describing: error))")
                    }
                }
            }
            
            self.downloadAttachment(attachment, progressUpdate: pregressUpdate, success: decryptor, fail: fail)
            return
        }
        
        decryptor(attachment, localURL)
    }
    
    private func downloadAttachment(_ attachment: Attachment,
                                    progressUpdate setProgress: @escaping (Float)->Void,
                                    success: @escaping ((Attachment, URL) throws ->Void),
                                    fail: @escaping (NSError)->Void)
    {
        let totalValue = attachment.fileSize.floatValue
        let user = self.parentViewModel.user
        user.messageService.fetchAttachmentForAttachment(attachment, downloadTask: { taskOne in
            setProgress(0.0)
            user.apiService.getSession()?.setDownloadTaskDidWriteDataBlock { _, taskTwo, _, totalBytesWritten, _ in
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
            do {
                try success(attachment, url)
            } catch let error {
                fail(error as NSError)
            }
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
        
        let user = self.parentViewModel.user
        guard let decryptData =
            user.newSchema ?
                try data.decryptAttachment(keyPackage: keyPackage,
                                           userKeys: user.userPrivateKeys,
                                           passphrase: user.mailboxPassword,
                                           keys: user.addressKeys) :
                try data.decryptAttachment(keyPackage,
                                           passphrase: user.mailboxPassword,
                                           privKeys: user.addressPrivateKeys), //DONE
            let _ = try? decryptData.write(to: tempClearFileURL, options: [.atomic]) else
        {
            throw Errors._cant_decrypt_this_attachment
        }
        
        clearfile(tempClearFileURL)
    }
}
