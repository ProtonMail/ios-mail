// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import UIKit
import XCTest
@testable import ProtonMail

final class MIMETypeTests: XCTestCase {
    
    private struct Pair {
        let mimes: [String]
        let type: MIMEType
        let icon: UIImage
        let bigIcon: UIImage
    }

    func testJPG() {
        let pairs = [
            Pair(mimes: MIMEType.jpgMIME,
                 type: .jpg,
                 icon: UIImage(named: "mail_attachment-jpeg")!,
                 bigIcon: UIImage(named: "mail_attachment_file_image")!),
            Pair(mimes: [MIMEType.pngMIME],
                 type: .png,
                 icon: UIImage(named: "mail_attachment-jpeg")!,
                 bigIcon: UIImage(named: "mail_attachment_file_image")!),
            Pair(mimes: [MIMEType.zipMIME],
                 type: .zip,
                 icon: UIImage(named: "mail_attachment-zip")!,
                 bigIcon: UIImage(named: "mail_attachment_file_zip")!),
            Pair(mimes: [MIMEType.pdfMIME],
                 type: .pdf,
                 icon: UIImage(named: "mail_attachment-pdf")!,
                 bigIcon: UIImage(named: "mail_attachment_file_pdf")!),
            Pair(mimes: [MIMEType.txtMIME],
                 type: .txt,
                 icon: UIImage(named: "mail_attachment-txt")!,
                 bigIcon: UIImage(named: "mail_attachment_file_general")!),
            Pair(mimes: [MIMEType.htmlMIME],
                 type: .html,
                 icon: UIImage(named: "mail_attachment_general")!,
                 bigIcon: UIImage(named: "mail_attachment_file_general")!),
            Pair(mimes: [MIMEType.multipartMixedMIME],
                 type: .mutipartMixed,
                 icon: UIImage(named: "mail_attachment_general")!,
                 bigIcon: UIImage(named: "mail_attachment_file_general")!),
            Pair(mimes: MIMEType.msWordMIME,
                 type: .doc,
                 icon: UIImage(named: "mail_attachment-doc")!,
                 bigIcon: UIImage(named: "mail_attachment_file_doc")!),
            Pair(mimes: MIMEType.msExcelMIME,
                 type: .xls,
                 icon: UIImage(named: "mail_attachment-xls")!,
                 bigIcon: UIImage(named: "mail_attachment_file_xls")!),
            Pair(mimes: MIMEType.msPptMIME,
                 type: .ppt,
                 icon: UIImage(named: "mail_attachment-ppt")!,
                 bigIcon: UIImage(named: "mail_attachment_file_ppt")!),
            Pair(mimes: MIMEType.videoMIME,
                 type: .video,
                 icon: UIImage(named: "mail_attachment_video")!,
                 bigIcon: UIImage(named: "mail_attachment_file_video")!),
            Pair(mimes: MIMEType.audioMIME,
                 type: .audio,
                 icon: UIImage(named: "mail_attachment_audio")!,
                 bigIcon: UIImage(named: "mail_attachment_file_audio")!),
            Pair(mimes: MIMEType.epubMIME,
                 type: .epub,
                 icon: UIImage(named: "mail_attachment_general")!,
                 bigIcon: UIImage(named: "mail_attachment_file_general")!),
            Pair(mimes: MIMEType.icsMIME,
                 type: .ics,
                 icon: UIImage(named: "mail_attachment_general")!,
                 bigIcon: UIImage(named: "mail_attachment_file_general")!),
            Pair(mimes: ["fjlsdkfjsdkf"],
                 type: .unknownFile,
                 icon: UIImage(named: "mail_attachment_general")!,
                 bigIcon: UIImage(named: "mail_attachment_file_general")!)
        ]
        for pair in pairs {
            for mime in pair.mimes {
                let type = MIMEType(rawValue: mime)
                XCTAssertEqual(type, pair.type)
                XCTAssertEqual(type.icon, pair.icon)
                XCTAssertEqual(type.bigIcon, pair.bigIcon)
            }
        }
    }

}
