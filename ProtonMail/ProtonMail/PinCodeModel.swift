//
//  PinCodeModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/11/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation


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
}