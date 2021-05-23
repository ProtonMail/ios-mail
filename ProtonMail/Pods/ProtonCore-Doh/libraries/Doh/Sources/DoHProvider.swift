//
//  DoHProvider.swift
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

#if canImport(PromiseKit)
import PromiseKit
import AwaitKit
#endif

enum DoHProvider {
    case google
    case quad9
}

public protocol DoHProviderPublic {
    func fetch(sync host: String) -> [DNS]?
    func fetch(async host: String)
    #if canImport(PromiseKit)
    func fetch(host: String) -> Promise<DNS?>
    #endif
}

protocol DoHProviderInternal: DoHProviderPublic {
    func query(host: String) -> String
    func parse(response: String) -> DNS?
    func parse(data response: Data) -> [DNS]?
}

extension DoHProviderInternal {
    public func fetch(sync host: String) -> [DNS]? {
        let urlStr = self.query(host: host)
        let url = URL(string: urlStr)!
        guard let resData = try? Data.init(contentsOf: url) else {
            return nil
        }
        guard let dns = self.parse(data: resData) else {
            return nil
        }
        return dns
    }

    public func fetch(async host: String) {

    }

    #if canImport(PromiseKit)
    public func fetch(host: String) -> Promise<DNS?> {
        return async {
            return nil
        }
    }
    #endif

}
