//
//  CaptchViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 12/28/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation



open class HumanCheckViewModel {
    public typealias HumanResBlock = (_ token: String?, _ error: NSError?) -> Void
    public typealias HumanCheckBlock = (_ error: NSError?) -> Void
    
    public init() { }

    open func getToken(_ complete: @escaping HumanResBlock) {
        fatalError("This method must be overridden")
    }
   
    open func humanCheck(_ type: String, token: String, complete:@escaping HumanCheckBlock) {
        fatalError("This method must be overridden")
    }
    
}
