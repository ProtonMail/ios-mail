//
//  UserAgent.swift
//  ProtonCore-Networking - Created on 5/22/20.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

public final class UserAgent {
    public static let `default` : UserAgent = UserAgent()
    
    #if DEBUG_CORE_INTERNALS
    public var initCount: Int = 0
    public var accessCount: Int = 0
    #endif
    
    private let cacheQueue = DispatchQueue(label: "ch.proton.core.networking.useragent")
    private var cachedUS: String?
    private init () { }
    
    // eg. Darwin/16.3.0
    internal func DarwinVersion() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        if let dv = String(bytes: Data(bytes: &sysinfo.release, count: Int(_SYS_NAMELEN)), encoding: .ascii) {
            let ndv = dv.trimmingCharacters(in: .controlCharacters)
            return "Darwin/\(ndv)"
        }
        return ""
    }
    // eg. CFNetwork/808.3
    internal func CFNetworkVersion() -> String {
        let dictionary = Bundle(identifier: "com.apple.CFNetwork")?.infoDictionary
        let version = dictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        return "CFNetwork/\(version)"
    }
    
    // eg. iOS/10_1
    private func deviceVersion() -> String {
#if canImport(UIKit)
        let currentDevice = UIDevice.current
        return "\(currentDevice.systemName)/\(currentDevice.systemVersion)"
#elseif canImport(AppKit)
        return "macOS/\(ProcessInfo.processInfo.operatingSystemVersionString)"
#else
        return ""
#endif
    }
    // eg. iPhone5,2
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
    // eg. MyApp/1
    private func appNameAndVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as? String ?? "Unknown"
        let name = dictionary["CFBundleName"] as? String ?? "Unknown"
        return "\(name)/\(version)"
    }
    
    /// Return the User agent string. the format requested by data team
    /// - Returns: UA string
    private func UAString() -> String {
        return "\(appNameAndVersion()) (\(deviceVersion()); \(deviceName()))"
    }
    
    public var ua: String? {
        cacheQueue.sync {
            if cachedUS == nil {
                #if DEBUG_CORE_INTERNALS
                initCount += 1
                #endif
                cachedUS = self.UAString()
            }
            
            #if DEBUG_CORE_INTERNALS
            accessCount += 1
            #endif
            return cachedUS
        }
    }
}
