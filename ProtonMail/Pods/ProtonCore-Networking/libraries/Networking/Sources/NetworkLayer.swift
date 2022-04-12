//
//  MessageService.swift
//  ProtonCore-Networking - Created on 5/22/20.
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

//////////
///// predefind input funcs for callbacks, for example
// typealias CallBackBlocks = (() -> Void)
protocol NetworkLayer {
    // generci interfaces to support Http requests
//    func request(_ request: URLRequestConvertible,
//                 success: @escaping (() -> Void),
//                 failure: @escaping ((Error) -> Void))
//    func download(_ request: URLRequestConvertible,
//                  success: @escaping ((JSONDictionary) -> Void),
//                  failure: @escaping ((Error) -> Void))
//    func upload(_ request: URLRequestConvertible,
//                parameters: [String: String],
//                files: [String: URL],
//                success: @escaping ((JSONDictionary) -> Void),
//                failure: @escaping ((Error) -> Void))
//    func request(method: HTTPMethod, path: String,
//                 parameters: Any?, headers: [String : Any]?,
//                 authenticated: Bool,
//                 customAuthCredential: AuthCredential?,
//                 completion: CompletionBlock?)
    func initSession()

    func hookupSSLPining()
}

class AFNetworkingWarpper: NetworkLayer {
    func initSession() {

    }

    func hookupSSLPining() {

    }

    /// response for delevey data to the third party lib
    init() {
        // setup session manager
        // setup pining
        // etc
    }
}

// class MailDoh : DoH {
//    //Doh config
// }
//
//
// ---------------------- notes ----------------------
//
///// general flow
// 1. Defind your APIClient. example.  -  GetSomething: APIClient
// 2. Definde YourService extend on Service interface, and hold the instance of the PMAPIService.
// 3. when your service business logic trying to reach API. just create a APIClient impliment GetSomething and pass in APIService
// 3. each APIClient has routes of the server end point. devs only need to set the vars defind in the interface
// 4. when app start, need to init the PMAPIService by passing in DohConfig, AuthDelegate, APIServiceDelegate and the NetworkWrapperImpl
//
// The Demo code is coming this week.
