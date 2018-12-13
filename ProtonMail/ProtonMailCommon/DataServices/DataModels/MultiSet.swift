//
//  MultiSet.swift
//  ProtonMail - Created on 2018/11/7.
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

class MultiSet<T: Hashable> {
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

extension MultiSet: Sequence {
    func makeIterator() -> DataType.Iterator {
        return data.makeIterator()
    }
}
