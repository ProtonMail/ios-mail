//
//  AttachmentListViewModel.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

final class AttachmentListViewModel {
    typealias Dependencies = HasUserManager & HasCoreDataContextProviderProtocol & HasFetchAttachmentUseCase

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

    let attachmentSections: [AttachmentSection] = [.normal, .inline]
    private(set) var inlineAttachments: [AttachmentInfo] = []
    private(set) var normalAttachments: [AttachmentInfo] = []
    private var downloadingTask: [AttachmentID: URLSessionDownloadTask] = [:]

    /// (attachmentID, tempClearFileURL)
    var attachmentDownloaded: ((AttachmentID, URL) -> Void)?
    private let dependencies: Dependencies

    init(attachments: [AttachmentInfo], inlineCIDS: [String]?, dependencies: Dependencies) {
        self.inlineAttachments = attachments.inlineAttachments(inlineCIDS: inlineCIDS)
        self.normalAttachments = attachments.normalAttachments(inlineCIDS: inlineCIDS)
        self.dependencies = dependencies
    }

    func open(attachmentInfo: AttachmentInfo, showPreviewer: () -> Void, failed: @escaping (NSError) -> Void) {
        guard !isAttachmentDownloading(id: attachmentInfo.id) else {
            return
        }

        guard let attachment = self.getAttachment(from: attachmentInfo) else {
            // two attachment types. inline and normal att in core data
            // inline att doesn't need to decrypt and it saved in cache temporarily when decrypting the message
            // in this case just try to open it directly
            if let url = attachmentInfo.localUrl {
                self.attachmentDownloaded?(attachmentInfo.id, url)
            }
            return
        }

        showPreviewer()

        let userKeys = dependencies.user.toUserKeys()
        dependencies.fetchAttachment.execute(params: .init(
            attachmentID: attachment.id,
            attachmentKeyPacket: attachment.keyPacket,
            userKeys: userKeys
        )) { result in
            do {
                let attachmentFile = try result.get()
                let fileData = attachmentFile.data
                let fileName = attachment.name.cleaningFilename()
                let unencryptedFileUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

                try fileData.write(to: unencryptedFileUrl, options: [.atomic])
                DispatchQueue.main.async { [weak self] in
                    self?.attachmentDownloaded?(attachment.id, unencryptedFileUrl)
                }
            } catch {
                failed(error as NSError)
            }
        }
    }

    func isEmpty(section: AttachmentSection) -> Bool {
        let sectionItems = section == .inline ? inlineAttachments : normalAttachments
        return sectionItems.isEmpty
    }

    func isAttachmentDownloading(id: AttachmentID) -> Bool {
        downloadingTask.keys.contains(id)
    }

    func getAttachment(id: AttachmentID) -> (AttachmentInfo, IndexPath)? {
        if let index = normalAttachments.firstIndex(where: { $0.id == id }) {
            let attachment = normalAttachments[index]
            let path = IndexPath(row: index, section: 0)
            return (attachment, path)
        } else if let index = inlineAttachments.firstIndex(where: { $0.id == id }) {
            let attachment = inlineAttachments[index]
            let path = IndexPath(row: index, section: 1)
            return (attachment, path)
        }
        return nil
    }

    private func getAttachment(from info: AttachmentInfo) -> AttachmentEntity? {
        var result: AttachmentEntity?

        guard let objectID = info.objectID?.rawValue else {
            return nil
        }

        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            if let attachment = context.object(with: objectID) as? Attachment {
                result = AttachmentEntity(attachment)
            }
        }

        return result
    }
}

private extension AttachmentInfo {

    func isInline(inlineCIDS: [String]?) -> Bool {
        if let mime = self as? MimeAttachment {
            return mime.isInline
        }
        guard let contentID = self.contentID else { return false }
        if let inlineCIDS = inlineCIDS {
            return inlineCIDS.contains(contentID)
        }
        return self.isInline
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
