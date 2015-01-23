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

class EmailThread: NSObject {
    
    internal var id: String!
    internal var title: String!
    internal var sender: String!
    internal var time: String!
    internal var hasAttachments: Bool = false
    internal var isEncrypted: Bool = false
    internal var isFavorite: Bool = false
    
    override init() {
        super.init()
    }
    
    convenience init(id: String, title: String, sender:String, time: String, hasAttachments: Bool = false, isEncrypted: Bool = false, isFavorite: Bool = false) {
        
        self.init()
        self.id = id
        self.title = title
        self.sender = sender
        self.time = time
        self.hasAttachments = hasAttachments
        self.isEncrypted = isEncrypted
        self.isFavorite = isFavorite
    }
}
