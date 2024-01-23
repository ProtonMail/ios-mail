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
// swiftlint:disable:next type_body_length
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
            "application/ogg",
            "application/x-cdf",
            "audio/aac",
            "audio/aiff",
            "audio/midi",
            "audio/mpeg",
            "audio/mpeg3",
            "audio/ogg",
            "audio/x-hx-aac-adts",
            "audio/x-m4a",
            "audio/x-midi",
            "audio/x-mpeg-3",
            "audio/x-realaudio",
            "audio/x-wav"
        ],
        .calendar: [
            "text/calendar"
        ],
        .code: [
            "application/atom+xml",
            "application/javascript",
            "application/json",
            "application/ld+json",
            "application/rss+xml",
            "application/vnd.google-earth.kml+xml",
            "application/x-csh",
            "application/x-httpd-php",
            "application/x-java-archive-diff",
            "application/x-java-jnlp-file",
            "application/x-perl",
            "application/x-sh",
            "application/x-tcl",
            "application/xhtml+xml",
            "application/xspf+xml",
            "text/css",
            "text/html",
            "text/javascript",
            "text/mathml",
            "text/vnd.wap.wml",
            "text/xml"
        ],
        .compressed: [
            "application/gzip",
            "application/java-archive",
            "application/mac-binhex40",
            "application/vnd.apple.installer+xml",
            "application/vnd.google-earth.kmz",
            "application/x-7z-compressed",
            "application/x-bzip",
            "application/x-bzip2",
            "application/x-freearc",
            "application/x-rar-compressed",
            "application/x-tar",
            "application/zip"
        ],
        .default: [
            "application/epub+zip",
            "application/octet-stream",
            "application/vnd.amazon.ebook",
            "application/vnd.mozilla.xul+xml",
            "application/x-cocoa",
            "application/x-makeself",
            "application/x-perl",
            "application/x-pilot",
            "application/x-redhat-package-manager",
            "application/x-sea",
            "application/x-shockwave-flash",
            "application/x-stuffit",
            "application/x-x509-ca-cert",
            "application/x-xpinstall",
            "text/vnd.sun.j2me.app-descriptor"
        ],
        .excel: [
            "application/excel",
            "application/vnd.ms-excel",
            "application/vnd.oasis.opendocument.spreadsheet",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "application/x-excel",
            "application/x-msexcel"
        ],
        .font: [
            "application/font-woff",
            "application/vnd.ms-fontobject",
            "font/otf",
            "font/ttf",
            "font/woff2"
        ],
        .image: [
            "application/postscript",
            "application/vnd.visio",
            "image/gif",
            "image/jpeg",
            "image/jpg",
            "image/png",
            "image/svg+xml",
            "image/tiff",
            "image/vnd.wap.wbmp",
            "image/webp",
            "image/x-icon",
            "image/x-jng",
            "image/x-ms-bmp",
            "video/x-mng"
        ],
        .key: [
            "application/pgp-keys"
        ],
        .keynote: [
            "application/vnd.apple.keynote",
            "application/x-iwork-keynote-sffkey"
        ],
        .numbers: [
            "application/vnd.apple.numbers",
            "application/x-iwork-numbers-sffnumbers"
        ],
        .pages: [
            "application/vnd.apple.pages",
            "application/x-iwork-pages-sffpages"
        ],
        .pdf: [
            "application/pdf"
        ],
        .powerpoint: [
            "application/mspowerpoint",
            "application/powerpoint",
            "application/vnd.ms-powerpoint",
            "application/vnd.oasis.opendocument.presentation",
            "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "application/x-mspowerpoint",
            "pot"
        ],
        .text: [
            "application/x-x509-ca-cert",
            "text/csv",
            "text/plain",
            "text/x-component"
        ],
        .video: [
            "application/vnd.apple.mpegurl",
            "application/vnd.wap.wmlc",
            "image/mov",
            "video/3gpp",
            "video/avi",
            "video/mp2t",
            "video/mp4",
            "video/mpeg",
            "video/quicktime",
            "video/webm",
            "video/x-flv",
            "video/x-m4v",
            "video/x-matroska",
            "video/x-ms-asf",
            "video/x-ms-wmv",
            "video/x-msvideo",
            "video/x-quicktime"
        ],
        .word: [
            "application/doc",
            "application/ms-doc",
            "application/msword",
            "application/rtf",
            "application/vnd.oasis.opendocument.text",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/x-abiword"
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
