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

public class ContactVO: NSObject, ContactPickerModelProtocol {
    public struct Attributes {
        static public let email = "email"
    }

    public var title: String
    public var subtitle: String
    public var contactId: String
    public var name: String!
    @objc public var email: String!
    public var isProtonMailContact: Bool = false
    
    //
    var contactTitle : String {
        get {
            return title
        }
    }
    var contactSubtitle : String? {
        get {
            return subtitle
        }
    }
    var contactImage : UIImage? {
        get {
            return nil
        }
    }

    
    public init(id: String! = "", name: String!, email: String!, isProtonMailContact: Bool = false) {
        self.contactId = id
        self.name = name
        self.email = email
        self.isProtonMailContact = isProtonMailContact
        
        self.title = !name.isEmpty && name != " " ? name : email
        self.subtitle = email
    }
    
    override public var description: String {
        return "\(name) \(email)"
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? ContactVO else {
            return false
        }
        let lhs = self
        
        return lhs.email == rhs.email
    }
}

//Extension::Array - contact vo
extension Array where Element: ContactVO {
    mutating func distinctMerge(_ check : [Element]) {
        for element in check {
            if self.contains(element) {
                
            } else {
                self.append(element)
            }
        }
    }
    
    public func uniq() -> [Element] {
        var arrayCopy = self
        arrayCopy.uniqInPlace()
        return arrayCopy
    }
    
    mutating internal func uniqInPlace() {
        var seen = [Element]()
        var index = 0
        for element in self {
            if seen.contains(element) {
                remove(at: index)
            } else {
                seen.append(element)
                index+=1
            }
        }
    }
}
