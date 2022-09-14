//
//  DoHProviderGoogle.swift
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

public struct Google: DoHProviderInternal {
    
    let supported: [DNSType] = [.txt]
    
    let networkingEngine: DoHNetworkingEngine

    init(networkingEngine: DoHNetworkingEngine) {
        self.networkingEngine = networkingEngine
    }

    public let url = "https://dns.google.com"

    func query(host: String, sessionId: String?) -> String {
        if let sessionId = sessionId {
            return self.url + "/resolve?type=TXT&name=" + sessionId + "." + host
        }
        return self.url + "/resolve?type=TXT&name=" + host
    }
}
