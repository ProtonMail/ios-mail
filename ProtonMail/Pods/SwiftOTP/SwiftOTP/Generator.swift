//
//  Generator.swift
//  SwiftOTP
//
//  Created by Lachlan Bell on 12/1/18.
//  Copyright © 2018 Lachlan Bell. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
//  distribute, sublicense, create a derivative work, and/or sell copies of the
//  Software in any work that is designed, intended, or marketed for pedagogical or
//  instructional purposes related to programming, coding, application development,
//  or information technology.  Permission for such use, copying, modification,
//  merger, publication, distribution, sublicensing, creation of derivative works,
//  or sale is expressly withheld.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import CryptoSwift

internal class Generator {

	// Generator singleton
	static let shared = Generator()
	
	/// Generates a one time password string
	/// - parameter secret: The secret key data
	/// - parameter algorithm: The hashing algorithm to use of type OTPAlgorithm
	/// - parameter counter: UInt64 Counter value
	/// - parameter digits: Number of digits for generated string in range 6...8, defaults to 6
	/// - returns: One time password string, nil if error
	func generateOTP(secret: Data, algorithm: OTPAlgorithm = .sha1, counter: UInt64, digits: Int = 6) -> String? {
		// Get byte array of secret key
		let key = secret.bytes
		
		// HMAC message data from counter as big endian
		let counterMessage = counter.bigEndian.data
		
		// HMAC hash counter data with secret key
		guard let hmac = try? HMAC(key: key, variant: algorithm.hmacVariant).authenticate(counterMessage.bytes) else { return nil }
		
		// Get last 4 bits of hash as offset
		let offset = Int((hmac.last ?? 0x00) & 0x0f)
		
		// Get 4 bytes from the hash from [offset] to [offset + 3]
		let truncatedHMAC = Array(hmac[offset...offset + 3])
		
		// Convert byte array of the truncated hash to data
		let data =  Data(truncatedHMAC)
		
		// Convert data to UInt32
		var number = UInt32(strtoul(data.toHexString(), nil, 16))
		
		// Mask most significant bit
		number &= 0x7fffffff
		
		// Modulo number by 10^(digits)
		number = number % UInt32(pow(10, Float(digits)))

		// Convert int to string
		let strNum = String(number)
		
		// Return string if adding leading zeros is not required
		if strNum.count == digits {
			return strNum
		}
		
		// Add zeros to start of string if not present and return
		let prefixedZeros = String(repeatElement("0", count: (digits - strNum.count)))
		return (prefixedZeros + strNum)
	}
}
