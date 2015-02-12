//
//  NetworkQueue.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

class NetworkQueue: PersistentQueue {
    
    private struct Key {
        static let method = "method"
        static let path = "path"
        static let parameters = "parameters"
    }

    // MARK: - Public variables
    
    var isBlocked: Bool = false
    
    // MARK: - Public methods
    
    func addRequest(#method: String, path: String, parameters: AnyObject?) -> NSUUID {
        var networkElement: [String : AnyObject] = [Key.method : method, Key.path : path]
        
        if let parameters: AnyObject = parameters {
            networkElement[Key.parameters] = parameters
        }
        
        return add(networkElement)
    }
    
    func nextRequest() -> (uuid: NSUUID, method: String, path: String, parameters: AnyObject?)? {
        if isBlocked {
            return nil
        }
        
        if let (uuid, object: AnyObject) = next() {
            if let networkElement = object as? [String : AnyObject] {
                return (uuid, networkElement[Key.method] as String, networkElement[Key.path] as String, networkElement[Key.parameters])
            } else {
                NSLog("\(__FUNCTION__) Removing invalid networkElement: \(object) from the queue.")
                remove(elementID: uuid)
            }
        }
        
        return nil
    }
    
}