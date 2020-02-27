//
//  KeychainWrapper.swift
//  ProtonMail - Created on 7/17/17.
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
#if canImport(PMKeymaker)
    // Keymaker framework is not linked with PushService to keep lower memory footprint
    // Keychain class is a member of PushService target alone
    import PMKeymaker
#endif

final class KeychainWrapper: Keychain {
    
    public static var keychain = KeychainWrapper()
    
    init() {
        #if Enterprise
            let prefix = "6UN54H93QT."
            let group = prefix + "com.protonmail.protonmail"
            let service = "com.protonmail"
        #else
            let prefix = "2SB5Z68H26."
            let group = prefix + "ch.protonmail.protonmail"
            let service = "ch.protonmail"
        #endif
        
        super.init(service: service, accessGroup: group)
    }
}
