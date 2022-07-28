//
//  MIMEType.swift
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

import UIKit

// The purpose of this type is to map incoming MIME types to icons
enum AttachmentType: CaseIterable, Equatable {
    case audio
    case doc
    case general
    case image
    case pdf
    case ppt
    case txt
    case video
    case xls
    case zip

    static let mimeTypeMap: [AttachmentType: [String]] = [
        .audio: [
            "audio/x-m4a",
            "audio/mpeg3",
            "audio/x-mpeg-3",
            "video/mpeg",
            "video/x-mpeg",
            "audio/mpeg",
            "audio/aac",
            "audio/x-hx-aac-adts"
        ],
        .doc: [
            "application/doc",
            "application/ms-doc",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        ],
        .image: [
            "image/jpg",
            "image/jpeg",
            "image/png"
        ],
        .pdf: [
            "application/pdf"
        ],
        .ppt: [
            "application/mspowerpoint",
            "application/powerpoint",
            "application/vnd.ms-powerpoint",
            "application/x-mspowerpoint",
            "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        ],
        .txt: [
            "text/plain"
        ],
        .video: [
            "video/quicktime",
            "video/x-quicktime",
            "image/mov",
            "audio/aiff",
            "audio/x-midi",
            "audio/x-wav",
            "video/avi",
            "video/mp4",
            "video/x-matroska"
        ],
        .xls: [
            "application/excel",
            "application/vnd.ms-excel",
            "application/x-excel",
            "application/x-msexcel",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        ],
        .zip: [
            "application/zip"
        ]
    ]

    init(mimeType: String) {
        self = Self.mimeTypeMap.first { $1.contains(mimeType) }?.key ?? .general
    }

    /// Icon for composer
    // swiftlint:disable object_literal
    var icon: UIImage {
        let asset: ImageAsset

        switch self {
        case .image:
            asset = Asset.mailAttachmentJpeg
        case .zip:
            asset = Asset.mailAttachmentZip
        case .pdf:
            asset = Asset.mailAttachmentPdf
        case .txt:
            asset = Asset.mailAttachmentTxt
        case .doc:
            asset = Asset.mailAttachmentDoc
        case .xls:
            asset = Asset.mailAttachmentXls
        case .ppt:
            asset = Asset.mailAttachmentPpt
        case .video:
            asset = Asset.mailAttachmentVideo
        case .audio:
            asset = Asset.mailAttachmentAudio
        case .general:
            asset = Asset.mailAttachmentGeneral
        }

        return asset.image
    }

    /// Icon for message detail
    var bigIcon: UIImage {
        let asset: ImageAsset

        switch self {
        case .image:
            asset = Asset.mailAttachmentJpeg
        case .zip:
            asset = Asset.mailAttachmentFileZip
        case .pdf:
            asset = Asset.mailAttachmentPdf
        case .txt:
            // There is no icon for txt, use general temporary
            return Self.general.bigIcon
        case .doc:
            asset = Asset.mailAttachmentFileDoc
        case .xls:
            asset = Asset.mailAttachmentFileXls
        case .ppt:
            asset = Asset.mailAttachmentFilePpt
        case .video:
            asset = Asset.mailAttachmentFileVideo
        case .audio:
            asset = Asset.mailAttachmentFileAudio
        case .general:
            asset = Asset.mailAttachmentFileGeneral
        }

        return asset.image
    }
    // swiftlint:enable object_literal
}
