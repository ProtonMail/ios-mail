//
//  PMKeymaker+Crypto.swift
//  PMKeymaker
//
//  Created by Anatoly Rosencrantz on 12/03/2020.
//

import Foundation
import Crypto

public struct CryptoSubtle: SubtleProtocol {
    public static func Random(_ len: Int) -> Data? {
        let pgp = CryptoGetGopenPGP()!
        return try? pgp.randomTokenSize(len)
    }
    
    public static func DeriveKey(_ one: String, _ two: Data, _ three: Int, _ four: inout NSError?) -> Data? {
        return SubtleDeriveKey(one, two, three, &four)
    }
    public static func EncryptWithoutIntegrity(_ one: Data, _ two: Data, _ three: Data, _ four: inout NSError?) -> Data? {
        return SubtleEncryptWithoutIntegrity(one, two, three, &four)
    }
    public static func DecryptWithoutIntegrity(_ one: Data, _ two: Data, _ three: Data, _ four: inout NSError?) -> Data? {
        return SubtleDecryptWithoutIntegrity(one, two, three, &four)
    }
    
     
}

public typealias LockedErrors = Errors
public typealias Locked<T> = GenericLocked<T, CryptoSubtle>
public typealias BioProtection = GenericBioProtection<CryptoSubtle>
public typealias PinProtection = GenericPinProtection<CryptoSubtle>
public typealias Keymaker = GenericKeymaker<CryptoSubtle>
public typealias StringCryptoTransformer = GenericStringCryptoTransformer<CryptoSubtle>
