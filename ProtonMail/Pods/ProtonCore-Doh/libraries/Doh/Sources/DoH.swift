//
//  DoH.swift
//  ProtonCore-Doh - Created on 2/24/20.
//
//  Copyright (c) 2019 Proton Technologies AG
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
import ProtonCore_Log

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
    let dns: DNS
    let fetchTime: Double
}

public enum DoHStatus {
    case on
    case off
    case forceAlternativeRouting
    @available(*, deprecated, renamed: "on")
    case auto // mix don't know yet
}

/// server configuation
public protocol ServerConfig {

    /// api host, the Doh query host  -- if you don't want to use doh, set enableDoh = false
    var apiHost: String { get }

    /// enable doh or not default is True. if you don't want to use doh, set this value to false
    var enableDoh: Bool { get }

    /// default host -- protonmail server url
    var defaultHost: String { get }

    /// default host path -- server url path for example: /api
    var defaultPath: String { get }

    /// captcha response host
    var captchaHost: String { get }
    var humanVerificationV3Host: String { get }
    
    // account host
    var accountHost: String { get }

    // default signup domain for this server url
    var signupDomain: String { get }

    /// debug mode vars
    var debugMode: Bool { get }
    var blockList: [String: Int] { get }
    
    /// the doh provider timeout  the default value is 5s
    var timeout: TimeInterval { get }
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
    
    var timeout: TimeInterval {
        return 20
    }
}

public protocol DoHInterface {

    @available(*, deprecated, message: "Please use getCurrentlyUsedHostUrl() in places you want to synchronously get the host url. Use handleErrorResolvingProxyDomainIfNeeded(host:error:completion:) in places that you handle the errors that should result in switching to proxy domain")
    func getHostUrl() -> String
    func getCurrentlyUsedHostUrl() -> String
    
    var isCurrentlyUsingProxyDomain: Bool { get }
    
    @available(*, deprecated, message: "Please use handleErrorResolvingProxyDomainIfNeeded(host:error:completion:)")
    func handleError(host: String, error: Error?) -> Bool
    func handleErrorResolvingProxyDomainIfNeeded(
        host: String, error: Error?, callCompletionBlockOn: DoHWorkExecutor?, completion: @escaping (Bool) -> Void
    )
    
    @available(*, deprecated, renamed: "clearCache")
    func clearAll()
    func clearCache()
    
    func getCaptchaHostUrl() -> String
    func getHumanVerificationV3Host() -> String
    func getAccountHost() -> String
    func getHumanVerificationV3Headers() -> [String: String]
    func getAccountHeaders() -> [String: String]
    func codeCheck(code: Int) -> Bool
}

public protocol DoHWorkExecutor {
    func execute(work: @escaping () -> Void)
}

extension DispatchQueue: DoHWorkExecutor {
    public func execute(work: @escaping () -> Void) {
        self.async { work() }
    }
}

open class DoH: DoHInterface {

    public var status: DoHStatus = .off
    private var proxyDomainsAreCurrentlyResolved = false
    
    private var caches: [DNSCache] = []
    private var providers: [DoHProviderPublic] = []
    
    private let domainResolvingExecutor: DoHWorkExecutor
    private let networkingEngine: DoHNetworkingEngine
    private let currentTimeProvider: () -> Date
    
    var config: DoH & ServerConfig {
        guard let config = self as? DoH & ServerConfig else {
            fatalError("DoH subclass must also conform to ServerConfig")
        }
        return config
    }

    internal var mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
    
    // MARK: - Initialization and deinitialization
    
    public init(networkingEngine: DoHNetworkingEngine = URLSession.shared,
                executor: DoHWorkExecutor = DispatchQueue(label: "ch.proton.core.ios.doh", qos: .userInitiated),
                currentTimeProvider: @escaping () -> Date = Date.init) {
        self.networkingEngine = networkingEngine
        self.domainResolvingExecutor = executor
        self.currentTimeProvider = currentTimeProvider
        pthread_mutex_init(mutex, nil)
    }
    
    deinit {
        pthread_mutex_destroy(mutex)
        self.mutex.deinitialize(count: 1)
        self.mutex.deallocate()
    }
    
    // MARK: - Accessing host url
    
    /// Returns the currently used host url. This means:
    /// * if DoH is not enabled or its status is .off or the apiHost is not empty, it will return the constants from ServerConfig
    /// * if DoH is enabled and its status is .on or .auto and the apiHost is not empty:
    ///     * if there's a proxy domain available in cache, it will return the proxy domain url
    ///     * otherwise it will return the constants from ServerConfig
    /// By proxy domain being available I mean proxy domain being already fetched and cached,
    /// and not removed from cache after connection failure or time limit.
    /// - Returns: currently used host url string
    public func getCurrentlyUsedHostUrl() -> String {
        getCurrentlyUsedHost() + config.defaultPath
    }
    
    private func getCurrentlyUsedHost() -> String {
        guard doHProxyDomainsMechanismIsActive() else {
            return getDefaultHost()
        }
        guard let hostUrlToUse = fetchCurrentlyUsedHostUrlFromCacheUpdatingIfNeeded() else {
            return getDefaultHost()
        }
        return hostUrl(config, hostUrlToUse)
    }
    
    @available(*, deprecated, message: "Please use getCurrentlyUsedHostUrl() instead")
    public func getHostUrl() -> String {
        getCurrentlyUsedHostUrl()
    }
    
    private func doHProxyDomainsMechanismIsActive() -> Bool {
        status != .off && config.enableDoh && !config.apiHost.isEmpty
    }
    
    private func getDefaultHost() -> String {
        config.defaultHost
    }

    private func hostUrl(_ config: ServerConfig, _ found: DNSCache) -> String {
        let newurl = URL(string: config.defaultHost)!
        let host = newurl.host
        let hostUrl = newurl.absoluteString.replacingOccurrences(of: host!, with: found.dns.url)
        return hostUrl
    }

    public func getCaptchaHostUrl() -> String {
        guard doHProxyDomainsMechanismIsActive() else { return config.captchaHost }
        guard let defaultUrl = URL(string: config.defaultHost)?.host else { return config.captchaHost }
        guard config.captchaHost.contains(defaultUrl) else { return config.captchaHost }
        guard let currentUrl = fetchCurrentlyUsedHostUrlFromCacheUpdatingIfNeeded()?.dns.url else { return config.captchaHost }
        return config.captchaHost.replacingOccurrences(of: defaultUrl, with: currentUrl)
    }
    
    public func getHumanVerificationV3Host() -> String {
        guard let proxyDomain = currentlyUsedProxyDomain() else { return config.humanVerificationV3Host }
        return proxyDomain
    }
    
    public func getHumanVerificationV3Headers() -> [String: String] {
        guard isCurrentlyUsingProxyDomain, let host = URL(string: config.humanVerificationV3Host)?.host else { return [:] }
        return ["X-PM-DoH-Host": host]
    }
    
    public func getAccountHost() -> String {
        guard let proxyDomain = currentlyUsedProxyDomain() else { return config.accountHost }
        return proxyDomain
    }
    
    public func getAccountHeaders() -> [String: String] {
        guard isCurrentlyUsingProxyDomain, let host = URL(string: config.accountHost)?.host else { return [:] }
        return ["X-PM-DoH-Host": host]
    }
    
    public var isCurrentlyUsingProxyDomain: Bool {
        currentlyUsedProxyDomain() != nil
    }
    
    private func currentlyUsedProxyDomain() -> String? {
        guard doHProxyDomainsMechanismIsActive() else { return nil }
        let currentlyUsedHost = getCurrentlyUsedHost()
        guard currentlyUsedHost != getDefaultHost() else { return nil }
        return currentlyUsedHost
    }

    public func getSignUpString() -> String { config.signupDomain }
    
    // MARK: - Caching

    public func clearCache() {
        pthread_mutex_lock(mutex)
        defer { pthread_mutex_unlock(mutex) }
        
        self.caches = []
    }
    
    @available(*, deprecated, message: "Please use clearCache() instead")
    public func clearAll() {
        clearCache()
    }
    
    private func fetchCurrentlyUsedHostUrlFromCacheUpdatingIfNeeded() -> DNSCache? {
        pthread_mutex_lock(mutex)
        defer { pthread_mutex_unlock(mutex) }
        caches = caches.filter { $0.fetchTime + 24 * 60 * 60 > currentTimeProvider().timeIntervalSince1970 }
        return caches.first
    }
    
    private func isThereAnyDomainWorthRetryInCache() -> Bool {
        pthread_mutex_lock(mutex)
        defer { pthread_mutex_unlock(mutex) }
        
        return !caches.isEmpty
    }

    private func populateCache(dnsList: [DNS]) {
        pthread_mutex_lock(mutex)
        defer { pthread_mutex_unlock(mutex) }
        
        for dns in dnsList.shuffled() {
            let dnsCache = DNSCache(dns: dns, fetchTime: currentTimeProvider().timeIntervalSince1970)
            if let indexOfAlreadyExistingDNS = caches.firstIndex(where: { $0.dns == dns }) {
                caches[indexOfAlreadyExistingDNS] = dnsCache
            } else {
                caches.append(dnsCache)
            }
        }
    }
    
    private func removeFailedDomainFromCache(host: String) {
        pthread_mutex_lock(mutex)
        defer { pthread_mutex_unlock(mutex) }
        
        // remove the dns cache that failed
        caches = caches.filter { $0.dns.url != host }
    }
    
    // MARK: - Handling error
    
    /// Checks if the error means it is worth retrying using the proxy domain.
    /// - Parameters:
    ///   - host: The host url of the request which possible error should be checked
    ///   - error: The error (if any) returned from the request
    ///   - callCompletionBlockOn: Executor used to call completion block on
    ///   - completion: Completion block parameter (Bool) indicates whether the request should be retried.
    public func handleErrorResolvingProxyDomainIfNeeded(
        host: String, error: Error?,
        callCompletionBlockOn possibleCompletionBlock: DoHWorkExecutor? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        
        let callCompletionBlockOn = possibleCompletionBlock ?? DispatchQueue.main
        guard errorShouldResultInTryingProxyDomain(host: host, error: error),
              let failedHost = URL(string: host)?.host,
              let defaultHost = URL(string: config.defaultHost)?.host else {
            callCompletionBlockOn.execute { completion(false) }
            return
        }
        
        if failedHost == defaultHost {
            handlePrimaryHostFailure(callCompletionBlockOn: callCompletionBlockOn, completion: completion)
            
        } else if let accountHost = URL(string: config.accountHost)?.host, failedHost == accountHost {
            handlePrimaryHostFailure(callCompletionBlockOn: callCompletionBlockOn, completion: completion)
            
        } else if let hvV3Host = URL(string: config.humanVerificationV3Host)?.host, failedHost == hvV3Host {
            handlePrimaryHostFailure(callCompletionBlockOn: callCompletionBlockOn, completion: completion)
            
        } else {
            handleProxyDomainFailure(failedHost: failedHost,
                                     callCompletionBlockOn: callCompletionBlockOn,
                                     completion: completion)
            
        }
    }
    
    private func errorShouldResultInTryingProxyDomain(host: String, error: Error?) -> Bool {
        guard doHProxyDomainsMechanismIsActive() else { return false }

        guard config.debugMode == false else { return debugModeLogic(host: host) }

        guard let checkedHost = URL(string: host)?.host else { return false }
        
        if status == .forceAlternativeRouting, let defaultHost = URL(string: config.defaultHost)?.host, defaultHost == checkedHost {
            return true
        }

        guard let error = error, codeCheck(code: (error as NSError).code) else { return false }
        
        return true
    }
    
    public func codeCheck(code: Int) -> Bool {
        guard code == NSURLErrorTimedOut ||
                code == NSURLErrorCannotConnectToHost ||
                code == NSURLErrorCannotFindHost ||
                code == NSURLErrorDNSLookupFailed ||
                code == 3500 || // this is tls error
                code == -1200 ||
                code == 451 ||
                code == 310 ||
                code == -1017 || // this is when proxy return nil body
                //            code == -1004 ||  // only for testing
                code == -1005 // only for testing
        else {
            return false
        }
        
        return true
    }
    
    private func handlePrimaryHostFailure(callCompletionBlockOn: DoHWorkExecutor,
                                          completion: @escaping (Bool) -> Void) {
        guard isThereAnyDomainWorthRetryInCache() == false else {
            // the request to primary host failed, but proxy domain is available - should retry, proxy domain will be returned in getCurrentlyUsedHostUrl()
            callCompletionBlockOn.execute { completion(true) }
            return
        }
        
        // the request to primary host failed and no proxy domains are available — should try resolving the domains
        resolveProxyDomainHostUrl { [weak self] domainsWereResolved in
            
            guard let self = self else {
                callCompletionBlockOn.execute { completion(false) }
                return
            }
            
            // domains are not resolved, should not retry
            guard domainsWereResolved else {
                callCompletionBlockOn.execute { completion(false) }
                return
            }
            
            // if there is no retry-worthy domain after resolving, don't bother retrying
            guard self.isThereAnyDomainWorthRetryInCache() else {
                callCompletionBlockOn.execute { completion(false) }
                return
            }
            
            // if domains are resolved, should retry
            callCompletionBlockOn.execute { completion(true) }
        }
    }
    
    private func handleProxyDomainFailure(
        failedHost: String, callCompletionBlockOn: DoHWorkExecutor, completion: @escaping (Bool) -> Void
    ) {
        removeFailedDomainFromCache(host: failedHost)
        
        if isThereAnyDomainWorthRetryInCache() {
            // more domains are available — should retry
             callCompletionBlockOn.execute { completion(true) }
        } else {
            // no more proxy domains are available — should not retry
            callCompletionBlockOn.execute { completion(false) }
        }
    }
    
    @available(*, deprecated, message: "Please use handleErrorResolvingProxyDomainIfNeeded(host:error:completion:)")
    public func handleError(host: String, error: Error?) -> Bool {
        assert(Thread.isMainThread == false, "This is a blocking call, should never be called from the main thread")
        
        let semaphore = DispatchSemaphore(value: 0)
        var result: Bool = false
        handleErrorResolvingProxyDomainIfNeeded(host: host, error: error) { shouldRetry in
            result = shouldRetry
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    
    // MARK: - Resolving proxy domains
    
    private func resolveProxyDomainHostUrl(completion: @escaping (Bool) -> Void) {
        domainResolvingExecutor.execute { [weak self] in
            guard let self = self else { completion(false); return }
            
            guard self.isThereAnyDomainWorthRetryInCache() == false else {
                PMLog.debug("[DoH] Resolving proxy domain — succeeded before")
                completion(true)
                return
            }
            
            PMLog.debug("[DoH] Resolving proxy domain — fetching")
            // perform the proxy domain fetching. it should result in populating the cache
            self.fetchHostFromDNSProvidersUsingSynchronousBlockingCall(timeout: self.config.timeout)
            
            // try getting the domain from cache again
            guard self.isThereAnyDomainWorthRetryInCache() else {
                PMLog.debug("[DoH] Resolving proxy domain — failed")
                return completion(false)
            }
            
            PMLog.debug("[DoH] Resolving proxy domain — succeeded")
            completion(true)
        }
    }

    private func fetchHostFromDNSProvidersUsingSynchronousBlockingCall(timeout: TimeInterval) {
        assert(Thread.isMainThread == false, "This is a blocking call, should never be called from the main thread")
        
        let semaphore = DispatchSemaphore(value: 0)
        [Google(networkingEngine: networkingEngine), Quad9(networkingEngine: networkingEngine)]
            .map { (provider: DoHProviderInternal) in
                provider.fetch(host: config.apiHost, timeout: timeout) { [weak self] dns in
                    defer { semaphore.signal() }
                    guard let self = self, let dns = dns else { return }
                    self.populateCache(dnsList: dns)
                }
            }.forEach {
                semaphore.wait()
            }
    }
    
    // MARK: - Debug logic

    private var globalCounter = 0
    func debugModeLogic(host: String) -> Bool {
        guard let newurl = URL(string: host) else { return false }
        
        guard let host = newurl.host else { return false }

        guard let foundCode = config.blockList[host] else { return false }

        let code = foundCode

        guard codeCheck(code: code) else { return false }

        pthread_mutex_lock(mutex)
        defer { pthread_mutex_unlock(mutex) }

        globalCounter += 1
        guard globalCounter % 2 == 0 else { return false }
        
        caches = caches.filter { $0.dns.url != host }
        
        guard isThereAnyDomainWorthRetryInCache() else { return false }
        
        return true
    }
}
