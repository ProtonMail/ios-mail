//
//  APIService+MessagesExtension.swift
//  ProtonMail
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
import PMCommon

//TODO:: this file need to be removed
fileprivate struct MessagePath {
    static let base = "/\(Constants.App.API_PREFIXED)/messages"
}

//TODO :: all the request post put ... all could abstract a body layer, after change the request only need the url and request object.
/// Messages extension
extension APIService {
    
//    enum Filter: Int {
//        case noFilter = -2
//        case read = 0
//        case unRead = 1
//    }
//
//    enum Order: Int {
//        case ascending = 0
//        case descending = 1
//    }
//
//    enum SortedColumn: String {
//        case date = "Date"
//        case from = "From"
//        case size = "Size"
//        case subject = "Subject"
//    }
//
//    struct MessageErrorCode {
//        static let credentialExpired = 10
//        static let credentialInvalid = 20
//        static let invalidGrant = 30
//        static let unableToParseToken = 40
//    }
//
//    //new way to do the new work calls
//    func POST<T> ( _ apiRequest : ApiRequest<T>!, authCredential: AuthCredential? = nil, completion: CompletionBlock?) {
//        let parameterStrings = apiRequest.toDictionary()
//        request(method: .post,
//                path: apiRequest.path(),
//                parameters: parameterStrings,
//                headers: self.getHeader(apiRequest),
//                customAuthCredential: authCredential,
//                completion: completion)
//    }
//
//    func PUT<T> ( _ apiRequest : ApiRequest<T>!, authCredential: AuthCredential? = nil, completion: CompletionBlock?) {
//        let parameterStrings = apiRequest.toDictionary()
//        request(method: .put,
//                path: apiRequest.path(),
//                parameters: parameterStrings,
//                headers: self.getHeader(apiRequest),
//                customAuthCredential: authCredential,
//                completion: completion)
//    }
//
    func GET( _ api : Request, authCredential: AuthCredential? = nil, completion: CompletionBlock?) {
        var headers = api.header
        headers[HTTPHeader.apiVersion] = api.version
        self.request(method: .get,
                     path: api.path,
                     parameters: api.parameters,
                     headers: headers,
                     authenticated: api.isAuth,
                     autoRetry: api.autoRetry,
                     customAuthCredential: api.authCredential,
                     completion: completion)
    }
//
//    func Delete<T> ( _ apiRequest : ApiRequest<T>!, authCredential: AuthCredential? = nil, completion: CompletionBlock?) {
//        let parameterStrings = apiRequest.toDictionary()
//        request(method: .delete,
//                path: apiRequest.path(),
//                parameters: parameterStrings,
//                headers: self.getHeader(apiRequest),
//                customAuthCredential: authCredential,
//                completion: completion)
//    }
//
//    private func getHeader<T>(_ apiRequest : ApiRequest<T>) -> [String: Int] {
//        if apiRequest.ver() == -1 {
//            return [:]
//        }
//        return
//    }
//
//    // MARK : Need change soon tempry for no outside incoming emails
//    func fetchLatestMessageList(_ time: Int, completion: @escaping CompletionBlock) {
//        let path = MessagePath.base + "/latest/\(time)"
//        request(method: .get,
//                path: path,
//                parameters: nil,
//                headers: [:],
//                completion: completion)
//    }
//
//
//    // MARK: - Public methods
//    func messageCheck(timestamp: TimeInterval, completion: CompletionBlock?) {
//        let path = MessagePath.base + "/check"
//        let parameters = ["t" : timestamp]
//        request(method: .get,
//                path: path,
//                parameters: parameters,
//                headers: [:],
//                completion: completion)
//    }
//
//    func messageCountForLocation(_ location: Int, completion: CompletionBlock?) {
//        let path = MessagePath.base
//        let parameters = ["Location" : location]
//        let completionWrapper = completionWrapperParseCompletion(completion, forKey: "MessageCount")
//        request(method: .get,
//                path: path,
//                parameters: parameters,
//                headers: [:],
//                completion: completionWrapper)
//    }
//
//
    func messageDetail(messageID: String, completion: @escaping CompletionBlock) {
        let path = MessagePath.base + "/\(messageID)"
        PMLog.D("path: \(path)")
        self.request(method: .get,
                     path: path,
                     parameters: nil,
                     headers: [:],
                     authenticated: true,
                     autoRetry: true,
                     customAuthCredential: nil,
                     completion: completion)
    }
//
//    func messageSearch(_ query: String, page: Int, completion: CompletionBlock?) {
//        let path = MessagePath.base
//        let parameters :  [String : Any] = [
//            "Keyword" : query,
//            "Page" : page
//        ]
//
//        request(method: .get,
//                path: path,
//                parameters: parameters,
//                headers: [:],
//                completion: completion)
//    }
//
//
//    // MARK: - Private methods
//    fileprivate func filteredMessageStringParameters(_ parameters: [String : String]) -> [String : String] {
//        var filteredParameters: [String : String] = [:]
//        for (key, value) in parameters {
//            if !value.isEmpty {
//                filteredParameters[key] = value
//            }
//        }
//        return filteredParameters
//    }
}
