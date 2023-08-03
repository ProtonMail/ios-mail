// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import XCTest

@testable import ProtonMail

final class HeaderTests: XCTestCase {
    func testFilenames_encodedInQuotedPrintable_areDecodedCorrectly() throws {
        let headersString = "Content-Disposition: attachment; filename=\"=?utf-8?Q?=E4=BF=A1=E7=94=A8=E5=8D=A1=E9=9B=BB=E5=AD=90=E5=B8=B3=E5=96=AE=E6=B6=88?= =?utf-8?Q?=E8=B2=BB=E6=98=8E=E7=B4=B0_1120?=7.pdf\"; name=\"=?utf-8?Q?=E4=BF=A1=E7=94=A8=E5=8D=A1=E9=9B=BB=E5=AD=90=E5=B8=B3=E5=96=AE=E6=B6=88?= =?utf-8?Q?=E8=B2=BB=E6=98=8E=E7=B4=B0_1120?=7.pdf\"\r\nContent-Transfer-Encoding: base64\r\nContent-Type: application/pdf; filename=\"=?utf-8?Q?=E4=BF=A1=E7=94=A8=E5=8D=A1=E9=9B=BB=E5=AD=90=E5=B8=B3=E5=96=AE=E6=B6=88?= =?utf-8?Q?=E8=B2=BB=E6=98=8E=E7=B4=B0_1120?=7.pdf\"; name=\"=?utf-8?Q?=E4=BF=A1=E7=94=A8=E5=8D=A1=E9=9B=BB=E5=AD=90=E5=B8=B3=E5=96=AE=E6=B6=88?= =?utf-8?Q?=E8=B2=BB=E6=98=8E=E7=B4=B0_1120?=7.pdf\"\r\n"
        let headers = [Header](string: headersString)

        let contentDisposition = try XCTUnwrap(headers[.contentDisposition])
        XCTAssertEqual(contentDisposition.keyValues["filename"], "信用卡電子帳單消 費明細_11207.pdf")
        XCTAssertEqual(contentDisposition.keyValues["name"], "信用卡電子帳單消 費明細_11207.pdf")

        let contentTransferEncoding = try XCTUnwrap(headers[.contentTransferEncoding])
        XCTAssertEqual(contentTransferEncoding.keyValues, [:])

        let contentType = try XCTUnwrap(headers[.contentType])
        XCTAssertEqual(contentType.keyValues["filename"], "信用卡電子帳單消 費明細_11207.pdf")
        XCTAssertEqual(contentType.keyValues["name"], "信用卡電子帳單消 費明細_11207.pdf")
    }

    func testFilenames_encodedInBase64_areDecodedCorrectly() throws {
        let headersString = "Content-Disposition: attachment; filename=\"=?UTF-8?B?Zm9v?=.zip"
        let headers = [Header](string: headersString)

        let contentDisposition = try XCTUnwrap(headers[.contentDisposition])
        XCTAssertEqual(contentDisposition.keyValues["filename"], "foo.zip")
    }

    func testFilenames_encodedIncorrectly_areSkipped() throws {
        let headersString = "Content-Disposition: attachment; filename=\"=?utf-8?Q?=E4=BF?=; name=\"=?utf-8?Q?=E8=B2=BB=E6=98=8E=E7=B4=B0?="
        let headers = [Header](string: headersString)

        let contentDisposition = try XCTUnwrap(headers[.contentDisposition])
        XCTAssertEqual(contentDisposition.keyValues["filename"], "=?utf-8?Q?=E4=BF?=")
        XCTAssertEqual(contentDisposition.keyValues["name"], "費明細")
    }

    func testFilenames_notEncoded_areSkipped() throws {
        let headersString = "Content-Disposition: attachment; filename=\"foo.zip; name=\"=?utf-8?Q?=E8=B2=BB=E6=98=8E=E7=B4=B0?="
        let headers = [Header](string: headersString)

        let contentDisposition = try XCTUnwrap(headers[.contentDisposition])
        XCTAssertEqual(contentDisposition.keyValues["filename"], "foo.zip")
        XCTAssertEqual(contentDisposition.keyValues["name"], "費明細")
    }
}
