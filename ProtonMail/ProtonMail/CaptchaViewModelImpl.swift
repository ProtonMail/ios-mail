//
//  CaptchaViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 12/28/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation



public class CaptchaViewModelImpl : HumanCheckViewModel {
    
    override public func getToken(complete: HumanResBlock) {
        let api = GetHumanCheckRequest<GetHumanCheckResponse>()
        api.call { (task, response, hasError) in
            complete(token: response?.token, error: response?.error)
        }
    }
    
    override public func humanCheck(type: String, token: String, complete: HumanCheckBlock) {
        let api = HumanCheckRequest<ApiResponse>(type: type, token: token)
        api.call { (task, response, hasError) in
            complete(error: response?.error)
        }
    }
}
