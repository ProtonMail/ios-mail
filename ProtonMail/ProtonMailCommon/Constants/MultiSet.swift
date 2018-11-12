//
//  MultiSet.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/11/7.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class MultiSet<T: Hashable>
{
    typealias DataType = [T:Int]
    private var data: DataType
    
    init() {
        data = DataType()
    }
    
    subscript(_ query: T) -> Int? {
        get {
            return data[query]
        }
    }
    
    /**
     Insert an element
     */
    func insert(_ newData: T) {
        if let count = data[newData] {
            data.updateValue(count + 1, forKey: newData)
        } else {
            data[newData] = 1
        }
    }
    
    /**
     Remove an element
     */
    func remove(_ removeData: T) {
        if let count = data[removeData] {
            if count <= 1 {
                data.removeValue(forKey: removeData)
            } else {
                data.updateValue(count - 1, forKey: removeData)
            }
        }
    }
    
    /**
     Remove all specified elements
     */
    func removeAll(of removeData: T) {
        if let _ = data[removeData] {
            data.removeValue(forKey: removeData)
        }
    }
    
    /**
     Clears the multiset
     */
    func removeAll() {
        data.removeAll()
    }
    
    func allObjectsWithDuplicates() -> [T] {
        var result: [T] = []
        for member in data {
            for _ in 0..<member.value {
                result.append(member.key)
            }
        }
        return result
    }
    
    func allObjectsWithoutDuplicates() -> [T] {
        return data.map{$0.key}
    }
}

extension MultiSet: Sequence
{
    func makeIterator() -> DataType.Iterator {
        return data.makeIterator()
    }
}
