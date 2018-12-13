//
//  TestAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/9/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

// Mark : get all settings
final class TestOffline : ApiRequest<ApiResponse> {
    override func path() -> String {
        return Constants.App.API_PATH + "/tests/offline"
    }
    override func apiVersion() -> Int {
        return 3
        
    }
}

final class TestBadRequest : ApiRequestNew<ApiResponse> {
    override func path() -> String {
        return Constants.App.API_PATH + "/tests/offline1"
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

