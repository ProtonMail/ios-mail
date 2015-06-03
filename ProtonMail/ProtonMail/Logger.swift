//
//  NSLogExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


class PMLog {
    
    static func D(message: String, file: String = __FUNCTION__, function: String = __FILE__, line: Int = __LINE__, column: Int = __COLUMN__)
    {
        
        #if DEBUG
            
            println("\(file) : \(function) : \(line) : \(column) - \(message)")
            
        #endif
        
    }
    
    static func D(message: AnyObject, file: String = __FUNCTION__, function: String = __FILE__, line: Int = __LINE__, column: Int = __COLUMN__)
    {
        
        #if DEBUG
            
            println("\(file) : \(function) : \(line) : \(column) - \(message)")
            
        #endif
        
    }
}

//func PMLog(message: String, file: String = __FUNCTION__, function: String = __FILE__, line: Int = __LINE__, column: Int = __COLUMN__)
//{
//    
//    //#if DEBUG
//    
//    println("\(file) : \(function) : \(line) : \(column) - \(message)")
//    //NSLog("credential: \(credential)")
//    //#endif
//    //NSLog("", "")
//    
//}

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
