//
//  AttachmentListViewModel.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

class AttachmentListViewModel {

    enum AttachmentSection: Int {
        case normal = 1, inline

        var actionTitle: String {
            switch self {
            case .normal:
                return LocalString._normal_attachments
            case .inline:
                return LocalString._inline_attachments
            }
        }
    }

    private enum Errors: Error {
        case cantFindAttachment
        case cantDecryptAttachment

        var localizedDescription: String {
            switch self {
            case .cantFindAttachment:
                return LocalString._cant_find_this_attachment
            case .cantDecryptAttachment:
                return LocalString._cant_decrypt_this_attachment
            }
        }
    }

    let attachmentSections: [AttachmentSection] = [.normal, .inline]
    private(set) var inlineAttachments: [AttachmentInfo] = []
    private(set) var normalAttachments: [AttachmentInfo] = []
    private(set) var inlineCIDS: [String]?
    private var downloadingTask: [String: URLSessionDownloadTask] = [:]
    let user: UserManager

    var attachmentCount: Int {
        return inlineAttachments.count + normalAttachments.count
    }
    /// (attachmentID, tempClearFileURL)
    var attachmentDownloaded: ((String, URL) -> Void)?

    init(attachments: [AttachmentInfo], user: UserManager, inlineCIDS: [String]?) {
        self.user = user
        self.inlineCIDS = inlineCIDS
        self.inlineAttachments = attachments.inlineAttachments(inlineCIDS: inlineCIDS)
        self.normalAttachments = attachments.normalAttachments(inlineCIDS: inlineCIDS)
    }

    func open(attachmentInfo: AttachmentInfo,
              showPreviewer: @escaping () -> Void,
              failed: @escaping (NSError) -> Void) {
        guard let attachment = attachmentInfo.att else {
            // two attachment types. inline and normal att in core data
            // inline att doesn't need to decrypt and it saved in cache temporarily when decrypting the message
            // in this case just try to open it directly
            if let url = attachmentInfo.localUrl,
               let id = attachmentInfo.att?.attachmentID {
                self.attachmentDownloaded?(id, url)
            }
            return
        }

        let decryptor: (Attachment, URL) -> Void = { [weak self] in
            guard let self = self else { return }
            do {
                try self.decrypt($0, encryptedFileURL: $1)
            } catch {
                failed(error as NSError)
            }
        }

        showPreviewer()
        if self.downloadingTask[attachment.attachmentID] != nil {
            return
        }

        guard attachmentInfo.isDownloaded,
              let localURL = attachmentInfo.localUrl else {
            if let attachmentToDownload = attachmentInfo.att {
                self.downloadAttachment(attachmentToDownload,
                                        success: decryptor,
                                        fail: failed)
            }
            return
        }

        guard FileManager.default.fileExists(atPath: localURL.path,
                                             isDirectory: nil) else {
            if let context = attachment.managedObjectContext {
                context.performAndWait {
                    attachment.localURL = nil
                    _ = context.saveUpstreamIfNeeded()
                }
            }
            self.downloadAttachment(attachment,
                                    success: decryptor,
                                    fail: failed)
            return
        }

        decryptor(attachment, localURL)
    }

    func isEmpty(section: AttachmentSection) -> Bool {
        let sectionItems = section == .inline ? inlineAttachments : normalAttachments
        return sectionItems.isEmpty
    }

    func isAttachmentDownloading(id: String) -> Bool {
        return self.downloadingTask[id] != nil
    }

    func getAttachment(id: String) -> (AttachmentInfo, IndexPath)? {
        if let index = normalAttachments.firstIndex(where: { $0.att?.attachmentID == id }) {
            let attachment = normalAttachments[index]
            let path = IndexPath(row: index, section: 0)
            return (attachment, path)
        } else if let index = inlineAttachments.firstIndex(where: { $0.att?.attachmentID == id }) {
            let attachment = inlineAttachments[index]
            let path = IndexPath(row: index, section: 1)
            return (attachment, path)
        }
        return nil
    }

    private func downloadAttachment(_ attachment: Attachment,
                                    success: @escaping ((Attachment, URL) throws -> Void),
                                    fail: @escaping (NSError) -> Void) {
        let service = user.messageService
        service.fetchAttachmentForAttachment(attachment,
                                             downloadTask: { [weak self] task in
            self?.downloadingTask[attachment.attachmentID] = task
        }, completion: { [weak self] _, url, error in
            self?.downloadingTask.removeValue(forKey: attachment.attachmentID)
            if let error = error {
                fail(error)
                return
            } else if let url = url {
                do {
                    try success(attachment, url)
                } catch {
                    fail(error as NSError)
                }
            }
        })
    }

    private func decrypt(_ attachment: Attachment,
                         encryptedFileURL: URL) throws {
        guard let keyPacket = attachment.keyPacket,
            let keyPackage: Data = Data(base64Encoded: keyPacket,
                                        options: NSData.Base64DecodingOptions(rawValue: 0)) else {
            assert(false, "what can cause this?")
            return
        }

        guard let data: Data = try? Data(contentsOf: encryptedFileURL) else {
            throw Errors.cantFindAttachment
        }

        // No way we should store this file cleartext any longer than absolutely needed
        let tempClearFileURL =
            FileManager.default.temporaryDirectoryUrl.appendingPathComponent(attachment.fileName.clear)

        guard let decryptData =
            user.newSchema ?
                try data.decryptAttachment(keyPackage: keyPackage,
                                           userKeys: user.userPrivateKeys,
                                           passphrase: user.mailboxPassword,
                                           keys: user.addressKeys) :
                try data.decryptAttachment(keyPackage,
                                           passphrase: user.mailboxPassword,
                                           privKeys: user.addressPrivateKeys),
            (try? decryptData.write(to: tempClearFileURL, options: [.atomic])) != nil else {
            throw Errors.cantDecryptAttachment
        }
        self.attachmentDownloaded?(attachment.attachmentID, tempClearFileURL)
    }

}

private extension AttachmentInfo {

    func isInline(inlineCIDS: [String]?) -> Bool {
        guard let attachment = att else { return false }
        if let inlineCIDS = inlineCIDS {
            guard let contentID = attachment.contentID() else { return false }
            return inlineCIDS.contains(contentID)
        }
        return attachment.inline()
    }

}

private extension Collection where Element == AttachmentInfo {

    func inlineAttachments(inlineCIDS: [String]?) -> [Element] {
        filter { $0.isInline(inlineCIDS: inlineCIDS) }
    }

    func normalAttachments(inlineCIDS: [String]?) -> [Element] {
        filter { !$0.isInline(inlineCIDS: inlineCIDS) }
    }

}
