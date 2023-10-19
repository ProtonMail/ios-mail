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
    case calendar
    case code
    case compressed
    case `default`
    case excel
    case font
    case image
    case key
    case keynote
    case numbers
    case pages
    case pdf
    case powerpoint
    case text
    case video
    case word

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
        .calendar: [],
        .code: [],
        .compressed: [
            "application/zip"
        ],
        .excel: [
            "application/excel",
            "application/vnd.ms-excel",
            "application/x-excel",
            "application/x-msexcel",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        ],
        .font: [],
        .image: [
            "image/jpg",
            "image/jpeg",
            "image/png"
        ],
        .key: [],
        .keynote: [],
        .numbers: [],
        .pages: [],
        .pdf: [
            "application/pdf"
        ],
        .powerpoint: [
            "application/mspowerpoint",
            "application/powerpoint",
            "application/vnd.ms-powerpoint",
            "application/x-mspowerpoint",
            "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        ],
        .text: [
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
        .word: [
            "application/doc",
            "application/ms-doc",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        ]
    ]

    init(mimeType: String) {
        self = Self.mimeTypeMap.first { $1.contains(mimeType) }?.key ?? .default
    }

    /// Icon for composer
    var icon: UIImage {
        let asset: ImageAsset
        switch self {
        case .audio:
            asset = Asset.icFileTypeIconAudio
        case .calendar:
            asset = Asset.icFileTypeIconCalendar
        case .code:
            asset = Asset.icFileTypeIconCode
        case .compressed:
            asset = Asset.icFileTypeIconCompressed
        case .default:
            asset = Asset.icFileTypeIconDefault
        case .excel:
            asset = Asset.icFileTypeIconExcel
        case .font:
            asset = Asset.icFileTypeIconFont
        case .image:
            asset = Asset.icFileTypeIconImage
        case .key:
            asset = Asset.icFileTypeIconKey
        case .keynote:
            asset = Asset.icFileTypeIconKeynote
        case .numbers:
            asset = Asset.icFileTypeIconNumbers
        case .pages:
            asset = Asset.icFileTypeIconPages
        case .pdf:
            asset = Asset.icFileTypeIconPdf
        case .powerpoint:
            asset = Asset.icFileTypeIconPowerpoint
        case .text:
            asset = Asset.icFileTypeIconText
        case .video:
            asset = Asset.icFileTypeIconVideo
        case .word:
            asset = Asset.icFileTypeIconWord
        }
        return asset.image
    }

    /// Icon for message detail
    var bigIcon: UIImage {
        let asset: ImageAsset
        switch self {
        case .audio:
            asset = Asset.icFileTypeAudio
        case .calendar:
            asset = Asset.icFileTypeCalendar
        case .code:
            asset = Asset.icFileTypeCode
        case .compressed:
            asset = Asset.icFileTypeCompressed
        case .default:
            asset = Asset.icFileTypeDefault
        case .excel:
            asset = Asset.icFileTypeExcel
        case .font:
            asset = Asset.icFileTypeFont
        case .image:
            asset = Asset.icFileTypeImage
        case .key:
            asset = Asset.icFileTypeKey
        case .keynote:
            asset = Asset.icFileTypeKeynote
        case .numbers:
            asset = Asset.icFileTypeNumbers
        case .pages:
            asset = Asset.icFileTypePages
        case .pdf:
            asset = Asset.icFileTypePdf
        case .powerpoint:
            asset = Asset.icFileTypePowerpoint
        case .text:
            asset = Asset.icFileTypeText
        case .video:
            asset = Asset.icFileTypeVideo
        case .word:
            asset = Asset.icFileTypeWord
        }
        return asset.image
    }
}
