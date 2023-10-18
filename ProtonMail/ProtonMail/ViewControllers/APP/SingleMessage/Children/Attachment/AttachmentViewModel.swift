//
//  AttachmentViewModel.swift
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

final class AttachmentViewModel {
    private(set) var attachments: Set<AttachmentInfo> = [] {
        didSet {
            reloadView?()
        }
    }
    var reloadView: (() -> Void)?

    var numberOfAttachments: Int {
        if isInlineAttachmentNoLoaded {
            return attachmentCount
        } else {
            return attachments.isEmpty ? attachmentCount : attachments.count
        }
    }
    private var attachmentCount: Int = 0
    private var isInlineAttachmentNoLoaded = true

    var totalSizeOfAllAttachments: Int {
        let attachmentSizes = attachments.map({ $0.size })
        let totalSize = attachmentSizes.reduce(0) { result, value -> Int in
            return result + value
        }
        return totalSize
    }

    func attachmentHasChanged(
        attachmentCount: Int,
        nonInlineAttachments: [AttachmentInfo],
        inlineAttachments: [AttachmentEntity]?,
        mimeAttachments: [MimeAttachment]
    ) {
        self.attachmentCount = attachmentCount
        isInlineAttachmentNoLoaded = inlineAttachments == nil
        var files: [AttachmentInfo] = nonInlineAttachments
        files.append(contentsOf: mimeAttachments)
        self.attachments = Set(files)
    }
}
