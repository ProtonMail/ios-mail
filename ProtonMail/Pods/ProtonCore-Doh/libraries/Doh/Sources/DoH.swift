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
import ProtonCore_Utilities

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

    /// default host -- proton mail server url
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

@available(*, deprecated, message: "Please use CompletionBlockExecutor from ProtonCore-Utilities")
public protocol DoHWorkExecutor {
    func execute(work: @escaping () -> Void)
}

@available(*, deprecated, message: "Please use CompletionBlockExecutor from ProtonCore-Utilities")
extension DispatchQueue: DoHWorkExecutor {
    public func execute(work: @escaping () -> Void) {
        self.async { work() }
    }
}

public protocol DoHInterface {

    @available(*, deprecated, message: "Please use getCurrentlyUsedHostUrl() in places you want to synchronously get the host url. Use handleErrorResolvingProxyDomainIfNeeded(host:error:completion:) in places that you handle the errors that should result in switching to proxy domain")
    func getHostUrl() -> String
    func getCurrentlyUsedHostUrl() -> String
    
    var isCurrentlyUsingProxyDomain: Bool { get }
    
    @available(*, deprecated, message: "Please use handleErrorResolvingProxyDomainIfNeeded(host:error:callCompletionBlockOn:completion:)")
    func handleError(host: String, error: Error?) -> Bool
    
    @available(*, deprecated, message: "Please use variant taking CompletionBlockExecutor from ProtonCore-Utilities: handleErrorResolvingProxyDomainIfNeeded(host:error:callCompletionBlockUsing:completion:)")
    func handleErrorResolvingProxyDomainIfNeeded(
        host: String, error: Error?, callCompletionBlockOn: DoHWorkExecutor?, completion: @escaping (Bool) -> Void
    )
    
    @available(*, deprecated, message: "Please use handleErrorResolvingProxyDomainIfNeeded(host:sessionId:error:callCompletionBlockUsing:completion:)")
    func handleErrorResolvingProxyDomainIfNeeded(
        host: String, error: Error?, callCompletionBlockUsing: CompletionBlockExecutor, completion: @escaping (Bool) -> Void
    )
    
    func handleErrorResolvingProxyDomainIfNeeded(
        host: String, sessionId: String?, error: Error?, callCompletionBlockUsing: CompletionBlockExecutor, completion: @escaping (Bool) -> Void
    )
    
    @available(*, deprecated, message: "Please use handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeeded(host:sessionId:response:error:callCompletionBlockUsing:completion:)")
    func handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeeded(host: String, response: URLResponse?, error: Error?, callCompletionBlockUsing: CompletionBlockExecutor, completion: @escaping (Bool) -> Void
    )
    
    // swiftlint:disable function_parameter_count
    func handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeeded(
        host: String, sessionId: String?, response: URLResponse?, error: Error?, callCompletionBlockUsing: CompletionBlockExecutor, completion: @escaping (Bool) -> Void
    )
    
    @available(*, deprecated, renamed: "clearCache")
    func clearAll()
    func clearCache()
    
    func getCaptchaHostUrl() -> String
    func getHumanVerificationV3Host() -> String
    func getAccountHost() -> String
    func getHumanVerificationV3Headers() -> [String: String]
    func getAccountHeaders() -> [String: String]
    
    @available(*, deprecated, message: "Please use errorIndicatesDoHSolvableProblem(error:) instead")
    func codeCheck(code: Int) -> Bool
    
    func errorIndicatesDoHSolvableProblem(error: Error?) -> Bool
}

open class DoH: DoHInterface {

    public var status: DoHStatus = .off
    private var proxyDomainsAreCurrentlyResolved = false
    
    private var caches: [DNSCache] = []
    private var providers: [DoHProviderPublic] = []
    
    private let domainResolvingExecutor: CompletionBlockExecutor
    private let networkingEngine: DoHNetworkingEngine
    private let currentTimeProvider: () -> Date
    
    private var cookiesSynchronizer: DoHCookieSynchronizer?
    
    var config: DoH & ServerConfig {
        guard let config = self as? DoH & ServerConfig else {
            fatalError("DoH subclass must also conform to ServerConfig")
        }
        return config
    }

    internal let cacheQueue = DispatchQueue(label: "ch.proton.core.doh.caches")
    
    // MARK: - Initialization and deinitialization
    
    public init(
        networkingEngine: DoHNetworkingEngine = URLSession.shared,
        executor: CompletionBlockExecutor = .asyncExecutor(dispatchQueue: .init(
            label: "ch.proton.core.ios.doh",
            qos: .userInitiated
        )),
        currentTimeProvider: @escaping () -> Date = Date.init
    ) {
        self.networkingEngine = networkingEngine
        self.domainResolvingExecutor = executor
        self.currentTimeProvider = currentTimeProvider
    }
    
    public func setUpCookieSynchronization(storage: HTTPCookieStorage?) {
        cookiesSynchronizer = storage.map { DoHCookieSynchronizer(cookieStorage: $0, doh: self) }
    }
    
    public func synchronizeCookies(with response: URLResponse?) {
        guard let synchronizer = cookiesSynchronizer else { return }
        guard let response = response, let httpResponse = response as? HTTPURLResponse else { return }
        guard let headers = httpResponse.allHeaderFields as? [String: String] else { return }
        synchronizer.synchronizeCookies(with: headers)
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
    open func getCurrentlyUsedHostUrl() -> String {
        getCurrentlyUsedHost() + config.defaultPath
    }
    
    private func getCurrentlyUsedHost() -> String {
        guard doHProxyDomainsMechanismIsActive() else {
            return getDefaultHost()
        }
        guard let hostUrlToUse = fetchCurrentlyUsedHostUrlFromCacheUpdatingIfNeeded() else {
            return getDefaultHost()
        }
        return hostUrl(for: hostUrlToUse.dns.url)
    }
    
    @available(*, deprecated, message: "Please use getCurrentlyUsedHostUrl() instead")
    public func getHostUrl() -> String {
        getCurrentlyUsedHostUrl()
    }
    
    private func doHProxyDomainsMechanismIsActive() -> Bool {
        status != .off && config.enableDoh && !config.apiHost.isEmpty
    }
    
    func getDefaultHost() -> String {
        config.defaultHost
    }

    func hostUrl(for proxyDomain: String) -> String {
        let newurl = URL(string: config.defaultHost)!
        let host = newurl.host!
        let hostUrl = newurl.absoluteString.replacingOccurrences(of: host, with: proxyDomain)
        return hostUrl
    }

    open func getCaptchaHostUrl() -> String {
        guard doHProxyDomainsMechanismIsActive() else { return config.captchaHost }
        guard let defaultUrl = URL(string: config.defaultHost)?.host else { return config.captchaHost }
        guard config.captchaHost.contains(defaultUrl) else { return config.captchaHost }
        guard let currentUrl = fetchCurrentlyUsedHostUrlFromCacheUpdatingIfNeeded()?.dns.url else { return config.captchaHost }
        return config.captchaHost.replacingOccurrences(of: defaultUrl, with: currentUrl)
    }
    
    open func getHumanVerificationV3Host() -> String {
        guard var proxyDomain = currentlyUsedProxyDomain() else { return config.humanVerificationV3Host }
        for (custom, original) in AlternativeRoutingRequestInterceptor.schemeMapping {
            proxyDomain = proxyDomain.replacingOccurrences(of: original, with: custom)
        }
        return proxyDomain
    }
    
    open func getHumanVerificationV3Headers() -> [String: String] {
        guard isCurrentlyUsingProxyDomain, let host = URL(string: config.humanVerificationV3Host)?.host else { return [:] }
        return ["X-PM-DoH-Host": host]
    }
    
    open func getAccountHost() -> String {
        guard var proxyDomain = currentlyUsedProxyDomain() else { return config.accountHost }
        for (custom, original) in AlternativeRoutingRequestInterceptor.schemeMapping {
            proxyDomain = proxyDomain.replacingOccurrences(of: original, with: custom)
        }
        return proxyDomain
    }
    
    open func getAccountHeaders() -> [String: String] {
        guard isCurrentlyUsingProxyDomain, let host = URL(string: config.accountHost)?.host else { return [:] }
        return ["X-PM-DoH-Host": host]
    }
    
    open var isCurrentlyUsingProxyDomain: Bool {
        currentlyUsedProxyDomain() != nil
    }
    
    private func currentlyUsedProxyDomain() -> String? {
        guard doHProxyDomainsMechanismIsActive() else { return nil }
        let currentlyUsedHost = getCurrentlyUsedHost()
        guard currentlyUsedHost != getDefaultHost() else { return nil }
        return currentlyUsedHost
    }

    open func getSignUpString() -> String { config.signupDomain }
    
    // MARK: - Caching

    open func clearCache() {
        cacheQueue.sync {
            self.caches = []
        }
    }
    
    @available(*, deprecated, message: "Please use clearCache() instead")
    public func clearAll() {
        clearCache()
    }
    
    private func fetchCurrentlyUsedHostUrlFromCacheUpdatingIfNeeded() -> DNSCache? {
        return cacheQueue.sync {
            caches = caches.filter { $0.fetchTime + 24 * 60 * 60 > currentTimeProvider().timeIntervalSince1970 }
            return caches.first
        }
    }
    
    func fetchAllCacheHostUrls() -> [String] {
        return cacheQueue.sync {
            caches = caches.filter { $0.fetchTime + 24 * 60 * 60 > currentTimeProvider().timeIntervalSince1970 }
            return caches.map { $0.dns.url }
        }
    }
    
    private func isThereAnyDomainWorthRetryInCache() -> Bool {
        return cacheQueue.sync {
            !caches.isEmpty
        }
    }

    private func populateCache(dnsList: [DNS]) {
        cacheQueue.sync {
            for dns in dnsList.shuffled() {
                let dnsCache = DNSCache(dns: dns, fetchTime: currentTimeProvider().timeIntervalSince1970)
                if let indexOfAlreadyExistingDNS = caches.firstIndex(where: { $0.dns == dns }) {
                    caches[indexOfAlreadyExistingDNS] = dnsCache
                } else {
                    caches.append(dnsCache)
                }
            }
        }
    }
    
    private func removeFailedDomainFromCache(host: String) {
        cacheQueue.sync {
            // remove the dns cache that failed
            caches = caches.filter { $0.dns.url != host }
        }
    }
    
    public func handleErrorResolvingProxyDomainIfNeeded(host: String, error: Error?, callCompletionBlockUsing: CompletionBlockExecutor, completion: @escaping (Bool) -> Void) {
        handleErrorResolvingProxyDomainIfNeeded(host: host, sessionId: nil, error: error, completion: completion)
    }
    
    // MARK: - Handling error
    
    /// Checks if the error means it is worth retrying using the proxy domain.
    /// - Parameters:
    ///   - host: The host url of the request which possible error should be checked
    ///   - sessionId: auth sessionId
    ///   - error: The error (if any) returned from the request
    ///   - callCompletionBlockOn: Executor used to call completion block on
    ///   - completion: Completion block parameter (Bool) indicates whether the request should be retried.
    open func handleErrorResolvingProxyDomainIfNeeded(
        host: String, sessionId: String?, error: Error?,
        callCompletionBlockUsing callCompletionBlockOn: CompletionBlockExecutor = .asyncMainExecutor,
        completion: @escaping (Bool) -> Void
    ) { 
        guard errorShouldResultInTryingProxyDomain(host: host, error: error),
              let failedHost = URL(string: host)?.host,
              let defaultHost = URL(string: config.defaultHost)?.host else {
            callCompletionBlockOn.execute { completion(false) }
            return
        }
        
        if failedHost == defaultHost {
            handlePrimaryHostFailure(sessionId: sessionId, callCompletionBlockOn: callCompletionBlockOn, completion: completion)
            
        } else if let accountHost = URL(string: config.accountHost)?.host, failedHost == accountHost {
            handlePrimaryHostFailure(sessionId: sessionId, callCompletionBlockOn: callCompletionBlockOn, completion: completion)
            
        } else if let hvV3Host = URL(string: config.humanVerificationV3Host)?.host, failedHost == hvV3Host {
            handlePrimaryHostFailure(sessionId: sessionId, callCompletionBlockOn: callCompletionBlockOn, completion: completion)
            
        } else {
            handleProxyDomainFailure(failedHost: failedHost,
                                     callCompletionBlockOn: callCompletionBlockOn,
                                     completion: completion)
            
        }
    }
    
    public func handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeeded(host: String, response: URLResponse?, error: Error?, callCompletionBlockUsing: CompletionBlockExecutor, completion: @escaping (Bool) -> Void) {
        handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeeded(host: host, sessionId: nil, response: response, error: error, callCompletionBlockUsing: callCompletionBlockUsing, completion: completion)
    }
    
    public func handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeeded(
        host: String, sessionId: String?, response: URLResponse?, error: Error?,
        callCompletionBlockUsing: CompletionBlockExecutor = .asyncMainExecutor,
        completion: @escaping (Bool) -> Void
    ) {
        handleErrorResolvingProxyDomainIfNeeded(host: host, sessionId: sessionId, error: error, callCompletionBlockUsing: callCompletionBlockUsing) { [weak self] in
            self?.synchronizeCookies(with: response)
            completion($0)
        }
    }
    
    private func errorShouldResultInTryingProxyDomain(host: String, error: Error?) -> Bool {
        guard doHProxyDomainsMechanismIsActive() else { return false }

        guard config.debugMode == false else { return debugModeLogic(host: host) }

        guard let checkedHost = URL(string: host)?.host else { return false }
        
        if status == .forceAlternativeRouting, let defaultHost = URL(string: config.defaultHost)?.host, defaultHost == checkedHost {
            return true
        }

        guard errorIndicatesDoHSolvableProblem(error: error) else { return false }
        
        return true
    }
    
    open func errorIndicatesDoHSolvableProblem(error: Error?) -> Bool {
        guard let error = error else { return false }
        return determineIfErrorCodeIndicatesDoHSolvableProblem((error as NSError).code)
    }
    
    @available(*, deprecated, message: "Please use errorIndicatesDoHSolvableProblem(error:) instead")
    public func codeCheck(code: Int) -> Bool {
        determineIfErrorCodeIndicatesDoHSolvableProblem(code)
    }
    
private func determineIfErrorCodeIndicatesDoHSolvableProblem(_ code: Int) -> Bool {
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
    
    private func handlePrimaryHostFailure(sessionId: String?, callCompletionBlockOn: CompletionBlockExecutor,
                                          completion: @escaping (Bool) -> Void) {
        guard isThereAnyDomainWorthRetryInCache() == false else {
            // the request to primary host failed, but proxy domain is available - should retry, proxy domain will be returned in getCurrentlyUsedHostUrl()
            callCompletionBlockOn.execute { completion(true) }
            return
        }
        
        // the request to primary host failed and no proxy domains are available — should try resolving the domains
        resolveProxyDomainHostUrl(sessionId: sessionId) { [weak self] domainsWereResolved in
            
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
        failedHost: String, callCompletionBlockOn: CompletionBlockExecutor, completion: @escaping (Bool) -> Void
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
        handleErrorResolvingProxyDomainIfNeeded(host: host, sessionId: nil, error: error) { shouldRetry in
            result = shouldRetry
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    
    @available(*, deprecated, message: "Please use variant taking CompletionBlockExecutor from ProtonCore-Utilities: handleErrorResolvingProxyDomainIfNeeded(host:error:callCompletionBlockUsing:completion:)")
    public func handleErrorResolvingProxyDomainIfNeeded(
        host: String, error: Error?, callCompletionBlockOn: DoHWorkExecutor?, completion: @escaping (Bool) -> Void
    ) {
        guard let callCompletionBlockOn = callCompletionBlockOn else {
            handleErrorResolvingProxyDomainIfNeeded(host: host, sessionId: nil, error: error, completion: completion)
            return
        }
        let executor = CompletionBlockExecutor(executionContext: callCompletionBlockOn.execute)
        handleErrorResolvingProxyDomainIfNeeded(host: host, sessionId: nil, error: error, callCompletionBlockUsing: executor, completion: completion)
    }
    
    // MARK: - Resolving proxy domains
    
    private func resolveProxyDomainHostUrl(sessionId: String?, completion: @escaping (Bool) -> Void) {
        domainResolvingExecutor.execute { [weak self] in
            guard let self = self else { completion(false); return }
            
            guard self.isThereAnyDomainWorthRetryInCache() == false else {
                PMLog.debug("[DoH] Resolving proxy domain — succeeded before")
                completion(true)
                return
            }
            
            PMLog.debug("[DoH] Resolving proxy domain — fetching")
            // perform the proxy domain fetching. it should result in populating the cache
            self.fetchHostFromDNSProvidersUsingSynchronousBlockingCall(sessionId: sessionId, timeout: self.config.timeout)
            
            // try getting the domain from cache again
            guard self.isThereAnyDomainWorthRetryInCache() else {
                PMLog.debug("[DoH] Resolving proxy domain — failed")
                return completion(false)
            }
            
            PMLog.debug("[DoH] Resolving proxy domain — succeeded")
            completion(true)
        }
    }

    private func fetchHostFromDNSProvidersUsingSynchronousBlockingCall(sessionId: String?, timeout: TimeInterval) {
        assert(Thread.isMainThread == false, "This is a blocking call, should never be called from the main thread")
        
        let semaphore = DispatchSemaphore(value: 0)
        [Google(networkingEngine: networkingEngine), Quad9(networkingEngine: networkingEngine)]
            .map { (provider: DoHProviderInternal) in
                provider.fetch(host: config.apiHost, sessionId: sessionId, timeout: timeout) { [weak self] dns in
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

        guard determineIfErrorCodeIndicatesDoHSolvableProblem(code) else { return false }

        return cacheQueue.sync {
            globalCounter += 1
            guard globalCounter % 2 == 0 else { return false }

            caches = caches.filter { $0.dns.url != host }

            guard isThereAnyDomainWorthRetryInCache() else { return false }

            return true
        }
    }
}
