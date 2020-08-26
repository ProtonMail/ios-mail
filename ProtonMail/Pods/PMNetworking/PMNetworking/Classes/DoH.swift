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
    let primary : Bool
    let dns : DNS
    let lastTimeout : Double
    var retry : Int
}

public enum DoHStatus {
    case on
    case off
    case auto //mix don't know yet
}


public protocol DoHConfig {
    var apiHost : String { get }
    var defaultHost : String { get }
    var defaultPath : String { get }
}

protocol DoHInterface {
    func getHostUrl() -> String
    func handleError(host: String, error: Error?)
    func clearAll()
    func codeCheck(code: Int) -> Bool
}

open class DoH : DoHInterface {
    
    public var status : DoHStatus = .off
    
    private var caches : [String: [DNSCache]] = [:]
    private var providers : [DoHProviderPublic] = []
    internal var mutex = pthread_mutex_t()
    
    public func getHostUrl() -> String {
        let config = self as! DoHConfig
        switch status {
        case .on, .auto:
            if let found = self.cache(get: config.apiHost) {
                print("Found from cache")
                let newurl = URL(string: config.defaultHost)!
                let host = newurl.host
                let hostUrl = newurl.absoluteString.replacingOccurrences(of: host!, with: found.dns.url)
                return hostUrl + config.defaultPath
            }
            
            //doing google for now. will add others
            if let dns = Google().fetch(sync: config.apiHost) {
                self.cache(set: config.apiHost, dns: dns)
                let url = dns.url
                let newurl = URL(string: config.defaultHost)!
                let host = newurl.host
                let hostUrl = newurl.absoluteString.replacingOccurrences(of: host!, with: url)
                return hostUrl + config.defaultPath
            }
        case .off:
            break
        }
        return config.defaultHost + config.defaultPath
    }
    
    public init() throws {
        pthread_mutex_init(&mutex, nil)
        guard let config = self as? DoHConfig else {
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
        
        if first.retry > 0 && found.count > 1{
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
    
    func cache(set host: String, dns : DNS) {
        pthread_mutex_lock(&self.mutex)
        defer { pthread_mutex_unlock(&self.mutex) }
        
        let timeout = Date().timeIntervalSince1970 + Double(dns.ttl) * 1000
        let cache = DNSCache(primary: false, dns: dns, lastTimeout: timeout, retry: 0)
        var tmp = self.caches[host] ?? []
        tmp.append(cache)
        self.caches[host] = tmp
    }
    
    func cache(clear host: String) {
        
    }
    
    public func clearAll() {
        
        pthread_mutex_lock(&self.mutex)
        defer { pthread_mutex_unlock(&self.mutex) }
        
        let config = self as! DoHConfig
        var tmp : [DNSCache] = []
        let newurl = URL(string: config.defaultHost)!
        let host = newurl.host!
        let dns = DNS(url: host, ttl: 0)
        let cache = DNSCache(primary: true, dns: dns, lastTimeout: 0, retry: 0)
        tmp.append(cache)
        self.caches[config.apiHost] = tmp
    }
    
    public func handleError(host: String, error: Error?) {
        guard let config = self as? DoHConfig else {
            return
        }
        guard let error = error as NSError? else {
            return
        }
        guard let newurl = URL(string: host) else {
            return
        }
        guard let host = newurl.host else {
            return
        }
        
        let code = error.code
        
        guard self.codeCheck(code: code) else {
            return
        }
        
        pthread_mutex_lock(&self.mutex)
        defer { pthread_mutex_unlock(&self.mutex) }
        
        guard var found = self.caches[config.apiHost] else {
            return
        }
        
        for i in 0 ..< found.count {
            let item = found[i]
            if item.dns.url == host {
                found[i].retry += 1
            }
        }
        self.caches[config.apiHost] = found
        
    }
    
    public func codeCheck(code: Int) -> Bool {
        guard code == NSURLErrorTimedOut ||
            code == NSURLErrorCannotConnectToHost ||
            code == NSURLErrorCannotFindHost ||
            code == NSURLErrorDNSLookupFailed ||
            code == -1200 ||
            code == 451 ||
            code == 310
            else {
                return false
        }
        
        return true
    }            
}

protocol test {
    
}
