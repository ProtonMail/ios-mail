//
//  CaptchViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 12/28/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation



public class HumanCheckViewModel {
    public typealias HumanResBlock = (token: String?, error: NSError?) -> Void
    public typealias HumanCheckBlock = (error: NSError?) -> Void
    
    public init() { }

    public func getToken(complete: HumanResBlock) {
        fatalError("This method must be overridden")
    }
   
    public func humanCheck(type: String, token: String, complete: HumanCheckBlock) {
        fatalError("This method must be overridden")
    }
    
}
