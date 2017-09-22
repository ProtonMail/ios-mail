//
//  MIMEMessage.Part.swift
//  Marcel
//
//  Created by Ben Gottlieb on 9/1/17.
//  Copyright © 2017 Stand Alone, inc. All rights reserved.
//

import Foundation


public struct Part: CustomStringConvertible {
    public enum ContentEncoding: String { case base64 }
    
    public let headers: [Header]
    public let body: Data
    let subParts: [Part]
    
    public subscript(_ header: Header.Kind) -> String? {
        return self.headers[header]?.cleanedBody
    }
    
    public var bodyString: String {
        let data = self.data
        
        guard let string = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else { return "\(data.count) bytes" }
        
        return string
    }
    
    public var contentType: String? { return self.headers[.contentType]?.body }
    public var contentEncoding: ContentEncoding? { return ContentEncoding(rawValue: self.headers[.contentTransferEncoding]?.body ?? "") }
    func part(ofType type: String) -> Part? {
        if self.contentType?.contains(type) == true { return self }
        
        for part in self.subParts {
            if let sub = part.part(ofType: type) { return sub }
        }
        return nil
    }
    
    var data: Data {
        if self.contentEncoding == .base64,
            let string = String(data: self.body, encoding: .ascii),
            let decoded = Data(base64Encoded: string) {
            return decoded
        }
        return self.body
    }
    
    init(components: Data.Components) {
        if let blankIndex = components.index(of: "") {
            self.headers = components[0..<blankIndex].map { Header($0) }
            self.body = components[blankIndex..<components.count]
            var dataString = String(data: self.body, encoding: .utf8)
//            let b = String(data: self.body, .utf8)
            PMLog.D(dataString!)
            
            var parts: [Part] = []
            if let boundary = self.headers[.contentType]?.boundaryValue {
                let groups = components.separated(by: boundary)
                let gcount = groups.count
                if gcount > 0 {
                    for i in 1..<groups.count {
                        let group = groups[i]
                        let subpart = Part(components: group)
                        parts.append(subpart)
                    }
                }
            }
            self.subParts = parts
        } else {
            self.headers = components.all.map { Header($0) }
            self.subParts = []
            self.body = Data()
        }
    }
    
    public var description: String {
        var string = ""
        
        for header in self.headers {
            string += "\(header)\n"
        }
        
        string += "\n"
        string += self.bodyString
        return string
    }
}
