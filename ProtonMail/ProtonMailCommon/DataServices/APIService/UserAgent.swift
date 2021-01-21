//
//  UserAgent.swift
//  ProtonMail
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

final class UserAgent {
    public static let `default` : UserAgent = UserAgent()
    private var mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
    private var cachedUS : String?
    private init () {
        // init lock
        mutex.initialize(to: pthread_mutex_t())
        pthread_mutex_init(mutex, nil)
    }
    
    //eg. Darwin/16.3.0
    private func DarwinVersion() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        if let dv = String(bytes: Data(bytes: &sysinfo.release, count: Int(_SYS_NAMELEN)), encoding: .ascii) {
            let ndv = dv.trimmingCharacters(in: .controlCharacters)
            return "Darwin/\(ndv)"
        }
        return ""
    }
    //eg. CFNetwork/808.3
    private func CFNetworkVersion() -> String {
        let dictionary = Bundle(identifier: "com.apple.CFNetwork")?.infoDictionary
        let version = dictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        return "CFNetwork/\(version)"
    }
    
    //eg. iOS/10_1
    private func deviceVersion() -> String {
        let currentDevice = UIDevice.current
        return "\(currentDevice.systemName)/\(currentDevice.systemVersion)"
    }
    //eg. iPhone5,2
    private func deviceName() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let data = Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN))
        if let dn = String(bytes: data, encoding: .ascii) {
            let ndn = dn.trimmingCharacters(in: .controlCharacters)
            return ndn
        }
        return "Unknown"
    }
    //eg. MyApp/1
    private func appNameAndVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as? String ?? "Unknown"
        let name = dictionary["CFBundleName"] as? String ?? "Unknown"
        return "\(name)/\(version)"
    }
    
    private func UAString() -> String {
        return "\(appNameAndVersion()) (\(deviceVersion()); \(deviceName()))"
    }
    
    var ua : String? {
        get {
            pthread_mutex_lock(self.mutex)
            if cachedUS == nil {
                cachedUS = self.UAString()
            }
            pthread_mutex_unlock(self.mutex)
            return cachedUS
        }
    }
}
