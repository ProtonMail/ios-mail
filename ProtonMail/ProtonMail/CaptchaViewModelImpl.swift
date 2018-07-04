//
//  CaptchaViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 12/28/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation



final class CaptchaViewModelImpl : HumanCheckViewModel {
    
    override func getToken(_ complete: @escaping HumanResBlock) {
        let api = GetHumanCheckToken()
        api.call { (task, response, hasError) in
            complete(response?.token, response?.error)
        }
    }
    
    override func humanCheck(_ type: String, token: String, complete: @escaping HumanCheckBlock) {
        let api = HumanCheckRequest(type: type, token: token)
        api.call { (task, response, hasError) in
            complete(response?.error)
        }
    }
}
