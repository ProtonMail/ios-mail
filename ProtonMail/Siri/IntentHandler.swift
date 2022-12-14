//
//  IntentHandler.swift
//  Proton Mail - Created on 27/11/2018.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Intents
import ProtonCore_Keymaker

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
class WipeMainKeyIntentHandler: NSObject, WipeMainKeyIntentHandling {

    func handle(intent: WipeMainKeyIntent, completion: @escaping (WipeMainKeyIntentResponse) -> Void) {
        Keymaker(autolocker: nil, keychain: KeychainWrapper.keychain).wipeMainKey()
        PushNotificationDecryptor().wipeEncryptionKit()

        // Remove all items in UserDefault
        let userDefault = UserDefaults(suiteName: Constants.AppGroup)
        userDefault?.dictionaryRepresentation().keys.forEach({ key in
            userDefault?.removeObject(forKey: key)
        })
        removeCoreData()

        completion(WipeMainKeyIntentResponse(code: WipeMainKeyIntentResponseCode.success, userActivity: nil))
    }

    private func removeCoreData() {
        let dbUrl = FileManager.default.appGroupsDirectoryURL
            .appendingPathComponent("ProtonMail.sqlite")
        let dbShmUrl = FileManager.default.appGroupsDirectoryURL
            .appendingPathComponent("ProtonMail.sqlite-shm")
        let dbWalUrl = FileManager.default.appGroupsDirectoryURL
            .appendingPathComponent("ProtonMail.sqlite-wal")
        let urlsToBeRemoved = [dbUrl, dbShmUrl, dbWalUrl]
        urlsToBeRemoved.forEach { url in
            do {
                if FileManager.default.fileExists(atPath: url.absoluteString) {
                    try FileManager.default.removeItem(at: url)
                }
            } catch {
                SystemLogger.log(message: "Error deleting data store: \(String(describing: error))",
                                 category: .coreData)
            }
        }
    }
}
