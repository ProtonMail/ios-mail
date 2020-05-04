//
//  TestAPI.swift
//  ProtonMail - Created on 4/9/18.
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

// Mark : get all settings
final class TestOffline : ApiRequest<ApiResponse> {
    override func path() -> String {
        return "/tests/offline"
    }
    override func apiVersion() -> Int {
        return 3
        
    }
}

final class TestBadRequest : ApiRequestNew<ApiResponse> {
    override func path() -> String {
        return "/tests/offline1"
    }
    override func apiVersion() -> Int {
        return 3
        
    }
}


//example
//let api = TestBadRequest()
//api.call().done(on: .main) { (res) in
//    PMLog.D(any: res)
//    }.catch(on: .main) { (error) in
//        PMLog.D(any: error)
//}

