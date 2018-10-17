//
//  Keymaker.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 13/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//
//  There is a building. Inside this building there is a level
//  where no elevator can go, and no stair can reach. This level
//  is filled with doors. These doors lead to many places. Hidden
//  places. But one door is special. One door leads to the source.
//

import Foundation
import LocalAuthentication
import Security
import CryptoSwift

var keymaker = Keymaker.shared
class Keymaker: NSObject {
    typealias Key = Array<UInt8>
    typealias Salt = Array<UInt8>
    
    private(set) var mainKey: Key?
    
    static var shared = Keymaker()
    private let controlThread = DispatchQueue.global(qos: .utility)
    
    private override init() {
        super.init()
        
        defer {
            self.obtainMainKey() {
                self.mainKey = $0
            }
        }
    }
    
    private func swallowMainKey() {
        self.mainKey = nil
    }
    
    private func destroyMainKey() {
        sharedKeychain.keychain().removeItem(forKey: "mainKeyCypher")
    }
    
    private func obtainMainKey(with handler: (Key)->Void) {
        self.controlThread.sync {
            guard self.mainKey == nil else {
                handler(self.mainKey!)
                return
            }
            
            guard let cypherBits = sharedKeychain.keychain().data(forKey: "mainKeyCypher") else {
                let mainKey = self.generateRandomValue(length: 32)
                try! self.lock(mainKey: mainKey, with: .none) // FIXME: get real track
                handler(mainKey)
                return
            }

            let mainKeyBytes = try! self.unlock(cypherBits: cypherBits.bytes, with: .none) // FIXME: get real track
            handler(mainKeyBytes.bytes)
        }
    }
    
    private func generateRandomValue(length: Int) -> Array<UInt8> {
        var newKey = Array<UInt8>(repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, newKey.count, &newKey)
        guard status == 0 else {
            fatalError("failed to generate cryptographically secure value")
        }
        return newKey
    }
    
    enum Track {
        case pin(String)
        case bioAndPin(String)
        case none
        case bio
        
        static var secureEnclaveLabel: String = "mainKey"
        
        func saveCyphertextInKeychain(_ cypher: Data) {
            // TODO: save cypher in keychain
        }
    }
    
    private func unlock(cypherBits: Key, with track: Track) throws -> Data {
        let locked = Locked<Key>.init(encryptedValue: Data(bytes: cypherBits))
        switch track {
        case .pin(let userInputPin):
            // let user enter PIN
            // pass handler further
            break
            
        case .bio:
            // talk to secure enclave
            // call handler()
            break
            
        case .none:
            // main key is stored in Keychain cleartext
            // call handler()
            break
        
        case .bioAndPin: break // can not happen in real life: two different UIs
        }
        
        fatalError()
    }
    
    private func lock(mainKey: Key, with track: Track) throws {
        switch track {
        case .pin(let pin):
            // 1. generate new salt
            // 2. derive key from pin and salt
            // 3. encrypt mainKey with ethemeralKey
            // 4. save salt in keychain
            // 5. save encryptedMainKey in keychain
            
            let salt = self.generateRandomValue(length: 8)
            let ethemeralKey = try PKCS5.PBKDF2(password: Array(pin.utf8), salt: salt, iterations: 4096, variant: .sha256).calculate()
            let locked = try Locked<Key>(clearValue: mainKey, with: ethemeralKey)
            
            track.saveCyphertextInKeychain(locked.encryptedValue)
            // TODO: save salt in keychain
            
        case .bio:
            if #available(iOS 10.0, *) {
                // 1. get enclosing key pair from SE
                // 2. encrypt mainKey with public key
                // 3. save publicKey in keychain
                // 4. save encryptedMainKey in keychain
                
                var error: Unmanaged<CFError>?
                let access = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                             kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                                                             .privateKeyUsage,
                                                             &error)!
                let privateKeyAttributes: Dictionary<String, Any> = [
                    kSecAttrIsPermanent as String:      true,
                    kSecAttrApplicationTag as String:   Track.secureEnclaveLabel,
                    kSecAttrAccessControl as String:    access
                ]
                let attributes: Dictionary<String, Any> = [
                    kSecAttrKeyType as String:          kSecAttrKeyTypeECSECPrimeRandom as String,
                    kSecAttrKeySizeInBits as String:    256,
                    kSecAttrTokenID as String:          kSecAttrTokenIDSecureEnclave,
                    kSecPrivateKeyAttrs as String:      privateKeyAttributes
                    
                ]

                var publicKey, privateKey: SecKey?
                let status = SecKeyGeneratePair(attributes as CFDictionary, &publicKey, &privateKey)
                guard status == 0, publicKey != nil else {
                    throw NSError(domain: String(describing: Keymaker.self), code: 0, localizedDescription: "Failed to generate SE elliptic keypair")
                    // TODO: check on non-SecureEnclave-capable device with ios10-11
                }
                
                let locked = try Locked<Key>(clearValue: mainKey) { cleartext -> Data in
                    var error: Unmanaged<CFError>?
                    let cypherdata = SecKeyCreateEncryptedData(publicKey!,
                                                           SecKeyAlgorithm.eciesEncryptionStandardX963SHA256AESGCM,
                                                           Data(bytes: cleartext) as CFData,
                                                           &error)
                    guard error == nil, cypherdata != nil else {
                        throw NSError(domain: String(describing: Keymaker.self), code: 0, localizedDescription: "Failed to encrypt data with SE publicKey")
                    }
                    return cypherdata! as Data
                }
                
                track.saveCyphertextInKeychain(locked.encryptedValue)
                // TODO: save public key in keychain

                
            } else {
                // TODO: save mainKey in keychain with touchID access _shrug_
            }
            
        case .bioAndPin(let pin):
            try self.lock(mainKey: mainKey, with: .pin(pin))
            try self.lock(mainKey: mainKey, with: .bio)
            
        case .none:
            track.saveCyphertextInKeychain(Data(bytes: mainKey))
        }
    }
}


extension Keymaker {
    internal func getUnlockFlow() -> SignInUIFlow {
        if sharedTouchID.showTouchIDOrPin() {
            if userCachedStatus.isPinCodeEnabled && !userCachedStatus.pinCode.isEmpty {
                return SignInUIFlow.requirePin
            } else {
                //check touch id status
                if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
                    return SignInUIFlow.requireTouchID
                } else {
                    return SignInUIFlow.restore
                }
            }
        } else {
            return SignInUIFlow.restore
        }
    }
}

#if !APP_EXTENSION
extension Keymaker {
    internal func unlock(accordingToFlow signinFlow: SignInUIFlow,
                         requestPin: @escaping ()->Void,
                         onRestore: @escaping ()->Void,
                         afterSignIn: @escaping ()->Void)
    {
        switch signinFlow {
        case .requirePin:
            sharedUserDataService.isSignedIn = false
            requestPin()
            
        case .requireTouchID:
            sharedUserDataService.isSignedIn = false
            self.biometricAuthentication(afterBioAuthPassed: onRestore, afterSignIn: afterSignIn)
            
        case .restore:
            self.signInIfRememberedCredentials(onSuccess: afterSignIn)
            onRestore()
        }
    }
    
    internal func signIn(username: String,
                password: String,
                cachedTwoCode: String?,
                ask2fa: @escaping ()->Void,
                onError: @escaping (NSError)->Void,
                afterSignIn: @escaping ()->Void,
                requestMailboxPassword: @escaping ()->Void)
    {
        if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
            self.clean()
        }
        
        //need pass twoFACode
        sharedUserDataService.signIn(username,
                                     password: password,
                                     twoFACode: cachedTwoCode,
                                     ask2fa: ask2fa,
                                     onError: onError,
                                     onSuccess: { (mailboxpwd) in
                                        afterSignIn()
                                        if let mailboxPassword = mailboxpwd {
                                            self.decryptPassword(mailboxPassword, onError: onError)
                                        } else {
                                            UserTempCachedStatus.restore()
                                            self.loadContent(requestMailboxPassword: requestMailboxPassword)
                                        }
        })
    }
    
    internal func biometricAuthentication(afterBioAuthPassed: @escaping ()->Void,
                                          afterSignIn: @escaping ()->Void)
    {
        let savedEmail = userCachedStatus.codedEmail()
        
        let context = LAContext()
        var error: NSError?
        context.localizedFallbackTitle = ""
        let reasonString = "\(LocalString._general_login): \(savedEmail)"
        
        guard context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) else{
            var alertString : String = "";
            switch error!.code{
            case LAError.Code.touchIDNotEnrolled.rawValue:
                alertString = LocalString._general_touchid_not_enrolled
            case LAError.Code.passcodeNotSet.rawValue:
                alertString = LocalString._general_passcode_not_set
            case -6:
                alertString = error?.localizedDescription ?? LocalString._general_touchid_not_available
                break
            default:
                alertString = LocalString._general_touchid_not_available
            }
            alertString.alertToast()
            return
        }
        
        context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString) { success, evalPolicyError in
            DispatchQueue.main.async {
                guard success else {
                    switch evalPolicyError!._code {
                    case LAError.Code.systemCancel.rawValue:
                        LocalString._authentication_was_cancelled_by_the_system.alertToast()
                    case LAError.Code.userCancel.rawValue:
                        PMLog.D("Authentication was cancelled by the user")
                    case LAError.Code.userFallback.rawValue:
                        PMLog.D("User selected to enter custom password")
                    default:
                        PMLog.D("Authentication failed")
                        LocalString._authentication_failed.alertToast()
                    }
                    return
                }
                self.signInIfRememberedCredentials(onSuccess: afterSignIn)
                afterBioAuthPassed()
            }
        }
    }
    
    internal func signInIfRememberedCredentials(onSuccess: ()->Void) {
        if sharedUserDataService.isUserCredentialStored {
            userCachedStatus.lockedApp = false
            sharedUserDataService.isSignedIn = true
        
            self.loadContent(requestMailboxPassword: onSuccess)
        } else {
            self.clean()
        }
    }
    
    private func loadContent(requestMailboxPassword: ()->Void) {
        if sharedUserDataService.isMailboxPasswordStored {
            UserTempCachedStatus.clearFromKeychain()
            userCachedStatus.pinFailedCount = 0
            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationDefined.didSignIn), object: nil)
            (UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
            self.loadContactsAfterInstall()
        } else {
            requestMailboxPassword()
        }
    }
    
    internal func clean() {
        UserTempCachedStatus.backup()
        sharedUserDataService.signOut(true)
        userCachedStatus.signOut()
        sharedMessageDataService.launchCleanUpIfNeeded()
    }
    
    private func loadContactsAfterInstall() {
        ServicePlanDataService.shared.updateCurrentSubscription()
        sharedUserDataService.fetchUserInfo().done { _ in }.catch { _ in }
        
        //TODO:: here need to be changed
        sharedContactDataService.fetchContacts { (contacts, error) in
            if error != nil {
                PMLog.D("\(String(describing: error))")
            } else {
                PMLog.D("Contacts count: \(contacts!.count)")
            }
        }
    }
    
    internal func mailboxPassword(from cleartextPassword: String) -> String {
        var mailboxPassword = cleartextPassword
        if let keysalt = AuthCredential.getKeySalt(), !keysalt.isEmpty {
            let keysalt_byte: Data = keysalt.decodeBase64()
            mailboxPassword = PasswordUtils.getMailboxPassword(cleartextPassword, salt: keysalt_byte)
        }
        return mailboxPassword
    }
    
    internal func decryptPassword(_ mailboxPassword: String,
                         onError: @escaping (NSError)->Void)
    {
        let isRemembered = true
        guard sharedUserDataService.isMailboxPasswordValid(mailboxPassword, privateKey: AuthCredential.getPrivateKey()) else {
            onError(NSError.init(domain: "", code: 0, localizedDescription: LocalString._the_mailbox_password_is_incorrect))
            return
        }
        
        guard !sharedUserDataService.isSet else {
            sharedUserDataService.setMailboxPassword(mailboxPassword, keysalt: nil, isRemembered: isRemembered)
            (UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
            return
        }
    
        do {
            try AuthCredential.setupToken(mailboxPassword, isRememberMailbox: isRemembered)
        } catch let ex as NSError {
            onError(ex)
        }
        
        sharedLabelsDataService.fetchLabels()
        ServicePlanDataService.shared.updateCurrentSubscription()
        sharedUserDataService.fetchUserInfo().done(on: .main) { info in
            guard let info = info else {
                onError(NSError.unknowError())
                return
            }
        
            guard info.delinquent < 3 else {
                onError(NSError.init(domain: "", code: 0, localizedDescription: LocalString._general_account_disabled_non_payment))
                return
            }
        
            userCachedStatus.pinFailedCount = 0;
            sharedUserDataService.setMailboxPassword(mailboxPassword, keysalt: nil, isRemembered: isRemembered)
            UserTempCachedStatus.restore()
            self.loadContent(requestMailboxPassword: { })
            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationDefined.didSignIn), object: nil)
        }.catch(on: .main) { (error) in
            fatalError() // FIXME: is this possible at all?
        }
    }
    
}
#endif
