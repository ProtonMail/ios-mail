//
//  Reusable.swift
//  PMUIFoundations
//
//  Created by Aaron Huánuco on 20/08/2020.
//

protocol Reusable: class {
    static var reuseIdentifier: String { get }
}

extension Reusable {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
