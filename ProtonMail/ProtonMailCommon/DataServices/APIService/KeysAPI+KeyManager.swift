//
//  KeysAPI.swift
//  ProtonMail - Created on 11/11/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import PromiseKit
import Crypto
import PMCommon

///MARK: This file is prepared for future key manager framwork

/// The key apis path
let path : String = "/keys"

/// Raw key list object - this object will need convert to json string then signed it
final class KeyListRaw : Package {
    let fingerprint : String
    let sha256Fingerprint: [String]?
    let primary : Int
    let flags: Int
    
    
    /// KeyListRaw init key v1.2
    /// - Parameters:
    ///   - fingerprint: normal key fingerprint
    ///   - sha256fingerprint: sha256 fingerprints
    ///   - primary: is the key primary or others
    ///   - flags: bitmap key flags : 1 = can be used to verify, 2 = can be used to encrypt
    init(fingerprint: String, sha256fingerprint: [String], primary: Int, flags: Int) {
        self.fingerprint = fingerprint
        self.sha256Fingerprint = sha256fingerprint
        self.primary = primary
        self.flags = flags
    }
    
    /// KeyListRaw init key v1.1
    /// - Parameters:
    ///   - fingerprint: normal key fingerprint
    ///   - primary: is the key primary or others
    ///   - flags: bitmap key flags : 1 = can be used to verify, 2 = can be used to encrypt
    init(fingerprint: String, primary: Int, flags: Int) {
        self.fingerprint = fingerprint
        self.sha256Fingerprint = nil
        self.primary = primary
        self.flags = flags
    }
    
    var parameters: [String : Any]? {
        var out : [String : Any] = [
            "Fingerprint": self.fingerprint,
            "Primary": self.primary,
            "Flags": self.flags
        ]
        if let sha256fp = self.sha256Fingerprint {
            out["SHA256Fingerprints"] = sha256fp
        }
        return out
    }
    
    var json : String {
        let params = self.parameters!
        return params.json()
    }
}

/// Signed key list. package for SetupKeyRequest
final class SignedKeyList : Package {
    
    ///"Data": JSON.stringify([
    ///{
    ///  "SHA256Fingerprints": ["164ec63...53c93f7", "f767d...f53b0c"],
    ///  "Fingerprint": "c93f767df53b0ca8395cfde90483475164ec6353",
    ///  "Primary": 1,
    ///  "Flags": 3
    ///  }
    ///]),
    let data : String
    
    /// "-----BEGIN PGP SIGNATURE-----.*"
    let signature: String
    
    /// signed key list Init
    /// - Parameters:
    ///   - data: Keylist Raw array  [KeyListRaw] to json string
    ///   - signature: Detached signature of data
    init(data: String, signature: String) {
        self.data = data
        self.signature = signature
    }
    
    var parameters: [String : Any]? {
        return [
            "Data": self.data,
            "Signature": self.signature
        ]
    }
}

final class AddressKey : Package {
    
    /// address id this key belongs to -- "xRvCGwFq_TW7i8FtJaGyFEq0g==",
    let addressID : String
    
    /// The private key -- "-----BEGIN PGP PRIVATE KEY BLOCK-----.*",
    let privateKey : String
    
    /// v1.2 The random token encrypted by userKey.   token is the key passphrase -- "-----BEGIN PGP MESSAGE-----.*",
    let token : String?
    
    /// v1.2 The signature of the token. signed by user key --  "-----BEGIN PGP SIGNATURE-----.*",
    let signature: String?
    
    /// Signed Key list object : SignedKeyList
    let signedKeyList: SignedKeyList
  
    
    /// AddressKey inital key v1.2
    /// - Parameters:
    ///   - addressID: address id
    ///   - privateKey: address private key
    ///   - token: The random token encrypted by userKey - armed format
    ///   - signature: encrypted token signature
    ///   - signedKeyList: signed key list
    internal init(addressID: String, privateKey: String,
                  token: String, signature: String,
                  signedKeyList: SignedKeyList) {
        self.addressID = addressID
        self.privateKey = privateKey
        self.token = token
        self.signature = signature
        self.signedKeyList = signedKeyList
    }
    
    /// AddressKey inital key v1.1
    /// - Parameters:
    ///   - addressID: address id
    ///   - privateKey: address private key
    ///   - token: The random token encrypted by userKey - armed format
    ///   - signature: encrypted token signature
    ///   - signedKeyList: signed key list
    internal init(addressID: String,
                  privateKey: String,
                  signedKeyList: SignedKeyList) {
        self.addressID = addressID
        self.privateKey = privateKey
        self.token = nil
        self.signature = nil
        self.signedKeyList = signedKeyList
    }
    
    var parameters: [String : Any]? {
        var out : [String : Any] = [
            "AddressID": self.addressID,
            "PrivateKey": self.privateKey,
            "SignedKeyList": self.signedKeyList.parameters
        ]
        
        if let t = self.token, let s = self.signature {
            out["Token"] = t
            out["Signature"] = s
        }
        return out
    }
}


/// Setup a new key  -- Response
final class SetupKeyRequest : Request {

    /// PrimaryKey
    let primaryKey : String
    
    /// base64 encoded need random value -- RANDOMLY generated client-side
    let keySalt : String
    
    /// address keys package
    let addressKeys: [AddressKey]
    
    /// auth package
    let passwordAuth : PasswordAuth
    
    
    /// SetupKeyRequest inital
    /// - Parameters:
    ///   - primaryKey: primary key, ususally same with PrivateKey inside the AddressKey
    ///   - keySalt: randmon key salt, base64 format
    ///   - addressKeys: address keys package
    ///   - auth: auth package
    ///   - credential: customized credential, access tokens
    init(primaryKey: String, keySalt: String,
         addressKeys: [AddressKey], passwordAuth: PasswordAuth,
         credential: AuthCredential?) {
        self.primaryKey = primaryKey
        self.keySalt = keySalt
        self.addressKeys = addressKeys
        self.passwordAuth = passwordAuth
        self.credential = credential
    }

    //custom auth credentical
    let credential: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.credential
        }
    }
    
    var parameters: [String : Any]? {
        let out : [String : Any] = [
            "PrimaryKey": self.primaryKey, //"PrimaryKey": "-----BEGIN PGP PRIVATE KEY BLOCK-----.*",
            "KeySalt" : self.keySalt, //"KeySalt": <base64_encoded_key_salt>, // RANDOMLY generated client-side
            "AddressKeys" : self.addressKeys.parameters ?? [:],
            "Auth" : self.passwordAuth.parameters ?? [:]   //"Auth": { 4 params }
        ]

        PMLog.D(out.json(prettyPrinted: true))
        return out
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var path: String {
        return KeysAPI.path + "/setup"
    }
}
