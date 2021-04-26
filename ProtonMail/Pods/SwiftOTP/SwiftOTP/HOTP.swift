//
//  HOTP.swift
//  SwiftOTP
//
//  Created by Lachlan Bell on 14/1/18.
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

/// Counter-based one time password object
public struct HOTP {
	public let secret: Data
	public let digits: Int
	public let algorithm: OTPAlgorithm
	
	/// Initialise counter-based one time password object
	/// - parameter secret: Secret key data
	/// - parameter digits: Number of digits for generated string in range 6...8, defaults to 6
	/// - parameter algorithm: The hashing algorithm to use of type OTPAlgorithm, defaults to SHA-1
	/// - precondition: digits *must* be between 6 and 8 inclusive
	public init?(secret: Data, digits: Int = 6, algorithm: OTPAlgorithm = .sha1) {
		self.secret = secret
		self.digits = digits
		self.algorithm = algorithm
		
		guard validateDigits(digit: digits) else { return nil }
	}
	
	/// Generate one time password string from counter value
	/// - parameter counter: UInt64 counter value
	/// - returns: One time password string, nil if error
	/// - precondition: Counter value must be of type UInt64
	public func generate(counter: UInt64) -> String? {
		return Generator.shared.generateOTP(secret: secret, algorithm: algorithm, counter: counter, digits: digits)
	}
	
	/// Verify time integer is postive
	/// - parameter time: Time since Unix epoch (01 Jan 1970 00:00 UTC)
	/// - returns: Whether time is valid
	private func validateDigits(digit: Int) -> Bool{
		let validDigits = 6...8
		return validDigits.contains(digit)
	}
}
