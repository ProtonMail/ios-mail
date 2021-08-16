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
    func fetch(sync host: String, timeout: TimeInterval) -> [DNS]?
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
    public func fetch(sync host: String, timeout: TimeInterval) -> [DNS]? {
        let urlStr = self.query(host: host)
        let url = URL(string: urlStr)!
        
        let request = NSMutableURLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: timeout)
    
        guard let resData = self.fetchSynchronous(request: request) else {
            return nil
        }
        
        guard let dns = self.parse(data: resData) else {
            return nil
        }
        return dns
    }
    
    public func fetch(sync host: String) -> [DNS]? {
        self.fetch(sync: host, timeout: 5)
    }
    
    /// Return data from synchronous URL request
    private func fetchSynchronous(request: NSURLRequest) -> Data? {
        var data: Data?
        DispatchQueue.global(qos: .userInitiated).sync {
            let semaphore = DispatchSemaphore(value: 0)
            let task = URLSession.shared.dataTask(with: request as URLRequest) { taskData, response, error in
                data = taskData
                //  if data == nil, let _ = error {
                // TODO:: log error or throw error. for now we ignore it and upper layer will use the default values
                // }
                semaphore.signal()
            }
            task.resume()
            semaphore.wait()
        }
        return data
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
