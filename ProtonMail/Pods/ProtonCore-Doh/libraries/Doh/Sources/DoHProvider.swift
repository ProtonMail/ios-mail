//
//  DoHProvider.swift
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

enum DoHProvider {
    case google
    case quad9
}

public protocol DoHNetworkOperation {
    func resume()
}

extension URLSessionDataTask: DoHNetworkOperation {}

public protocol DoHNetworkingEngine {
    func networkRequest(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> DoHNetworkOperation
}

extension URLSession: DoHNetworkingEngine {
    public func networkRequest(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> DoHNetworkOperation {
        dataTask(with: request, completionHandler: completionHandler)
    }
}

public protocol DoHProviderPublic {
    func fetch(host: String, sessionId: String?, completion: @escaping ([DNS]?) -> Void)
    func fetch(host: String, sessionId: String?, timeout: TimeInterval, completion: @escaping ([DNS]?) -> Void)
}

protocol DoHProviderInternal: DoHProviderPublic {
    var networkingEngine: DoHNetworkingEngine { get }
    var supported: [DNSType] { get }
    func query(host: String, sessionId: String?) -> String
}

extension DoHProviderInternal {
    public func fetch(host: String, sessionId: String?, timeout: TimeInterval, completion: @escaping ([DNS]?) -> Void) {
        let urlStr = self.query(host: host, sessionId: sessionId)
        let url = URL(string: urlStr)!
        
        let request = URLRequest(
            url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: timeout
        )
        
        fetchAsynchronously(request: request) { data in
            guard let resData = data else { completion(nil); return }
            guard let dns = self.parse(data: resData) else { completion(nil); return }
            completion(dns)
        }
    }
    
    public func fetch(host: String, sessionId: String?, completion: @escaping ([DNS]?) -> Void) {
        self.fetch(host: host, sessionId: sessionId, timeout: 5, completion: completion)
    }
    
    private func fetchAsynchronously(request: URLRequest, completion: @escaping (Data?) -> Void) {
        let task = networkingEngine.networkRequest(with: request) { taskData, response, error in
            // TODO:: log error or throw error. for now we ignore it and upper layer will use the default values
            completion(taskData)
        }
        task.resume()
    }
    
    func parse(data response: Data) -> [DNS]? {
        do {
            guard let dictRes = try JSONSerialization.jsonObject(with: response, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any]
            else { return nil }

            guard let answers = dictRes["Answer"] as? [[String: Any]] else { return nil }

            var proxyAddressData: [(String, Int)] = []
            for answer in answers {
                guard let type = answer["type"] as? Int, supported.map(\.rawValue).contains(type) else { continue }
                guard let addr = answer["data"] as? String, let timeout = answer["TTL"] as? Int else { continue }
                
                let pureAddr = addr.replacingOccurrences(of: "\"", with: "")
                
                // validate that the data we received is a valid url, ignore if not
                guard URL(string: "https://\(pureAddr)") != nil else { continue }
                proxyAddressData.append((pureAddr, timeout))
            }
            guard proxyAddressData.count > 0 else { return nil }
            var dnsList: [DNS] = []
            for data in proxyAddressData {
                dnsList.append(DNS(host: data.0, ttl: data.1))
            }
            return dnsList
            
        } catch {
            PMLog.debug("parse error: \(error)")
            return nil
        }
    }
}
