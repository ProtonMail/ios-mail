//
//  NSManagedObjectExtension.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import CoreData

extension NSManagedObject {

    struct AttributeType: OptionSet {
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
    internal func replaceNilAttributesWithEmptyString(option: AttributeType) {
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
