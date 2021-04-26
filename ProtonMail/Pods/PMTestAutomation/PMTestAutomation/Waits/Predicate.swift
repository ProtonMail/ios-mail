//
//  Condition.swift
//  PMTestAutomation
//
//  Created by denys zelenchuk on 10.05.21.
//

internal struct Predicate {
    static let enabled = NSPredicate(format: "isEnabled == true")
    static let disabled = NSPredicate(format: "isEnabled == false")
    static let hittable = NSPredicate(format: "hittable == true")
    static let doesNotExist = NSPredicate(format: "exists == false")
    static let exists = NSPredicate(format: "exists == true")
    static func labelEquals(_ label: String) -> NSPredicate {
       return NSPredicate(format: "label == '\(label)'")
    }
    static func titleEquals(_ title: String) -> NSPredicate {
       return NSPredicate(format: "title == '\(title)'")
    }
    static func valueEquals(_ value: String) -> NSPredicate {
       return NSPredicate(format: "value == '\(value)'")
    }
}
