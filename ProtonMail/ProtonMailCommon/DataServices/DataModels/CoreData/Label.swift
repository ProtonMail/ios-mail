//
//  Label.swift
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


// lableID 
//    case draft = 1
//    case inbox = 0
//    case outbox = 2
//    case spam = 4
//    case archive = 6
//    case trash = 3
//    case allmail = 5
//    case starred = 10


extension Label {
    
    var spam : Bool {
        get {
            return self.labelID == "4"
        }
    }
    
    var trash : Bool {
        get {
            return self.labelID == "3"
        }
    }
    
    var draft : Bool {
        get {
            return self.labelID == "1"
        }
    }
}
