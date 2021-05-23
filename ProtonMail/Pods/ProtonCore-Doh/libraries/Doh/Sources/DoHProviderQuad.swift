//
//  DoHProviderQuad.swift
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
import ProtonCore_Log

struct Quad9: DoHProviderInternal {

    public init() {
        // TODO:: remove public later
    }

    let supported: [Int] = [DNSType.txt.rawValue]

    public let url = "https://dns11.quad9.net:5053"

    func query(host: String) -> String {
        return self.url + "/dns-query?type=TXT&name=" + host
    }

    func parse(response: String) -> DNS? {
        return nil
    }

    func parse(data response: Data) -> [DNS]? {
        do {
            guard let dictRes = try JSONSerialization.jsonObject(with: response, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any] else {
                // throw error
                return nil
            }

            guard let answers = dictRes["Answer"] as? [[String: Any]] else {
                // throw error
                return nil
            }

            var addrList: [String] = []
            var ttl = -1
            for answer in answers {
                if let type = answer["type"] as? Int, supported.contains(type) {
                    if let addr = answer["data"] as? String {
                        let pureAddr = addr.replacingOccurrences(of: "\"", with: "")
                        addrList.append(pureAddr)
                    }
                    if let timeout = answer["TTL"] as? Int {
                        ttl = timeout
                    }
                }
            }
            if ttl > 0 && addrList.count > 0 {
                var dnsList: [DNS] = []
                for addr in addrList {
                    dnsList.append(DNS(url: addr, ttl: ttl))
                }
                return dnsList
            }
            return nil
        } catch {
            PMLog.debug("parse error: \(error)")
            // throw error
            return nil
        }
    }
}
