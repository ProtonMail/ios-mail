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
    override open func path() -> String {
        return AppConstants.API_PATH + "/tests/offline"
    }
    override func apiVersion() -> Int {
        return 3
        
    }
}

final class TestBadRequest : ApiRequest<ApiResponse> {
    override open func path() -> String {
        return AppConstants.API_PATH + "/tests/offline1"
    }
    override func apiVersion() -> Int {
        return 3
        
    }
}
