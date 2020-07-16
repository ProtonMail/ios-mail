//
//  IntentHandler.swift
//  ProtonMail - Created on 27/11/2018.
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
    
import PMKeymaker
import Intents

@available(iOS 12.0, *)
class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        if intent is WipeMainKeyIntent {
            return WipeMainKeyIntentHandler()
        }
        
        assert(false, "Undefined intent")
        return self
    }
    
}

@available(iOS 12.0, *)
public class WipeMainKeyIntentHandler: NSObject, WipeMainKeyIntentHandling {
    
    public func handle(intent: WipeMainKeyIntent, completion: @escaping (WipeMainKeyIntentResponse) -> Void) {
        Keymaker(autolocker: nil, keychain: KeychainWrapper.keychain).wipeMainKey()
        PushNotificationDecryptor.wipeEncryptionKit()
        
        completion(WipeMainKeyIntentResponse(code: WipeMainKeyIntentResponseCode.success, userActivity: nil))
    }
}
