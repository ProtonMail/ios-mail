//
//  UserAgent.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/19/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation



final class UserAgent {
    public static let `default` : UserAgent = UserAgent()
    
    private var cachedUS : String?
    private init () { }
    
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
        return "\(appNameAndVersion()) \(deviceName()) \(deviceVersion()) \(CFNetworkVersion()) \(DarwinVersion())"
    }
    
    var ua : String? {
        get {
            if cachedUS == nil {
                cachedUS = self.UAString()
            }
            return cachedUS
        }
    }
}
