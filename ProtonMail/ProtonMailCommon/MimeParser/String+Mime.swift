//
//  String+Mime.swift
//  MimeKit
//
//  Created by Ben Gottlieb on 8/31/17.
//  Copyright © 2017 Stand Alone, inc. All rights reserved.
//

import Foundation

extension String {
	var decodedFromUTF8Wrapping: String {
		var result = self
		let utf = "=?utf-8?Q?"
		let utfEnd = "?="
		
//		while let range = result.range(of: utf, options: .caseInsensitive),
//			let endRange = result.range(of: utfEnd, options: .caseInsensitive, range: range.upperBound..<(self.index(before: self.endIndex)), locale: nil) {

		while let range = result.range(of: utf, options: .caseInsensitive), let endRange = result.range(of: utfEnd), range.upperBound < endRange.lowerBound {
			let innerRange = range.upperBound..<endRange.lowerBound
			let innerChunk = String(result[innerRange]) ?? ""
			result = result.replacingCharacters(in: range.lowerBound..<endRange.upperBound, with: innerChunk.convertedFromEmailHeaderField)
		}
		return result.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	var convertedFromEmailHeaderField: String {
		var result = self.replacingOccurrences(of: "_", with: " ")
		
		while let range = result.range(of: "=") {
			if range.upperBound > result.index(result.endIndex, offsetBy: -2) { break }
			let ascii = UInt8(String(result[range.upperBound..<result.index(range.upperBound, offsetBy: 2)]), radix: 16) ?? 20
			let replacement = String(UnicodeScalar(ascii))
			result = result.replacingCharacters(in: range.lowerBound..<result.index(range.upperBound, offsetBy: 2), with: replacement)
		}
		
		return result
	}
}

