//
//  DoH.swift
//  ProtonCore-Doh - Created on 2/24/20.
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
import ProtonCore_Log
import ProtonCore_Utilities

open class DoH: DoHInterface {

    open var status: DoHStatus = .off
    private var proxyDomainsAreCurrentlyResolved = false
    
    private var caches: [ProductionHosts: [DNSCache]] = [:]
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
    
    open func setUpCookieSynchronization(storage: HTTPCookieStorage?) {
        cookiesSynchronizer = storage.map { DoHCookieSynchronizer(cookieStorage: $0, doh: self) }
    }
    
    open func synchronizeCookies(with response: URLResponse?) {
        guard let synchronizer = cookiesSynchronizer else { return }
        guard let response = response, let httpResponse = response as? HTTPURLResponse else { return }
        guard let headers = httpResponse.allHeaderFields as? [String: String] else { return }
        
        guard let responseHost = httpResponse.url?.host, let host = ProductionHosts(rawValue: responseHost) else  { return }
        
        synchronizer.synchronizeCookies(for: host, with: headers)
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
        getCurrentlyUsedUrl(defaultingTo: config.defaultHost) + config.defaultPath
        }
    
    private func getCurrentlyUsedUrl(defaultingTo defaultHost: String) -> String {
        guard doHProxyDomainsMechanismIsActive() else { return defaultHost }
        
        guard let productionHost = productionHostIfExists(for: defaultHost) else { return defaultHost }
        
        guard let proxyDomainDNSCache = fetchCurrentlyUsedUrlFromCacheUpdatingIfNeeded(for: productionHost) else { return defaultHost }
        
        return hostUrl(for: proxyDomainDNSCache.dns.host, proxying: productionHost)
    }
    
    @available(*, deprecated, message: "Please use getCurrentlyUsedHostUrl() instead")
    open func getHostUrl() -> String {
        getCurrentlyUsedHostUrl()
    }
    
    private func doHProxyDomainsMechanismIsActive() -> Bool {
        status != .off && config.enableDoh
    }
    
    private func productionHostIfExists(for host: String) -> ProductionHosts? {
        if let productionHost = ProductionHosts(rawValue: host) { return productionHost }
        if let host = URL(string: host)?.host, let productionHost = ProductionHosts(rawValue: host) { return productionHost }
        return nil
    }
    
    private func headersForUrl(defaultValue: String) -> [String: String] {
        let currentlyUsedHV3Url = getCurrentlyUsedUrl(defaultingTo: defaultValue)
        guard currentlyUsedHV3Url != defaultValue else { return [:] }
        guard let host = URL(string: defaultValue)?.host else { return [:] }
        return [DoHConstants.dohHostHeader: host]
    }
    
    func hostUrl(for proxyDomain: String, proxying host: ProductionHosts) -> String {
        let url = host.url
        let domain = host.rawValue
        let proxyUrl = url.absoluteString.replacingOccurrences(of: domain, with: proxyDomain)
        return proxyUrl
    }
    
    open func getCurrentlyUsedUrlHeaders() -> [String: String] {
        headersForUrl(defaultValue: config.defaultHost)
    }

    open func getCaptchaHostUrl() -> String {
        getCurrentlyUsedUrl(defaultingTo: config.captchaHost)
    }
    
    open func getCaptchaHeaders() -> [String: String] {
        headersForUrl(defaultValue: config.captchaHost)
    }
    
    open func getHumanVerificationV3Host() -> String {
        var currentlyUsedHV3Url = getCurrentlyUsedUrl(defaultingTo: config.humanVerificationV3Host)
        guard currentlyUsedHV3Url != config.humanVerificationV3Host else { return currentlyUsedHV3Url }
        
        for (custom, original) in AlternativeRoutingRequestInterceptor.schemeMapping {
            currentlyUsedHV3Url = currentlyUsedHV3Url.replacingOccurrences(of: original, with: custom)
        }
        return currentlyUsedHV3Url
    }
    
    open func getHumanVerificationV3Headers() -> [String: String] {
        headersForUrl(defaultValue: config.humanVerificationV3Host)
    }
    
    open func getAccountHost() -> String {
        var currentlyUsedAccountDeletionUrl = getCurrentlyUsedUrl(defaultingTo: config.accountHost)
        guard currentlyUsedAccountDeletionUrl != config.accountHost else { return currentlyUsedAccountDeletionUrl }
        
        for (custom, original) in AlternativeRoutingRequestInterceptor.schemeMapping {
            currentlyUsedAccountDeletionUrl = currentlyUsedAccountDeletionUrl.replacingOccurrences(of: original, with: custom)
        }
        return currentlyUsedAccountDeletionUrl
    }
    
    open func getAccountHeaders() -> [String: String] {
        headersForUrl(defaultValue: config.accountHost)
    }

    open func getSignUpString() -> String { config.signupDomain }
    
    // MARK: - Caching

    var isCurrentlyUsingProxyDomain: Bool {
        cacheQueue.sync {
            !caches.values.flatMap { $0 }.isEmpty
        }
    }
    
    open func clearCache() {
        cacheQueue.sync {
            self.caches = [:]
        }
    }
    
    @available(*, deprecated, message: "Please use clearCache() instead")
    open func clearAll() {
        clearCache()
    }
    
    private func fetchCurrentlyUsedUrlFromCacheUpdatingIfNeeded(for host: ProductionHosts) -> DNSCache? {
        return cacheQueue.sync {
            guard let dnsCaches = caches[host] else { return nil }
            caches[host] = dnsCaches.filter { $0.fetchTime + 24 * 60 * 60 > currentTimeProvider().timeIntervalSince1970 }
            return caches[host]?.first
        }
    }
    
    func fetchAllProxyDomainUrls(for host: ProductionHosts) -> [String] {
        return cacheQueue.sync {
            guard let dnsCaches = caches[host] else { return [] }
            caches[host] = dnsCaches.filter { $0.fetchTime + 24 * 60 * 60 > currentTimeProvider().timeIntervalSince1970 }
            return caches[host]?.map { $0.dns.host } ?? []
        }
    }
    
    private func productionHostForRequestHeaders(_ requestHeaders: [String: String]) -> ProductionHosts? {
        guard let dohHost = requestHeaders[DoHConstants.dohHostHeader] else { return nil }
        guard let productionHost = ProductionHosts(rawValue: dohHost) else { return nil }
        return productionHost
    }
    
    private func productionHostForPossibleProxyDomain(_ possibleProxyDomain: String) -> ProductionHosts? {
        return cacheQueue.sync {
            for (productionHost, dnsCaches) in caches {
                let proxyDomainFound = dnsCaches.contains { dnsCache in dnsCache.dns.host == possibleProxyDomain }
                if proxyDomainFound { return productionHost }
            }
            return nil
        }
    }
    
    private func isThereAnyProxyDomainWorthRetryInCache(for host: ProductionHosts) -> Bool {
        return cacheQueue.sync {
            guard let dnsCaches = caches[host] else { return false }
            return !dnsCaches.isEmpty
        }
    }
    
    private func populateCache(for host: ProductionHosts, with dnsList: [DNS]) {
        let fetchTime = currentTimeProvider().timeIntervalSince1970
        cacheQueue.sync {
            var dnsCaches: [DNSCache] = []
            for dns in dnsList.shuffled() {
                let dnsCache = DNSCache(dns: dns, fetchTime: fetchTime)
                if let indexOfAlreadyExistingDNS = dnsCaches.firstIndex(where: { $0.dns == dns }) {
                    dnsCaches[indexOfAlreadyExistingDNS] = dnsCache
                } else {
                    dnsCaches.append(dnsCache)
                }
            }
            caches[host] = dnsCaches
        }
    }
    
    private func removeFromCache(failedDomain: String, for host: ProductionHosts) {
        cacheQueue.sync {
            guard let dnsCaches = caches[host] else { return }
            // remove the dns cache that failed
            caches[host] = dnsCaches.filter { $0.dns.host != failedDomain }
        }
    }
    
    // MARK: - Handling error
    
    /// Checks if the error means it is worth retrying using the proxy domain.
    /// - Parameters:
    ///   - host: The host url of the request which possible error should be checked
    ///   - requestHeaders: The headers of the request
    ///   - sessionId: auth sessionId
    ///   - error: The error (if any) returned from the request
    ///   - callCompletionBlockOn: Executor used to call completion block on
    ///   - completion: Completion block parameter (Bool) indicates whether the request should be retried.
    open func handleErrorResolvingProxyDomainIfNeeded(
        host url: String, requestHeaders: [String: String], sessionId: String?, error: Error?,
        callCompletionBlockUsing callCompletionBlockOn: CompletionBlockExecutor = .asyncMainExecutor,
        completion: @escaping (Bool) -> Void
    ) { 
        
        guard let failedHost = URL(string: url)?.host else {
            callCompletionBlockOn.execute { completion(false) }
            return
        }
        
        guard errorShouldResultInTryingProxyDomain(failedHost: failedHost, error: error) else {
            callCompletionBlockOn.execute { completion(false) }
            return
        }
        
        if let productionHost = ProductionHosts(rawValue: failedHost) {
            
            handlePrimaryDomainFailure(for: productionHost, sessionId: sessionId, callCompletionBlockOn: callCompletionBlockOn, completion: completion)
            
        } else if let productionHost = productionHostForRequestHeaders(requestHeaders) ?? productionHostForPossibleProxyDomain(failedHost) {
            
            handleProxyDomainFailure(failedProxyDomain: failedHost, for: productionHost, callCompletionBlockOn: callCompletionBlockOn, completion: completion)
            
        } else {
            callCompletionBlockOn.execute { completion(false) }
        }
    }
    
    // swiftlint:disable function_parameter_count
    open func handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeeded(
        host: String, requestHeaders: [String: String], sessionId: String?, response: URLResponse?, error: Error?,
        callCompletionBlockUsing: CompletionBlockExecutor = .asyncMainExecutor,
        completion: @escaping (Bool) -> Void
    ) {
        handleErrorResolvingProxyDomainIfNeeded(host: host, requestHeaders: requestHeaders, sessionId: sessionId, error: error,
                                                callCompletionBlockUsing: callCompletionBlockUsing) { [weak self] in
            self?.synchronizeCookies(with: response)
            completion($0)
        }
    }
    
    private func errorShouldResultInTryingProxyDomain(failedHost: String, error: Error?) -> Bool {
        
        guard doHProxyDomainsMechanismIsActive() else { return false }

        if status == .forceAlternativeRouting, ProductionHosts(rawValue: failedHost) != nil { return true }

        guard errorIndicatesDoHSolvableProblem(error: error) else { return false }
        
        return true
    }
    
    open func errorIndicatesDoHSolvableProblem(error: Error?) -> Bool {
        guard let error = error else { return false }
        return determineIfErrorCodeIndicatesDoHSolvableProblem((error as NSError).code)
    }
    
    @available(*, deprecated, message: "Please use errorIndicatesDoHSolvableProblem(error:) instead")
    open func codeCheck(code: Int) -> Bool {
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
    
    private func handlePrimaryDomainFailure(
        for host: ProductionHosts, sessionId: String?, callCompletionBlockOn: CompletionBlockExecutor, completion: @escaping (Bool) -> Void
    ) {
        guard isThereAnyProxyDomainWorthRetryInCache(for: host) == false else {
            // the request to primary host failed, but proxy domain is available - should retry, proxy domain will be returned in getCurrentlyUsedHostUrl()
            callCompletionBlockOn.execute { completion(true) }
            return
        }
        
        // the request to primary host failed and no proxy domains are available — should try resolving the domains
        resolveProxyDomains(for: host, sessionId: sessionId) { [weak self] domainsWereResolved in
            
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
            guard self.isThereAnyProxyDomainWorthRetryInCache(for: host) else {
                callCompletionBlockOn.execute { completion(false) }
                return
            }
            
            // if domains are resolved, should retry
            callCompletionBlockOn.execute { completion(true) }
        }
    }
    
    private func handleProxyDomainFailure(
        failedProxyDomain: String, for host: ProductionHosts, callCompletionBlockOn: CompletionBlockExecutor, completion: @escaping (Bool) -> Void
    ) {
        removeFromCache(failedDomain: failedProxyDomain, for: host)
        
        if isThereAnyProxyDomainWorthRetryInCache(for: host) {
            // more domains are available — should retry
             callCompletionBlockOn.execute { completion(true) }
        } else {
            // no more proxy domains are available — should not retry
            callCompletionBlockOn.execute { completion(false) }
        }
    }
    
    @available(*, deprecated, message: "Please use handleErrorResolvingProxyDomainIfNeeded(host:error:completion:)")
    open func handleError(host: String, error: Error?) -> Bool {
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
    
    // MARK: - Resolving proxy domains
    
    private func resolveProxyDomains(for host: ProductionHosts, sessionId: String?, completion: @escaping (Bool) -> Void) {
        domainResolvingExecutor.execute { [weak self] in
            guard let self = self else { completion(false); return }
            
            guard self.isThereAnyProxyDomainWorthRetryInCache(for: host) == false else {
                PMLog.debug("[DoH] Resolving proxy domain — succeeded before")
                completion(true)
                return
            }
            
            PMLog.debug("[DoH] Resolving proxy domain — fetching")
            // perform the proxy domain fetching. it should result in populating the cache
            self.fetchHostFromDNSProvidersUsingSynchronousBlockingCall(for: host, sessionId: sessionId, timeout: self.config.timeout)
            
            // try getting the domain from cache again
            guard self.isThereAnyProxyDomainWorthRetryInCache(for: host) else {
                PMLog.debug("[DoH] Resolving proxy domain — failed")
                return completion(false)
            }
            
            PMLog.debug("[DoH] Resolving proxy domain — succeeded")
            completion(true)
        }
    }

    private func fetchHostFromDNSProvidersUsingSynchronousBlockingCall(for host: ProductionHosts, sessionId: String?, timeout: TimeInterval) {
        assert(Thread.isMainThread == false, "This is a blocking call, should never be called from the main thread")
        
        let semaphore = DispatchSemaphore(value: 0)
        [Google(networkingEngine: networkingEngine), Quad9(networkingEngine: networkingEngine)]
            .map { (provider: DoHProviderInternal) in
                provider.fetch(host: host.dohHost, sessionId: sessionId, timeout: timeout) { [weak self] dns in
                    defer { semaphore.signal() }
                    guard let self = self, let dns = dns else { return }
                    self.populateCache(for: host, with: dns)
                }
            }.forEach {
                semaphore.wait()
            }
    }
}
