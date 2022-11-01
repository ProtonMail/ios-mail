//
//  DNS.swift
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

/// dns record
public struct DNS: Equatable {
    
    /// the host
    public let host: String
    
    /// time to lives
    public let ttl: Int
}

extension DNS {
    
    @available(*, deprecated, renamed: "host")
    public var url: String { host }
    
    @available(*, deprecated, renamed: "init(host:ttl:)")
    init(url: String, ttl: Int) {
        self.init(host: url, ttl: ttl)
    }
}

/// dns type, right now only support 16 - txt
enum DNSType: Int {
    case txt = 16
}

/// dns result format
enum Type {
    case wireformat
    case json
}
