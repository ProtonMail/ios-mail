//
//  DohMock.swift
//  ProtonCore-TestingToolkit - Created on 03.06.2021.
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

import XCTest
import ProtonCore_Doh
import ProtonCore_Utilities

public struct DohInterfaceMock: DoHInterface, ServerConfig {

    public init() {}

    @PropertyStub(\DohInterfaceMock.apiHost, initialGet: .crash) public var apiHostStub
    public var apiHost: String { apiHostStub() }

    @PropertyStub(\DohInterfaceMock.blockList, initialGet: .crash) public var blockListStub
    public var blockList: [String: Int] { blockListStub() }

    @PropertyStub(\DohInterfaceMock.captchaHost, initialGet: .crash) public var captchaHostStub
    public var captchaHost: String { captchaHostStub() }
    
    @PropertyStub(\DohInterfaceMock.humanVerificationV3Host, initialGet: .crash) public var humanVerificationV3HostStub
    public var humanVerificationV3Host: String { humanVerificationV3HostStub() }
    
    @PropertyStub(\DohInterfaceMock.accountHost, initialGet: .crash) public var accountHostStub
    public var accountHost: String { accountHostStub() }

    @FuncStub(DohInterfaceMock.clearCache) public var clearCacheStub
    public func clearCache() { clearCacheStub() }
    
    @available(*, deprecated, message: "This is a stub for a deprecated API")
    @FuncStub(DohInterfaceMock.clearAll) public var clearAllStub
    @available(*, deprecated, message: "This is a deprecated API")
    public func clearAll() { clearAllStub() }

    @available(*, deprecated, message: "This is a stub for a deprecated API")
    @FuncStub(DohInterfaceMock.codeCheck, initialReturn: .crash) public var codeCheckStub
    @available(*, deprecated, message: "This is a deprecated API")
    public func codeCheck(code: Int) -> Bool { codeCheckStub(code) }
    
    @FuncStub(DohInterfaceMock.errorIndicatesDoHSolvableProblem, initialReturn: .crash) public var errorIndicatesDoHSolvableProblemStub
    public func errorIndicatesDoHSolvableProblem(error: Error?) -> Bool {
        errorIndicatesDoHSolvableProblemStub(error)
    }

    @PropertyStub(\DohInterfaceMock.debugBlock, initialGet: .crash) public var debugBlockStub
    public var debugBlock: [String: Bool] { debugBlockStub() }

    @PropertyStub(\DohInterfaceMock.debugMode, initialGet: .crash) public var debugModeStub
    public var debugMode: Bool { debugModeStub() }

    @PropertyStub(\DohInterfaceMock.defaultHost, initialGet: .crash) public var defaultHostStub
    public var defaultHost: String { defaultHostStub() }

    @PropertyStub(\DohInterfaceMock.defaultPath, initialGet: .crash) public var defaultPathStub
    public var defaultPath: String { defaultPathStub() }

    @PropertyStub(\DohInterfaceMock.enableDoh, initialGet: .crash) public var enableDohStub
    public var enableDoh: Bool { enableDohStub() }
    
    @FuncStub(DohInterfaceMock.getCurrentlyUsedUrlHeaders, initialReturn: .crash) public var getCurrentlyUsedUrlHeadersStub
    public func getCurrentlyUsedUrlHeaders() -> [String: String] {
        getCurrentlyUsedUrlHeadersStub()
    }

    @FuncStub(DohInterfaceMock.getCaptchaHostUrl, initialReturn: .crash) public var getCaptchaHostUrlStub
    public func getCaptchaHostUrl() -> String { getCaptchaHostUrlStub() }
    
    @FuncStub(DohInterfaceMock.getCaptchaHeaders, initialReturn: .crash) public var getCaptchaHeadersStub
    public func getCaptchaHeaders() -> [String: String] {
        getCaptchaHeadersStub()
    }
    
    @FuncStub(DohInterfaceMock.getHumanVerificationV3Host, initialReturn: .crash) public var getHumanVerificationV3HostStub
    public func getHumanVerificationV3Host() -> String { getHumanVerificationV3HostStub() }
    
    @FuncStub(DohInterfaceMock.getHumanVerificationV3Headers, initialReturn: .crash) public var getHumanVerificationV3HeadersStub
    public func getHumanVerificationV3Headers() -> [String: String] { getHumanVerificationV3HeadersStub() }
    
    @FuncStub(DohInterfaceMock.getAccountHost, initialReturn: .crash) public var getAccountHostStub
    public func getAccountHost() -> String { getAccountHostStub() }
    
    @FuncStub(DohInterfaceMock.getAccountHeaders, initialReturn: .crash) public var getAccountHeadersStub
    public func getAccountHeaders() -> [String: String] { getAccountHeadersStub() }

    @available(*, deprecated, message: "This is a stub for a deprecated API")
    @FuncStub(DohInterfaceMock.getHostUrl, initialReturn: .crash) public var getHostUrlStub
    @available(*, deprecated, message: "This is a deprecated API")
    public func getHostUrl() -> String { getHostUrlStub() }

    @available(*, deprecated, message: "This is a stub for a deprecated API")
    @FuncStub(DohInterfaceMock.handleError, initialReturn: .crash) public var handleErrorStub
    @available(*, deprecated, message: "This is a deprecated API")
    public func handleError(host: String, error: Error?) -> Bool { handleErrorStub(host, error) }

    @PropertyStub(\DohInterfaceMock.signupDomain, initialGet: .crash) public var signupDomainStub
    public var signupDomain: String { signupDomainStub() }

    @PropertyStub(\DohInterfaceMock.status, initialGet: .crash) public var statusStub
    public var status: DoHStatus { get { statusStub() } set { statusStub(newValue) } }
    
    @FuncStub(DohInterfaceMock.getCurrentlyUsedHostUrl, initialReturn: .crash) public var getCurrentlyUsedHostUrlStub
    public func getCurrentlyUsedHostUrl() -> String { getCurrentlyUsedHostUrlStub() }
    
    @PropertyStub(\DohInterfaceMock.isCurrentlyUsingProxyDomain, initialGet: .crash) public var isCurrentlyUsingProxyDomainStub
    public var isCurrentlyUsingProxyDomain: Bool { isCurrentlyUsingProxyDomainStub() }
    
    @FuncStub(DohInterfaceMock.resolveProxyDomainHostUrl) public var resolveProxyDomainHostUrlStub
    public func resolveProxyDomainHostUrl(completion: @escaping (String?) -> Void) { resolveProxyDomainHostUrlStub(completion) }
    
    @FuncStub(DohInterfaceMock.handleErrorResolvingProxyDomainIfNeeded(host:requestHeaders:sessionId:error:callCompletionBlockUsing:completion:)) public var handleErrorResolvingProxyDomainIfNeededWithExecutorWithSessionIdStub
    // swiftlint:disable function_parameter_count
    public func handleErrorResolvingProxyDomainIfNeeded(
        host: String,
        requestHeaders: [String: String],
        sessionId: String?,
        error: Error?,
        callCompletionBlockUsing: CompletionBlockExecutor,
        completion: @escaping (Bool) -> Void
    ) {
        handleErrorResolvingProxyDomainIfNeededWithExecutorWithSessionIdStub(host, requestHeaders, sessionId, error, callCompletionBlockUsing, completion)
    }
    
    @FuncStub(DohInterfaceMock.handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeeded(host:requestHeaders:sessionId:response:error:callCompletionBlockUsing:completion:)) public var handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeededWithSessionIdStub
    // swiftlint:disable function_parameter_count
    public func handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeeded(
        host: String,
        requestHeaders: [String: String],
        sessionId: String?,
        response: URLResponse?,
        error: Error?,
        callCompletionBlockUsing: CompletionBlockExecutor,
        completion: @escaping (Bool) -> Void
    ) {
        handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeededWithSessionIdStub(host, requestHeaders, sessionId, response, error, callCompletionBlockUsing, completion)
    }
    
    @FuncStub(DohInterfaceMock.getSignUpString, initialReturn: .empty) public var getSignUpStringStub
    public func getSignUpString() -> String { getSignUpStringStub() }
    
    @FuncStub(DohInterfaceMock.synchronizeCookies) public var synchronizeCookiesStub
    public func synchronizeCookies(with response: URLResponse?, requestHeaders: [String: String]) { synchronizeCookiesStub(response, requestHeaders) }
    
    @FuncStub(DohInterfaceMock.setUpCookieSynchronization) public var setUpCookieSynchronizationStub
    public func setUpCookieSynchronization(storage: HTTPCookieStorage?) { setUpCookieSynchronizationStub(storage) }
    
    @PropertyStub(\DohInterfaceMock.currentlyUsedCookiesStorage, initialGet: nil) public var currentlyUsedCookiesStorageStub
    public var currentlyUsedCookiesStorage: HTTPCookieStorage? { currentlyUsedCookiesStorageStub() }
    
}

public final class DohMock: DoH, ServerConfig {

    public init() {
        super.init()
        statusStub.fixture = .off
        handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeededWithSessionIdStub.bodyIs { _, _, _, _, _, _, _, completion in
            completion(false)
        }
        errorIndicatesDoHSolvableProblemStub.bodyIs { _, _ in false }
    }
    
    @FuncStub(DohMock.getCurrentlyUsedHostUrl, initialReturn: Dummy.url) public var getCurrentlyUsedHostUrlStub
    override public func getCurrentlyUsedHostUrl() -> String { getCurrentlyUsedHostUrlStub() }

    @PropertyStub(\DohInterfaceMock.defaultHost, initialGet: Dummy.url) public var defaultHostStub
    public var defaultHost: String { defaultHostStub() }

    @PropertyStub(\DohInterfaceMock.captchaHost, initialGet: .crash) public var captchaHostStub
    public var captchaHost: String { captchaHostStub() }
    
    @PropertyStub(\DohInterfaceMock.humanVerificationV3Host, initialGet: .crash) public var humanVerificationV3HostStub
    public var humanVerificationV3Host: String { humanVerificationV3HostStub() }
    
    @PropertyStub(\DohInterfaceMock.accountHost, initialGet: .crash) public var accountHostStub
    public var accountHost: String { accountHostStub() }

    @PropertyStub(\DohInterfaceMock.apiHost, initialGet: Dummy.domain) public var apiHostStub
    public var apiHost: String { apiHostStub() }

    @PropertyStub(\DohInterfaceMock.defaultPath, initialGet: Dummy.apiPath) public var defaultPathStub
    public var defaultPath: String { defaultPathStub() }

    @PropertyStub(\DohInterfaceMock.signupDomain, initialGet: .crash) public var signupDomainStub
    public var signupDomain: String { signupDomainStub() }
    
    @PropertyStub(\DohInterfaceMock.enableDoh, initialGet: false) public var enableDohStub
    public var enableDoh: Bool { enableDohStub() }
    
    @PropertyStub(\DohInterfaceMock.blockList, initialGet: .crash) public var blockListStub
    public var blockList: [String: Int] { blockListStub() }

    @FuncStub(DohInterfaceMock.clearCache) public var clearCacheStub
    override public func clearCache() { clearCacheStub() }
    
    @available(*, deprecated, message: "This is a stub for a deprecated API")
    @FuncStub(DohInterfaceMock.clearAll) public var clearAllStub
    @available(*, deprecated, message: "This is a deprecated API")
    override public func clearAll() { clearAllStub() }

    @available(*, deprecated, message: "This is a stub for a deprecated API")
    @FuncStub(DohInterfaceMock.codeCheck, initialReturn: .crash) public var codeCheckStub
    @available(*, deprecated, message: "This is a deprecated API")
    override public func codeCheck(code: Int) -> Bool { codeCheckStub(code) }
    
    @FuncStub(DohInterfaceMock.handleErrorResolvingProxyDomainIfNeeded(host:requestHeaders:sessionId:error:callCompletionBlockUsing:completion:)) public var handleErrorResolvingProxyDomainIfNeededWithExecutorWithSessionIdStub
    override public func handleErrorResolvingProxyDomainIfNeeded(
        host: String,
        requestHeaders: [String: String],
        sessionId: String?,
        error: Error?,
        callCompletionBlockUsing: CompletionBlockExecutor,
        completion: @escaping (Bool) -> Void
    ) {
        handleErrorResolvingProxyDomainIfNeededWithExecutorWithSessionIdStub(host, requestHeaders, sessionId, error, callCompletionBlockUsing, completion)
    }
    
    @FuncStub(DohInterfaceMock.handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeeded(host:requestHeaders:sessionId:response:error:callCompletionBlockUsing:completion:)) public var handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeededWithSessionIdStub
    override public func handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeeded(
        host: String,
        requestHeaders: [String: String],
        sessionId: String?,
        response: URLResponse?,
        error: Error?,
        callCompletionBlockUsing: CompletionBlockExecutor,
        completion: @escaping (Bool) -> Void
    ) {
        handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeededWithSessionIdStub(host, requestHeaders, sessionId, response, error, callCompletionBlockUsing, completion)
    }
    
    @FuncStub(DohInterfaceMock.errorIndicatesDoHSolvableProblem, initialReturn: .crash) public var errorIndicatesDoHSolvableProblemStub
    override public func errorIndicatesDoHSolvableProblem(error: Error?) -> Bool {
        errorIndicatesDoHSolvableProblemStub(error)
    }

    @PropertyStub(\DohInterfaceMock.debugBlock, initialGet: .crash) public var debugBlockStub
    public var debugBlock: [String: Bool] { debugBlockStub() }

    @PropertyStub(\DohInterfaceMock.debugMode, initialGet: .crash) public var debugModeStub
    public var debugMode: Bool { debugModeStub() }

    @FuncStub(DohInterfaceMock.getCaptchaHostUrl, initialReturn: .crash) public var getCaptchaHostUrlStub
    override public func getCaptchaHostUrl() -> String { getCaptchaHostUrlStub() }
    
    @FuncStub(DohInterfaceMock.getHumanVerificationV3Host, initialReturn: .crash) public var getHumanVerificationV3HostStub
    override public func getHumanVerificationV3Host() -> String { getHumanVerificationV3HostStub() }
    
    @FuncStub(DohInterfaceMock.getHumanVerificationV3Headers, initialReturn: .crash) public var getHumanVerificationV3HeadersStub
    override public func getHumanVerificationV3Headers() -> [String: String] { getHumanVerificationV3HeadersStub() }
    
    @FuncStub(DohInterfaceMock.getAccountHost, initialReturn: .crash) public var getAccountHostStub
    override public func getAccountHost() -> String { getAccountHostStub() }
    
    @FuncStub(DohInterfaceMock.getAccountHeaders, initialReturn: .crash) public var getAccountHeadersStub
    override public func getAccountHeaders() -> [String: String] { getAccountHeadersStub() }

    @available(*, deprecated, message: "This is a stub for a deprecated API")
    @FuncStub(DohInterfaceMock.getHostUrl, initialReturn: .crash) public var getHostUrlStub
    @available(*, deprecated, message: "This is a deprecated API")
    override public func getHostUrl() -> String { getHostUrlStub() }

    @available(*, deprecated, message: "This is a stub for a deprecated API")
    @FuncStub(DohInterfaceMock.handleError, initialReturn: .crash) public var handleErrorStub
    @available(*, deprecated, message: "This is a deprecated API")
    override public func handleError(host: String, error: Error?) -> Bool { handleErrorStub(host, error) }

    @PropertyStub(\DohInterfaceMock.status, initialGet: .crash) public var statusStub
    override public var status: DoHStatus { get { statusStub() } set { statusStub(newValue) } }
    
    @PropertyStub(\DohInterfaceMock.isCurrentlyUsingProxyDomain, initialGet: .crash) public var isCurrentlyUsingProxyDomainStub
    public var isCurrentlyUsingProxyDomain: Bool { isCurrentlyUsingProxyDomainStub() }
    
    @FuncStub(DohInterfaceMock.resolveProxyDomainHostUrl) public var resolveProxyDomainHostUrlStub
    public func resolveProxyDomainHostUrl(completion: @escaping (String?) -> Void) { resolveProxyDomainHostUrlStub(completion) }
    
    @FuncStub(DohInterfaceMock.getSignUpString, initialReturn: .empty) public var getSignUpStringStub
    override public func getSignUpString() -> String { getSignUpStringStub() }
    
    @FuncStub(DohInterfaceMock.synchronizeCookies) public var synchronizeCookiesStub
    override public func synchronizeCookies(with response: URLResponse?, requestHeaders: [String: String]) { synchronizeCookiesStub(response, requestHeaders) }
    
    @FuncStub(DohInterfaceMock.setUpCookieSynchronization) public var setUpCookieSynchronizationStub
    override public func setUpCookieSynchronization(storage: HTTPCookieStorage?) { setUpCookieSynchronizationStub(storage) }
}
