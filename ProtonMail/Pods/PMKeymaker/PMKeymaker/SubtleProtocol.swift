//
//  SubtleProtocol.swift
//  PMKeymaker
//
//  Created by Anatoly Rosencrantz on 12/03/2020.
//

import Foundation

public protocol SubtleProtocol {
    static func DeriveKey(_ one: String, _ salt: Data, _ three: Int, _ four: inout NSError?) -> Data?
    static func EncryptWithoutIntegrity(_ one: Data, _ two: Data, _ three: Data, _ four: inout NSError?) -> Data?
    static func DecryptWithoutIntegrity(_ one: Data, _ two: Data, _ three: Data, _ four: inout NSError?) -> Data?
    static func Random(_ bitlen : Int) -> Data?
}
