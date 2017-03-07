//
//  CaptchaViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 12/28/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation



open class CaptchaViewModelImpl : HumanCheckViewModel {
    
    override open func getToken(_ complete: @escaping HumanResBlock) {
        let api = GetHumanCheckRequest<GetHumanCheckResponse>()
        api.call { (task, response, hasError) in
            complete(response?.token, response?.error)
        }
    }
    
    override open func humanCheck(_ type: String, token: String, complete: @escaping HumanCheckBlock) {
        let api = HumanCheckRequest<ApiResponse>(type: type, token: token)
        api.call { (task, response, hasError) in
            complete(response?.error)
        }
    }
}
