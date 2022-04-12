//
//  DoHCookiesSynchronizer.swift
//  ProtonCore-Doh - Created on 24/03/22.
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

final class DoHCookieSynchronizer {
    
    weak var cookieStorage: HTTPCookieStorage?
    weak var doh: DoH?

    init(cookieStorage: HTTPCookieStorage, doh: DoH) {
        self.cookieStorage = cookieStorage
        self.doh = doh
    }
    
    func synchronizeCookies(with headers: [String: String]) {
        
        // The feature works as follows:
        // 1. Get the cookies for default host from the response headers
        // 2. Set these cookies (they wouldn't be set otherwise because they are not proxy domain cookies)
        // 3. Set cookies with the same properties for proxy domains
        // It works because backend always sets the cookies for the default host, never for proxy domain
        
        guard let doh = doh, let cookieStorage = cookieStorage else { return }
        
        let domains = doh.fetchAllCacheHostUrls()
        // this ensures we don't do any unnecessary work if no proxy domain is in use
        guard !domains.isEmpty else { return }
        
        guard let url = URL(string: doh.getDefaultHost()) else { return }
        let newCookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
        cookieStorage.setCookies(newCookies, for: url, mainDocumentURL: nil)
        
        guard let cookies = cookieStorage.cookies(for: url) else { return }
        
        for domain in domains {
            let domainCookies = cookies.compactMap { cookie -> HTTPCookie? in
                guard var properties = cookie.properties else { return nil }
                if properties[.domain] != nil {
                    properties[.domain] = domain
                }
                if properties[.originURL] != nil {
                    properties[.originURL] = domain
                }
                guard let newCookie = HTTPCookie(properties: properties) else { return nil }
                return newCookie
            }
            guard let domainUrl = URL(string: doh.hostUrl(for: domain)) else { continue }
            cookieStorage.setCookies(domainCookies, for: domainUrl, mainDocumentURL: nil)
        }
    }
}
