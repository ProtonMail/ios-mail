//
//  NSManagedObjectExtension.swift
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
import CoreData


extension NSManagedObject {
    
    /// Set nil string attributes to ""
    internal func replaceNilStringAttributesWithEmptyString() {
        for (_, attribute) in entity.attributesByName {
            if attribute.attributeType == .stringAttributeType {
                if value(forKey: attribute.name) == nil {
                    setValue("", forKey: attribute.name)
                }
            }
        }
    }
}

/// A little wrapper for passing managed objects between threads: it keeps the reference to the object so it will not be removed from persistent store row cache, but only object id is readable so no one will by mistake use the object itself on a wrong thread
struct ObjectBox<T: NSManagedObject> {
    let objectID: NSManagedObjectID
    private let cache: T
    
    init(_ object: T) {
        self.cache = object
        self.objectID = object.objectID
    }
}
