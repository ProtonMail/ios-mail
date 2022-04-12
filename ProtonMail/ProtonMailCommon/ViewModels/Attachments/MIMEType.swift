//
//  MIMEType.swift
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

import UIKit

enum MIMEType {
    case jpg
    case png
    case zip
    case pdf
    case txt
    case doc
    case xls
    case ppt
    case video
    case audio
    case epub
    case ics
    case unknownFile

    static let msWordMIME = ["application/doc",
                             "application/ms-doc",
                             "application/msword",
                             "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]

    static let msExcelMIME = ["application/excel",
                              "application/vnd.ms-excel",
                              "application/x-excel",
                              "application/x-msexcel",
                              "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]

    static let msPptMIME = ["application/mspowerpoint",
                            "application/powerpoint",
                            "application/vnd.ms-powerpoint",
                            "application/x-mspowerpoint",
                            "application/vnd.openxmlformats-officedocument.presentationml.presentation"]

    static let videoMIME = ["video/quicktime",
                            "video/x-quicktime",
                            "image/mov",
                            "audio/aiff",
                            "audio/x-midi",
                            "audio/x-wav",
                            "video/avi",
                            "video/mp4",
                            "video/x-matroska"]

    static let audioMIME = ["audio/x-m4a",
                            "audio/mpeg3",
                            "audio/x-mpeg-3",
                            "video/mpeg",
                            "video/x-mpeg",
                            "audio/mpeg",
                            "audio/aac",
                            "audio/x-hx-aac-adts"]

    static let epubMIME = ["application/epub+zip"]
    static let icsMIME = ["text/calendar"]

    // swiftlint:disable cyclomatic_complexity
    init(rawValue: String) {
        if rawValue == "image/jpeg" || rawValue == "image/jpg" {
            self = .jpg
        } else if rawValue == "image/png" {
            self = .png
        } else if rawValue == "application/zip" {
            self = .zip
        } else if rawValue == "application/pdf" {
            self = .pdf
        } else if rawValue == "text/plain" {
            self = .txt
        } else if MIMEType.msWordMIME.contains(rawValue) {
            self = .doc
        } else if MIMEType.msExcelMIME.contains(rawValue) {
            self = .xls
        } else if MIMEType.msPptMIME.contains(rawValue) {
            self = .ppt
        } else if MIMEType.videoMIME.contains(rawValue) {
            self = .video
        } else if MIMEType.audioMIME.contains(rawValue) {
            self = .audio
        } else if MIMEType.epubMIME.contains(rawValue) {
            self = .epub
        } else if MIMEType.icsMIME.contains(rawValue) {
            self = .ics
        } else {
            self = .unknownFile
        }
    }
    // swiftlint:enable cyclomatic_complexity

    /// Icon for composer
    // swiftlint:disable object_literal
    var icon: UIImage? {
        switch self {
        case .jpg:
            return UIImage(named: "mail_attachment-jpeg")
        case .png:
            return UIImage(named: "mail_attachment-jpeg")
        case .zip:
            return UIImage(named: "mail_attachment-zip")
        case .pdf:
            return UIImage(named: "mail_attachment-pdf")
        case .txt:
            return UIImage(named: "mail_attachment-txt")
        case .doc:
            return UIImage(named: "mail_attachment-doc")
        case .xls:
            return UIImage(named: "mail_attachment-xls")
        case .ppt:
            return UIImage(named: "mail_attachment-ppt")
        case .video:
            return UIImage(named: "mail_attachment_video")
        case .audio:
            return UIImage(named: "mail_attachment_audio")
        case .epub:
            return UIImage(named: "mail_attachment_general")
        case .ics:
            return UIImage(named: "mail_attachment_general")
        default:
            return UIImage(named: "mail_attachment_general")
        }
    }

    /// Icon for message detail
    var bigIcon: UIImage? {
        switch self {
        case .jpg:
            return UIImage(named: "mail_attachment_file_image")
        case .png:
            return UIImage(named: "mail_attachment_file_image")
        case .zip:
            return UIImage(named: "mail_attachment_file_zip")
        case .pdf:
            return UIImage(named: "mail_attachment_file_pdf")
        case .txt:
            // There is no icon for txt, use general temporary
            return UIImage(named: "mail_attachment_file_general")
        case .doc:
            return UIImage(named: "mail_attachment_file_doc")
        case .xls:
            return UIImage(named: "mail_attachment_file_xls")
        case .ppt:
            return UIImage(named: "mail_attachment_file_ppt")
        case .video:
            return UIImage(named: "mail_attachment_file_video")
        case .audio:
            return UIImage(named: "mail_attachment_file_audio")
        case .epub:
            return UIImage(named: "mail_attachment_file_general")
        case .ics:
            return UIImage(named: "mail_attachment_file_general")
        default:
            return UIImage(named: "mail_attachment_file_general")
        }
    }
    // swiftlint:enable object_literal
}
