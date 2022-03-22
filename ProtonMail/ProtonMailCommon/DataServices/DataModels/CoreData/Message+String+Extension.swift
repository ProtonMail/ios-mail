//
//  Message+String+Extension.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton AG
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

extension String {
    // this is a backup function. if the other one failed will call this
    func multipartGetHtmlContent() -> String {

        let textplainType = "text/plain".data(using: String.Encoding.utf8)
        let htmlType = "text/html".data(using: String.Encoding.utf8)

        guard
            var data = self.data(using: String.Encoding.utf8) as NSData?,
            var len = data.length as Int?
            else {
                return self.ln2br()
        }

        // get boundary=
        let boundarLine = "boundary=".data(using: String.Encoding.ascii)!
        let boundaryRange = data.range(of: boundarLine, options: NSData.SearchOptions.init(rawValue: 0), in: NSMakeRange(0, len))
        if boundaryRange.location == NSNotFound {
            return self.ln2br()
        }

        // new len
        len = len - (boundaryRange.location + boundaryRange.length)
        data = data.subdata(with: NSMakeRange(boundaryRange.location + boundaryRange.length, len)) as NSData
        let lineEnd = "\n".data(using: String.Encoding.ascii)!
        let nextLine = data.range(of: lineEnd, options: NSData.SearchOptions.init(rawValue: 0), in: NSMakeRange(0, len))
        if nextLine.location == NSNotFound {
            return self.ln2br()
        }
        let boundary = data.subdata(with: NSMakeRange(0, nextLine.location))
        var boundaryString = NSString(data: boundary, encoding: String.Encoding.utf8.rawValue)!
        boundaryString = boundaryString.replacingOccurrences(of: "\"", with: "") as NSString
        boundaryString = boundaryString.replacingOccurrences(of: "\r", with: "") as NSString
        boundaryString = "--".appending(boundaryString as String) as NSString // + boundaryString;

        len = len - (nextLine.location + nextLine.length)
        data = data.subdata(with: NSMakeRange(nextLine.location + nextLine.length, len)) as NSData

        var html: String = ""
        var plaintext: String = ""

        var count = 0
        let nextBoundaryLine = boundaryString.data(using: String.Encoding.ascii.rawValue)!
        var firstboundaryRange = data.range(of: nextBoundaryLine, options: NSData.SearchOptions(rawValue: 0), in: NSMakeRange(0, len))

        if firstboundaryRange.location == NSNotFound {
            return self.ln2br()
        }

        while true {
            if count >= 10 {
                break
            }
            count += 1
            len = len - (firstboundaryRange.location + firstboundaryRange.length) - 1
            data = data.subdata(with: NSMakeRange(1 + firstboundaryRange.location + firstboundaryRange.length, len)) as NSData

            if (data.subdata(with: NSMakeRange(0, 1)) as NSData).isEqual(to: "-".data(using: String.Encoding.ascii)!) {
                break
            }

            let ContentEnd = data.range(of: lineEnd, options: NSData.SearchOptions(rawValue: 0), in: NSMakeRange(2, len - 2))
            if ContentEnd.location == NSNotFound {
                break
            }
            let contentType = data.subdata(with: NSMakeRange(0, ContentEnd.location)) as NSData
            len = len - (ContentEnd.location + ContentEnd.length)
            data = data.subdata(with: NSMakeRange(ContentEnd.location + ContentEnd.length, len)) as NSData

            let EncodingEnd = data.range(of: lineEnd, options: NSData.SearchOptions(rawValue: 0), in: NSMakeRange(2, len - 2))
            if EncodingEnd.location == NSNotFound {
                break
            }
            len = len - (EncodingEnd.location + EncodingEnd.length)
            data = data.subdata(with: NSMakeRange(EncodingEnd.location + EncodingEnd.length, len)) as NSData

            let secondboundaryRange = data.range(of: nextBoundaryLine, options: NSData.SearchOptions(rawValue: 0), in: NSMakeRange(0, len))
            if secondboundaryRange.location == NSNotFound {
                break
            }
            // get data
            let text = data.subdata(with: NSMakeRange(1, secondboundaryRange.location - 1))

            let plainFound = contentType.range(of: textplainType!, options: NSData.SearchOptions(rawValue: 0), in: NSMakeRange(0, contentType.length))
            if plainFound.location != NSNotFound {
                plaintext = NSString(data: text, encoding: String.Encoding.utf8.rawValue)! as String
            }

            let htmlFound = contentType.range(of: htmlType!, options: NSData.SearchOptions(rawValue: 0), in: NSMakeRange(0, contentType.length))
            if htmlFound.location != NSNotFound {
                html = NSString(data: text, encoding: String.Encoding.utf8.rawValue)! as String
            }

            firstboundaryRange = secondboundaryRange
        }

        if  html.isEmpty && plaintext.isEmpty {
            return "<div><pre>" + self.rmln() + "</pre></div>"
        }

        return html.isEmpty ? plaintext.ln2br() : html
    }

}
