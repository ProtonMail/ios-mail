//
//  MIMEMessage.swift
//  Marcel
//
//  Created by Ben Gottlieb on 8/31/17.
//  Copyright © 2017 Stand Alone, inc. All rights reserved.
//

import Foundation

class MIMEMessage: Equatable {
	var raw: Data
	var subject: String? { return self[.subject] }

	var data: Data
	var string: String
	var mainPart: Part!

    var htmlBody: String? {
        if let html = self.mainPart.part(ofType: "text/html")?.bodyString(convertingFromUTF8: false) { return html }
        if let text = self.mainPart.part(ofType: "text/plain")?.bodyString(convertingFromUTF8: true) { return "<html><body>\(text)</body></html>" }
        return nil
    }

    subscript(_ field: Header.Kind) -> String? {
        return self.mainPart[field]
    }

    var identifier: String? {
        return self[.messageID] ?? self[.dkimSignature]
    }

    enum BoundaryType: String { case alternative, related }

    init?(data: Data) {
        guard let string = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            self.data = Data()
            self.string = ""

            return nil
        }

        self.raw = data
        self.data = data
        self.string = string
        if !self.setup() { return nil }
    }

    convenience init?(string: String) {
        self.init(data: string.data(using: .utf8) ?? Data())
    }

    func setup() -> Bool {
        if let part = Part(data: self.data) {
            self.mainPart = part
            return true
        }
        return false
    }

    static func ==(lhs: MIMEMessage, rhs: MIMEMessage) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
