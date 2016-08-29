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
            if attribute.attributeType == .StringAttributeType {
                if valueForKey(attribute.name) == nil {
                    setValue("", forKey: attribute.name)
                }
            }
        }
    }
}
