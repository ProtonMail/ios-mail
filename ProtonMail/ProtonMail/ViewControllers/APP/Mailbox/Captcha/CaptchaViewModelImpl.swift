//
//  CaptchaViewModelImpl.swift
//  Proton Mail - Created on 12/28/16.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_Networking
import ProtonCore_Services

final class CaptchaViewModelImpl: HumanCheckViewModel {

    let apiService: APIService
    init(api: APIService) {
        self.apiService = api
    }

    override func getToken(_ complete: @escaping HumanResBlock) {
        let api = GetHumanCheckToken()
        self.apiService.exec(route: api, responseObject: GetHumanCheckResponse()) { (task, response) in
            if let error = response.error {
                complete(nil, error.toNSError)
            } else {
                complete(response.token, nil)
            }
        }
    }

    override func humanCheck(_ type: String, token: String, complete: @escaping HumanCheckBlock) {
        let api = HumanCheckRequest(type: type, token: token)
        self.apiService.exec(route: api, responseObject: VoidResponse()) { (task, response) in
            complete(response.error?.toNSError)
        }
    }
}
