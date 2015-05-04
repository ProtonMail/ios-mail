//
//  NSLogExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


func PMLog(message: String, file: String = __FUNCTION__, function: String = __FILE__, line: Int = __LINE__, column: Int = __COLUMN__)
{
    //#if DEBUG
        
        println("\(file) : \(function) : \(line) : \(column) - \(message)")
        //NSLog("credential: \(credential)")
    //#endif

    
}

//extension NSLog{
//    
//    func Log()
//    {
//        
//    }
//    
////    func DLog(message: String, file: String = __FUNCTION__, function: String = __FILE__, line: Int = __LINE__, column: Int = __COLUMN__) {
////        println("\(file) : \(function) : \(line) : \(column) - \(message)")
////    }
//
//}
//
