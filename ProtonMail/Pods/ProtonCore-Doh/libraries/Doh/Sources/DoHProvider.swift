//
//  DoHProvider.swift
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
    func fetch(host: String, completion: @escaping ([DNS]?) -> Void)
    func fetch(host: String, timeout: TimeInterval, completion: @escaping ([DNS]?) -> Void)
}

protocol DoHProviderInternal: DoHProviderPublic {
    func query(host: String) -> String
    func parse(response: String) -> DNS?
    func parse(data response: Data) -> [DNS]?
    var networkingEngine: DoHNetworkingEngine { get }
}

extension DoHProviderInternal {
    public func fetch(host: String, timeout: TimeInterval, completion: @escaping ([DNS]?) -> Void) {
        let urlStr = self.query(host: host)
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
    
    public func fetch(host: String, completion: @escaping ([DNS]?) -> Void) {
        self.fetch(host: host, timeout: 5, completion: completion)
    }
    
    private func fetchAsynchronously(request: URLRequest, completion: @escaping (Data?) -> Void) {
        let task = networkingEngine.networkRequest(with: request) { taskData, response, error in
            // TODO:: log error or throw error. for now we ignore it and upper layer will use the default values
            completion(taskData)
        }
        task.resume()
    }
}
