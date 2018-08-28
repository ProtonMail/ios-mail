//
//  Label.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/22/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData


public class Label: NSManagedObject {
    
    @NSManaged public var color: String
    @NSManaged public var isDisplay: Bool
    @NSManaged public var labelID: String
    @NSManaged public var name: String
    @NSManaged public var type: NSNumber
    @NSManaged public var exclusive: Bool
    
 /// start at 1 , lower number on the top
    @NSManaged public var order: NSNumber
    
    @NSManaged public var messages: NSSet
    @NSManaged public var emails: NSSet
}
