//
//  PushNotificationDecryptor.swift
//  Proton Mail - Created on 06/11/2018.
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

import Foundation

/// Since push notifications are not stored in iOS internals for long, we do not care about these properties safety.
/// They are used for encryption of data-in-the-air and are changed at least per session.
/// On the other hand, they should be available to all of our extensions even when the app is locked.
final class PushNotificationDecryptor {

    enum Key {
        static let encryptionKit = "pushNotificationEncryptionKit"
    }

    @available(*, deprecated, message: "Old aproach to store encryption kits. Check `PushEncryptionKitSaver` instead.")
    static var saver = KeychainSaver<Set<PushSubscriptionSettings>>(key: Key.encryptionKit)
}
