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
    private let realAttachmentFlagProvider: RealAttachmentsFlagProvider
    private(set) var attachments: Set<AttachmentInfo> = [] {
        didSet {
            reloadView?()
        }
    }
    var reloadView: (() -> Void)?

    var numberOfAttachments: Int {
        return attachments.count
    }

    var totalSizeOfAllAttachments: Int {
        let attachmentSizes = attachments.map({ $0.size })
        let totalSize = attachmentSizes.reduce(0) { result, value -> Int in
            return result + value
        }
        return totalSize
    }

    init (realAttachmentFlagProvider: RealAttachmentsFlagProvider = userCachedStatus) {
        self.realAttachmentFlagProvider = realAttachmentFlagProvider
    }

    func attachmentHasChanged(
        attachments: [AttachmentInfo],
        inlines: [AttachmentInfo],
        mimeAttachments: [MimeAttachment]
    ) {
        var files: [AttachmentInfo] = attachments
        if !realAttachmentFlagProvider.realAttachments {
            files.append(contentsOf: inlines)
        }
        files.append(contentsOf: mimeAttachments)
        self.attachments = Set(files)
    }
}
