//
//  PinCodeModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/11/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation



 enum PinCodeStep: Int {
    case enterPin = 0
    case reEnterPin = 1
    case unlock = 2
    case done = 3
}


open class PinCodeViewModel : NSObject {
    
    func title() -> String {
        fatalError("This method must be overridden")
    }
    
    func cancel() -> String {
        fatalError("This method must be overridden")
    }
    
    func showConfirm() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func confirmString () -> String {
        fatalError("This method must be overridden")
    }
    
    func setCode (_ code : String) -> PinCodeStep {
        fatalError("This method must be overridden")
    }
    
    func isPinMatched() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func getPinFailedRemainingCount() -> Int {
        fatalError("This method must be overridden")
    }
    
    func getPinFailedError() -> String {
        fatalError("This method must be overridden")
    }
    
    func done() {
        
    }
    
    func checkTouchID() -> Bool {
        return false
    }
}
