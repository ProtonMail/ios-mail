//
//  ViewModelBase.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/22/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


class ViewModelBase {
    
    private var debugInfo : [String] = []
    private var logging : Bool = false
    
    init() { }

    public func start(_ initLog: String) {
        self.debugInfo.removeAll()
        self.debugInfo.append(initLog)
        self.logging = true
    }
    
    public func log(_ log: String) {
        if self.logging {
            self.debugInfo.append(log)
        }
    }
    
    public func end(_ endLog: String) {
        self.debugInfo.append(endLog)
        self.logging = false
    }
    
    public var logs : String {
        get {
            return debugInfo.joined(separator: "\r\n")
        }
    }


}
