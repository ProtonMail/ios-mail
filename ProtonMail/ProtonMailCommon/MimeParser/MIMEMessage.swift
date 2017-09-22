//
//  MIMEMessage.swift
//  Marcel
//
//  Created by Ben Gottlieb on 8/31/17.
//  Copyright © 2017 Stand Alone, inc. All rights reserved.
//

import Foundation

public class MIMEMessage {
	public var raw: Data
	public var subject: String? { return self[.subject] }
	
	var data: Data
	var string: String
	var mainPart: Part!
	
	public var htmlBody: String? {
		if let html = self.mainPart.part(ofType: "text/html")?.bodyString { return html }
		if let text = self.mainPart.part(ofType: "text/plain")?.bodyString { return "<html><body>\(text)</body></html>" }
		return nil
	}
    
    public var hasMultipart: Bool {
        return self.mainPart.part(ofType: "multipart/mixed") == nil
    }
	
	public subscript(_ field: Header.Kind) -> String? {
		return self.mainPart[field]
	}
	
	enum BoundaryType: String { case alternative, related }
	
	public init?(data: Data) {
		guard let string = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
			self.data = Data()
			self.string = ""
			
			return nil
		}
		
		self.raw = data
		self.data = data.convertFromMangledUTF8()
		self.string = string
		if !self.setup() { return nil }
	}
		
	public init?(string: String) {
		guard let data = string.data(using: .utf8) else {
			self.data = Data()
			self.raw = Data()
			self.string = ""
			
			return nil
		}
		self.string = string
		self.data = data.convertFromMangledUTF8()
		self.raw = self.data
		if !self.setup() { return nil }
	}
	
	func setup() -> Bool {
		if let components = self.data.components(separatedBy: "\n") {
			self.mainPart = Part(components: components)
			
			return true
		}
		return false
	}
}
