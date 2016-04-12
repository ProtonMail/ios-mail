//
//  SetPinCodeModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/11/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation


class SetPinCodeModelImpl : PinCodeViewModel {
    
    override func title() -> String {
        return ""
    }
    
    override func cancel() -> String {
        return ""
    }
    
    override func showConfirm() -> Bool {
        return true
    }
    
    override func confirmString () -> String {
        return ""
    }
}