//
//  Label.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/22/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


import CoreData

class Label: NSManagedObject {
    
    @NSManaged var color: String
    @NSManaged var isDisplay: Bool
    @NSManaged var labelID: String
    @NSManaged var name: String
    
 /// start at 1 , lower number on the top
    @NSManaged var order: NSNumber
    
    @NSManaged var message: Message
}
