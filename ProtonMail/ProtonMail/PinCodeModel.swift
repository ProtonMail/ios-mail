//
//  PinCodeModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/11/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation



 enum PinCodeStep: Int {
    case EnterPin = 0
    case ReEnterPin = 1
    case Unlock = 2
    case Done = 3
}


public class PinCodeViewModel : NSObject {
    
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
    
    func setCode (code : String) -> PinCodeStep {
        fatalError("This method must be overridden")
    }
    
    func isPinMatched() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func done() {
        
    }
    
    func checkTouchID() -> Bool {
        return false
    }
}