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

class ContactVO: NSObject, MBContactPickerModelProtocol {
    struct Attributes {
        static let email = "email"
    }

    internal var contactTitle: String!
    internal var contactSubtitle: String!
    internal var contactId: String!
    internal var name: String!
    internal var email: String!
    internal var isProtonMailContact: Bool = false
    
    init(id: String! = "", name: String!, email: String!, isProtonMailContact: Bool = false) {
        self.contactId = id
        self.name = name
        self.email = email
        self.isProtonMailContact = isProtonMailContact
        
        self.contactTitle = name
        self.contactSubtitle = email
    }
    
    override var description: String {
        return "\(name) \(email)"
    }
}
