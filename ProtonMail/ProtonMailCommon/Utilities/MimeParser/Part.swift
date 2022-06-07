//
//  MIMEMessage.Part.swift
//  Marcel
//
//  Created by Ben Gottlieb on 9/1/17.
//  Copyright © 2017 Stand Alone, inc. All rights reserved.
//

import Foundation

struct Part: CustomStringConvertible {
    enum ContentEncoding: String { case base64 }

    let headers: [Header]
    let body: Data
    let subParts: [Part]

    subscript(_ header: Header.Kind) -> String? {
        return self.headers[header]?.cleanedBody
    }

    var bodyString: String {
        var data = self.data.unwrap7BitLineBreaks()
        let ascii = String(data: data, encoding: .ascii) ?? ""

        if ascii.contains("=3D") { data = data.convertFromMangledUTF8() }

        return String(data: data, encoding: .utf8) ?? String(malformedUTF8: data)
    }

    var rawBodyString: String? {
        return String(data: body, encoding: .utf8) ?? String(malformedUTF8: body)
    }

    func findAtts() -> [Part] {
        var ret = [Part]()
        if let cd = self.contentDisposition, cd.isAttachment() {
            ret.append(self)
        }
        for part in self.subParts {
            let subRet = part.findAtts()
            ret.append(contentsOf: subRet)
        }
        return ret
    }

    func getFilename() -> String? {
        if let cd = self.contentDisposition {
            let kv = cd.keyValues
            if let name = kv["filename"] {
                return name.decodedFromUTF8Wrapping
            }
        }

        if let cd = self.headers[.contentType] {
            let kv = cd.keyValues
            if let name = kv["name"] {
                return name.decodedFromUTF8Wrapping
            }
        }

        return nil
    }

    func bodyString(convertingFromUTF8: Bool) -> String {
        var data = self.data.unwrap7BitLineBreaks()
        let ascii = String(data: data, encoding: .ascii) ?? ""

        if ascii.contains("=3D") { data = data.convertFromMangledUTF8() }

        guard let string = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else { return "\(data.count) bytes" }

        return string
    }

    var contentDisposition: Header? { return self.headers[.contentDisposition] }

    var contentCID: String? { return self.headers[.contentID]?.name }
    var cid: String? { return self.headers[.contentID]?.body }

    func partCIDs() -> [Part] {
        var ret = [Part]()
        if self.contentCID?.contains("Content-ID") == true {
            ret.append(self)
        }
        for part in self.subParts {
            let subRet = part.partCIDs()
            ret.append(contentsOf: subRet)
        }
        return ret
    }

    var contentType: String? {
        return self.headers[.contentType]?.body
    }
    var contentEncoding: ContentEncoding? {
        if let body = self.headers[.contentTransferEncoding]?.body {
            let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
             return ContentEncoding(rawValue: trimmedBody)
        }
        return nil
    }

    func part(ofType type: String) -> Part? {
        let lower = type.lowercased()
        if self.contentType?.lowercased().contains(lower) == true { return self }

        for part in self.subParts {
            if let sub = part.part(ofType: lower) { return sub }
        }
        return nil
    }

    var data: Data {
        if self.contentEncoding == .base64,
            let string = String(data: self.body, encoding: .ascii) {
            var trimmed = string.components(separatedBy: .whitespacesAndNewlines).joined()
            let count = trimmed.count
            let remainder = count % 4
            if remainder > 0 { // workaround fix the padding there. somehow the parser breaks the padding. hard to debug now. 
                trimmed = trimmed.padding(toLength: count + 4 - remainder,
                                              withPad: "=",
                                              startingAt: 0)
            }
            if let decoded = Data(base64Encoded: trimmed) {
                return decoded
            }
        }
        return self.body
    }

    init?(data: Data) {
        if let contentStart = data.mimeContentStart {
            let subData = data[0...contentStart]
            guard let components = subData.unwrapTabs().components() else { return nil }

            self.headers = components.all.map { Header($0) }
            self.body = data[contentStart...].convertFromMangledUTF8()
            // self.string = String(data: data[contentStart...], encoding: .utf8) ?? String(malformedUTF8: data[contentStart...])
            var parts: [Part] = []

            let boundaries = self.headers.allHeaders(ofKind: .contentType).compactMap { $0.boundaryValue }
            if let boundary = boundaries.first {
                let groups = data.separated(by: "--" + boundary)

                for i in 0..<groups.count {
                    if let subpart = Part(data: Data(groups[i])) {
                        parts.append(subpart)
                    }
                }
            }
            self.subParts = parts
        } else {
            self.headers = []
            self.subParts = []
            self.body = data
            // self.string = ""
        }
    }

    // only parse header
    init?(header: Data) {
        guard let components = header.unwrapTabs().components() else { return nil }

        self.headers = components.all.map { Header($0) }
        var parts: [Part] = []
        self.body = header

        let boundaries = self.headers.allHeaders(ofKind: .contentType).compactMap { $0.boundaryValue }
        if let boundary = boundaries.first {
            let groups = header.separated(by: "--" + boundary)

            for i in 0..<groups.count {
                if let subpart = Part(data: Data(groups[i])) {
                    parts.append(subpart)
                }
            }
        }
        self.subParts = parts
    }

    var description: String {
        var string = ""

        for header in self.headers {
            string += "\(header)\n"
        }

        string += "\n"
        string += self.bodyString(convertingFromUTF8: true)
        return string
    }
}
