//
//  NSManagedObjectExtension.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import CoreData


extension NSManagedObject {
    
    struct AttributeType : OptionSet {
        let rawValue: Int

        /// string type
        static let string = AttributeType(rawValue: 1 << 0 )
        /// transformable type
        static let transformable = AttributeType(rawValue: 1 << 1 )
    }
    
    /// Set nil string attributes to ""
    internal func replaceNilStringAttributesWithEmptyString() {
        replaceNilAttributesWithEmptyString(option: [.string])
    }
    
    
    /// Set nil string attributes to ""
    internal func replaceNilAttributesWithEmptyString(option : AttributeType) {
        let checkString = option.contains(.string)
        let checkTrans = option.contains(.transformable)
        for (_, attribute) in entity.attributesByName {
            
            if checkString && attribute.attributeType == .stringAttributeType {
                if value(forKey: attribute.name) == nil {
                    setValue("", forKey: attribute.name)
                }
            }
            
            if checkTrans && attribute.attributeType == .transformableAttributeType {
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
