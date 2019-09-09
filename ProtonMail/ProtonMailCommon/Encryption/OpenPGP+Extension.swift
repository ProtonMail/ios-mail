
//
//  OpenPGPExtension.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
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
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import Crypto


extension CryptoPmCrypto {
    func random(byte: Int) -> Data? {
        do {
            let out = try self.randomToken(with: byte)
            return out
        } catch {
            
        }
        return nil
    }
    
    class func updateKeysPassword(_ old_keys : [Key], old_pass: String, new_pass: String ) throws -> [Key] {
        var outKeys : [Key] = [Key]()
        for okey in old_keys {
            do {
                let new_private_key = try sharedOpenPGP.updatePrivateKeyPassphrase(okey.private_key,
                                                                                   oldPassphrase: old_pass,
                                                                                   newPassphrase: new_pass)
                let newK = Key(key_id: okey.key_id,
                               private_key: new_private_key,
                               token: nil,
                               signature: nil,
                               activation: nil,
                               isupdated: true)
                outKeys.append(newK)
            } catch {
                let newK = Key(key_id: okey.key_id,
                               private_key: okey.private_key,
                               token: nil,
                               signature: nil,
                               activation: nil,
                               isupdated: false)
                outKeys.append(newK)
            }
        }
        
        guard outKeys.count == old_keys.count else {
            throw UpdatePasswordError.keyUpdateFailed.error
        }
        
        guard outKeys.count > 0 && outKeys[0].is_updated == true else {
            throw UpdatePasswordError.keyUpdateFailed.error
        }
        
        for u_k in outKeys {
            if u_k.is_updated == false {
                continue
            }
            let result = KeyCheckPassphrase(u_k.private_key, new_pass)
            guard result == true else {
                throw UpdatePasswordError.keyUpdateFailed.error
            }
        }
        return outKeys
    }
    
    class func updateAddrKeysPassword(_ old_addresses : [Address], old_pass: String, new_pass: String ) throws -> [Address] {
        var out_addresses = [Address]()
        for addr in old_addresses {
            var outKeys : [Key] = [Key]()
            for okey in addr.keys {
                do {
                    let new_private_key = try sharedOpenPGP.updatePrivateKeyPassphrase(okey.private_key,
                                                                                       oldPassphrase: old_pass,
                                                                                       newPassphrase: new_pass)
                    let newK = Key(key_id: okey.key_id,
                                   private_key: new_private_key,
                                   token: nil,
                                   signature: nil,
                                   activation: nil,
                                   isupdated: true)
                    outKeys.append(newK)
                } catch {
                    let newK = Key(key_id: okey.key_id,
                                   private_key: okey.private_key,
                                   token: nil,
                                   signature: nil,
                                   activation: nil,
                                   isupdated: false)
                    outKeys.append(newK)
                }
            }
            
            guard outKeys.count == addr.keys.count else {
                throw UpdatePasswordError.keyUpdateFailed.error
            }
            
            guard outKeys.count > 0 && outKeys[0].is_updated == true else {
                throw UpdatePasswordError.keyUpdateFailed.error
            }
            
            for u_k in outKeys {
                if u_k.is_updated == false {
                    continue
                }
                let result = KeyCheckPassphrase(u_k.private_key, new_pass)
                guard result == true else {
                    throw UpdatePasswordError.keyUpdateFailed.error
                }
            }
            
            let new_addr = Address(addressid: addr.address_id,
                                   email: addr.email,
                                   order: addr.order,
                                   receive: addr.receive,
                                   display_name: addr.display_name,
                                   signature: addr.signature,
                                   keys: outKeys,
                                   status: addr.status,
                                   type: addr.type,
                                   send: addr.send)
            out_addresses.append(new_addr)
        }
        
        guard out_addresses.count == old_addresses.count else {
            throw UpdatePasswordError.keyUpdateFailed.error
        }
        
        return out_addresses
    }
}

//
extension PMNOpenPgp {
//    enum ErrorCode: Int {
//        case badPassphrase = 10001
//        case noPrivateKey = 10004
//        case badProtonMailPGPMessage = 10006
//    }
//
//    static func checkPassphrase(_ passphrase: String, forPrivateKey privateKey: String) -> Bool {
//        if !checkPassphrase(privateKey, passphrase: passphrase) {
//            return false
//        }
//        return true
//    }
//
    func generateKey(_ passphrase: String, userName: String, domain:String, bits: Int32) throws -> PMNOpenPgpKey? {
        var out_new_key : PMNOpenPgpKey?
        try ObjC.catchException {
            out_new_key = self.generateKey(userName, domain: domain, passphrase: passphrase, bits: bits, time: 0)
            if out_new_key!.privateKey.isEmpty || out_new_key!.publicKey.isEmpty {
                out_new_key = nil
            }
        }
        return out_new_key
    }
    
    func generateRandomKeypair() throws -> (passphrase: String, publicKey: String, privateKey: String) {
        let passphrase = UUID().uuidString
        let username = UUID().uuidString
        let domain = "protonmail.com"
        
        guard let keypair = try self.generateKey(passphrase,
                                                 userName: (username + "@" + domain).isValidEmail() ? username : "noreply",
                                                 domain: domain,
                                                 bits: Int32(2048)) else
        {
            throw NSError(domain: #file, code: 1, localizedDescription: "Failed to generate random keypair")
        }
        return (passphrase, keypair.publicKey, keypair.privateKey)
    }
}

//    class func updateKeyPassword(_ private_key: String, old_pass: String, new_pass: String ) throws -> String {
//        var out_key : String?
//        try ObjC.catchException {
//            out_key = PMNOpenPgp.updateSinglePassphrase(private_key, oldPassphrase: old_pass, newPassphrase: new_pass)
//            if out_key == nil || out_key!.isEmpty {
//                out_key = nil
//            }
//        }
//
//        guard let outKey = out_key else {
//            throw UpdatePasswordError.keyUpdateFailed.error
//        }
//
//        guard PMNOpenPgp.checkPassphrase(outKey, passphrase: new_pass) else {
//            throw UpdatePasswordError.keyUpdateFailed.error
//        }
//
//        return outKey
//    }
//
//
//    func signVerify(detached signature: String, publicKey: String, plainText: String ) -> Bool {
//        var check = false
//        do {
//            try ObjC.catchException {
//                check = self.signDetachedVerifySinglePubKey(publicKey, signature: signature, plainText: plainText)
//            }
//        } catch {
//
//        }
//        return check
//    }
//}

extension Data {
    func decryptAttachment(keyPackage: Data, userKeys: Data, passphrase: String, keys: [Key]) throws -> Data? {
        var firstError : Error?
        for key in keys {
            do {
                if let token = key.token, let signature = key.signature { //have both means new schema. key is
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        PMLog.D(signature)
                        return try sharedOpenPGP.decryptAttachment(keyPackage, dataPacket: self, privateKey: key.private_key, passphrase: plaitToken)
                    }
                } else if let token = key.token { //old schema with token - subuser. key is embed singed
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //TODO:: try to verify signature here embeded signature
                        return try sharedOpenPGP.decryptAttachment(keyPackage, dataPacket: self, privateKey: key.private_key, passphrase: plaitToken)
                    }
                } else {//normal key old schema
                    return try sharedOpenPGP.decryptAttachmentBinKey(keyPackage, dataPacket: self, privateKeys: userKeys, passphrase: passphrase)
                }
            } catch let error {
                if firstError == nil {
                    firstError = error
                }
                PMLog.D(error.localizedDescription)
            }
        }
        if let error = firstError {
            throw error
        }
        return nil
    }
    
    
    func decryptAttachment(_ keyPackage: Data, passphrase: String, privKeys: Data) throws -> Data? {
        return try sharedOpenPGP.decryptAttachmentBinKey(keyPackage, dataPacket: self, privateKeys: privKeys, passphrase: passphrase)
    }

    func decryptAttachmentWithSingleKey(_ keyPackage: Data, passphrase: String, publicKey: String, privateKey: String) throws -> Data? {
        return try sharedOpenPGP.decryptAttachment(keyPackage, dataPacket: self, privateKey: privateKey, passphrase: passphrase)
    }
    
  
    func signAttachment(byPrivKey: String, passphrase: String) throws -> String? {
        return try sharedOpenPGP.signBinDetached(self, privateKey: byPrivKey, passphrase: passphrase)
    }
    
    func encryptAttachment(fileName:String, pubKey: String) throws -> ModelsEncryptedSplit? {
        return try sharedOpenPGP.encryptAttachment(self, fileName: fileName, publicKey: pubKey)
    }
    
    static func makeEncryptAttachmentProcessor(fileName:String, totalSize: Int, pubKey: String) throws -> CryptoAttachmentProcessor {
        return try sharedOpenPGP.encryptAttachmentLowMemory(totalSize, fileName: fileName, publicKey: pubKey)
    }
    
    //key packet part
    func getSessionFromPubKeyPackage(_ passphrase: String, privKeys: Data) throws -> ModelsSessionSplit? {
        let out = try sharedOpenPGP.getSessionFromKeyPacketBinkeys(self, privateKey: privKeys, passphrase: passphrase)
        return out
    }
    
    //key packet part
    func getSessionFromPubKeyPackage(addrPrivKey: String, passphrase: String) throws -> ModelsSessionSplit? {
        return try sharedOpenPGP.getSessionFromKeyPacket(self, privateKey: addrPrivKey, passphrase: passphrase)
    }
    
    //key packet part
    func getSessionFromPubKeyPackage(userKeys: Data, passphrase: String, keys: [Key]) throws -> ModelsSessionSplit? {
        var firstError : Error?
        for key in keys {
            do {
                if let token = key.token, let signature = key.signature { //have both means new schema. key is
                    if let plainToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        PMLog.D(signature)
                        return try sharedOpenPGP.getSessionFromKeyPacket(self, privateKey: key.private_key, passphrase: plainToken)
                    }
                } else if let token = key.token { //old schema with token - subuser. key is embed singed
                    if let plainToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //TODO:: try to verify signature here embeded signature
                        return try sharedOpenPGP.getSessionFromKeyPacket(self, privateKey: key.private_key, passphrase: plainToken)
                    }
                } else {//normal key old schema
                    return try sharedOpenPGP.getSessionFromKeyPacketBinkeys(self, privateKey: userKeys, passphrase: passphrase)
                }
            } catch let error {
                if firstError == nil {
                    firstError = error
                }
                PMLog.D(error.localizedDescription)
            }
        }
        if let error = firstError {
            throw error
        }
        return nil
    }
    
    func getKeyPackage(strKey publicKey: String, algo : String) throws -> Data? {
        let session = ModelsSessionSplit()!
        session.setSession(self)
        session.setAlgo(algo) //default is "aes256"
        let packet : Data? = try sharedOpenPGP.keyPacket(withPublicKey: session, publicKey: publicKey)
        return packet
    }
    
    func getKeyPackage(dataKey publicKey: Data, algo : String) throws -> Data? {
        let session = ModelsSessionSplit()!
        session.setSession( self)
        session.setAlgo(algo) //default is "aes256"
        let packet : Data? = try sharedOpenPGP.keyPacket(withPublicKeyBin: session, publicKey: publicKey)
        return packet
    }
    
    func getSymmetricPacket(withPwd pwd: String, algo : String) throws -> Data? {
        let session = ModelsSessionSplit()!
        session.setSession(self)
        session.setAlgo(algo) //default is "aes256"
        let packet : Data? = try sharedOpenPGP.symmetricKeyPacket(withPassword: session, password: pwd)
        return packet
    }
}
