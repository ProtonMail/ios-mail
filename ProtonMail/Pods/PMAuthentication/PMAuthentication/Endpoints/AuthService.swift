//
//  AuthService.swift
//  PMAuthentication - Created on 20/02/2020.
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

public class AuthService: Client {
    public var apiService: APIService
    public init(api: APIService) {
        self.apiService = api
    }
    
    func info(username: String, complete: @escaping(_ response: AuthInfoResponse) -> Void) {
        let route = InfoEndpoint(username: username)
        self.apiService.exec(route: route, complete: complete)
    }
    
    func auth(username: String,
                     ephemeral: Data,
                     proof: Data,
                     session: String, complete: @escaping(_ response: Result<AuthService.AuthRouteResponse, Error>) -> Void) {
        let route = AuthEndpoint(username: username, ephemeral: ephemeral, proof: proof, session: session)
        self.apiService.exec(route: route, complete: complete)
    }
}
