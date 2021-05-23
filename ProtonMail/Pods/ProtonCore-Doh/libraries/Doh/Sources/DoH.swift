//
//  DoH.swift
//  Created by ProtonMail on 2/24/20.
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

struct RuntimeError: Error {
    let message: String
    init(_ message: String) {
        self.message = message
    }
    public var localizedDescription: String {
        return message
    }
}

struct DNSCache {
    let primary: Bool
    let dns: DNS
    let lastTimeout: Double
    var retry: Int
}

public enum DoHStatus {
    case on
    case off
    case auto // mix don't know yet
}

/// server configuation
public protocol ServerConfig {

    /// api host, the Doh query host  -- if you don't want to use doh, set this value to empty or set enableDoh = faluse
    var apiHost: String { get }

    /// enable doh or not default is True. if set to false will ignore apiHost value only use default host  -- if you don't want to use doh, set this value to faluse or set  or apiHost to empty
    var enableDoh: Bool { get }

    /// default host -- protonmail server url
    var defaultHost: String { get }

    /// default host path -- server url path for example: /api
    var defaultPath: String { get }

    /// captcha response host
    var captchaHost: String { get }

    // default signup domain for this server url
    var signupDomain: String { get }

    /// debug mode vars
    var debugMode: Bool { get }
    var blockList: [String: Int] { get }
}

public extension ServerConfig {
    var defaultPath: String {
        return ""
    }

    var debugMode: Bool {
        return false
    }

    var blockList: [String: Int] {
        return [String: Int]()
    }

    var enableDoh: Bool {
        return true
    }
}

protocol DoHInterface {
    func getHostUrl() -> String
    func getCaptchaHostUrl() -> String
    func handleError(host: String, error: Error?) -> Bool
    func clearAll()
    func codeCheck(code: Int) -> Bool
}

open class DoH: DoHInterface {

    public var status: DoHStatus = .off
    private var caches: [String: [DNSCache]] = [:]
    private var providers: [DoHProviderPublic] = []

    internal var mutex = pthread_mutex_t()
    internal var hostUrlMutex = pthread_mutex_t()

    public var debugBlock: [String: Bool] = [:]

    public func getHostUrl() -> String {
        pthread_mutex_lock(&self.hostUrlMutex)
        defer {
            pthread_mutex_unlock(&self.hostUrlMutex)
        }
        let config = self as! ServerConfig
        let defaultUrl = config.defaultHost + config.defaultPath

        guard config.enableDoh else {
            return defaultUrl
        }

        guard !config.apiHost.isEmpty else {
            return defaultUrl
        }

        switch status {
        case .on, .auto:
            if let found = self.cache(get: config.apiHost) {
                let newurl = URL(string: config.defaultHost)!
                let host = newurl.host
                let hostUrl = newurl.absoluteString.replacingOccurrences(of: host!, with: found.dns.url)
                return hostUrl + config.defaultPath
            }
            /// block call or call back call
            fetchAll(host: config.apiHost) // this is sync call

            if let found = self.cache(get: config.apiHost) {
                let newurl = URL(string: config.defaultHost)!
                let host = newurl.host
                let hostUrl = newurl.absoluteString.replacingOccurrences(of: host!, with: found.dns.url)
                return hostUrl + config.defaultPath
            }
        case .off:
            break
        }
        return defaultUrl
    }

    public func getCaptchaHostUrl() -> String {
        let config = self as! ServerConfig
        return config.captchaHost
    }

    public func getSignUpString() -> String {
        let config = self as! ServerConfig
        return config.signupDomain
    }

    func fetchAll(host: String) {
        // doing google for now. will add others
        if let dns = Google().fetch(sync: host) {
            self.cache(set: host, dnsList: dns)
        }

        if let dns = Quad9().fetch(sync: host) {
            self.cache(set: host, dnsList: dns)
        }
        var tmp = self.caches[host] ?? []
        for index in tmp.indices {
            tmp[index].retry = 0
        }
        self.caches[host] = tmp
    }

    public init() throws {
        pthread_mutex_init(&mutex, nil)
        pthread_mutex_init(&hostUrlMutex, nil)
        guard let config = self as? ServerConfig else {
            throw RuntimeError("Class didn't extend DoHConfig")
        }

        pthread_mutex_lock(&self.mutex)
        defer { pthread_mutex_unlock(&self.mutex) }

        var tmp = self.caches[config.defaultHost] ?? []
        let newurl = URL(string: config.defaultHost)!
        let host = newurl.host!
        let dns = DNS(url: host, ttl: 0)
        let cache = DNSCache(primary: true, dns: dns, lastTimeout: 0, retry: 0)
        tmp.append(cache)
        self.caches[config.apiHost] = tmp
    }

    func cache(get host: String) -> DNSCache? {
        pthread_mutex_lock(&self.mutex)
        defer { pthread_mutex_unlock(&self.mutex) }

        guard var found = self.caches[host] else {
            return nil
        }

        found = found.filter { (cache) -> Bool in
            return cache.primary == true || cache.retry < 1
        }
        self.caches[host] = found

        guard let first = found.first else {
            return nil
        }

        if first.lastTimeout > 0 && first.lastTimeout <= Date().timeIntervalSince1970 {
            if first.primary == false {
                found.removeFirst()
            }
            found.sort { (left, right) -> Bool in
                if left.retry > right.retry {
                    return true
                }
                return false
            }
            self.caches[host] = found
            return found.first
        }

        if first.retry > 0 && found.count > 1 {
            if first.primary == false && first.retry >= 10 {
                found.removeFirst()
            }
            found.sort { (left, right) -> Bool in
                if left.retry > right.retry {
                    return false
                }
                return true
            }

            self.caches[host] = found
            return found.first
        }

        if first.primary {
            if first.retry > 0 && found.count == 1 {
                return nil
            }
        }

        return found.first
    }

    func cache(set host: String, dns: DNS) {
        pthread_mutex_lock(&self.mutex)
        defer { pthread_mutex_unlock(&self.mutex) }

        let timeout = Date().timeIntervalSince1970 + Double(dns.ttl) * 1000
        let cache = DNSCache(primary: false, dns: dns, lastTimeout: timeout, retry: 0)
        var tmp = self.caches[host] ?? []
        tmp.append(cache)
        self.caches[host] = tmp
    }

    func cache(set host: String, dnsList: [DNS]) {
        pthread_mutex_lock(&self.mutex)
        defer { pthread_mutex_unlock(&self.mutex) }

        for dns in dnsList {
            let timeout = Date().timeIntervalSince1970 + Double(dns.ttl) * 1000
            let cache = DNSCache(primary: false, dns: dns, lastTimeout: timeout, retry: 0)
            var tmp = self.caches[host] ?? []
            tmp.append(cache)
            self.caches[host] = tmp
        }
    }

    func cache(clear host: String) {

    }

    public func clearAll() {
        pthread_mutex_lock(&self.mutex)
        defer { pthread_mutex_unlock(&self.mutex) }

        let config = self as! ServerConfig
        var tmp: [DNSCache] = []
        let newurl = URL(string: config.defaultHost)!
        let host = newurl.host!
        let dns = DNS(url: host, ttl: 0)
        let cache = DNSCache(primary: true, dns: dns, lastTimeout: 0, retry: 0)
        tmp.append(cache)
        self.caches[config.apiHost] = tmp
    }

    var globalCounter = 0
    var firstTime = 0
    public func handleError(host: String, error: Error?) -> Bool {

        guard status != .off else {
            return false
        }

        guard let config = self as? ServerConfig else {
            return false
        }

        guard config.debugMode == false else {
            return self.debugModeLogic(host: host)
        }

        guard let error = error as NSError? else {
            return false
        }
        guard let newurl = URL(string: host) else {
            return false
        }
        guard let host = newurl.host else {
            return false
        }

        let code = error.code

        guard self.codeCheck(code: code) else {
            return false
        }

        pthread_mutex_lock(&self.mutex)
        defer { pthread_mutex_unlock(&self.mutex) }

        guard var found = self.caches[config.apiHost] else {
            return false
        }

        for index in 0 ..< found.count {
            let item = found[index]
            if item.dns.url == host {
                found[index].retry += 1
            }
        }
        self.caches[config.apiHost] = found

        // loop and if all tried // should only loop found
        for (_, value) in self.caches {
            for val in value where val.retry < 1 {
                return true
            }
        }

        // temp workaround
        if status != .off && found.count == 1 && firstTime == 0 {
            firstTime += 1
            return true
        }

        return false
    }

    func debugModeLogic(host: String) -> Bool {
        guard let config = self as? ServerConfig else {
            return false
        }

        guard let newurl = URL(string: host) else {
            return false
        }
        guard let host = newurl.host else {
            return false
        }

        guard let foundCode = config.blockList[host] else {
            return false
        }

        let code = foundCode

        guard self.codeCheck(code: code) else {
            return false
        }

        pthread_mutex_lock(&self.mutex)
        defer { pthread_mutex_unlock(&self.mutex) }

        globalCounter += 1
        guard globalCounter % 2 == 0 else {
            return false
        }

        guard var found = self.caches[config.apiHost] else {
            return false
        }

        for index in 0 ..< found.count {
            let item = found[index]
            if item.dns.url == host {
                found[index].retry += 1
            }
        }
        self.caches[config.apiHost] = found

        // loop and if all tried
        for (_, value) in self.caches {
            for val in value where val.retry < 1 {
                return true
            }
        }

        return false
    }

    public func codeCheck(code: Int) -> Bool {
        guard code == NSURLErrorTimedOut ||
            code == NSURLErrorCannotConnectToHost ||
            code == NSURLErrorCannotFindHost ||
            code == NSURLErrorDNSLookupFailed ||
            code == -1200 ||
            code == 451 ||
            code == 310 ||
//            code == -1004 ||  // only for testing
            code == -1005 // only for testing
            else {
                return false
        }

        return true
    }
}

protocol test {

}
