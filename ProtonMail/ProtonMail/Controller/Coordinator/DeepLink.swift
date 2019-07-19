//
//  DeepLink.swift
//  ProtonMail - Created on 12/12/18.
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

class DeepLink {
    
    class Path {
        //
        var next: Path?
        weak var previous: Path?
        
        //
        var destination : String
        var sender: Any?
        
        init(dest: String, sender: Any? = nil) {
            self.destination = dest
            self.sender = sender
        }
    }
    
    
    /// Description
    ///
    /// - Parameters:
    ///   - dest: dest description
    ///   - sender: sender descriptio
    init(_ dest: String, sender: Any? = nil) {
        append(dest, sender: sender)
    }
    
    /// The head of the Linked List
    private(set) var head: Path?
    
    func append(_ dest: String, sender: Any? = nil) {
        let newNode = Path(dest: dest, sender: sender)
        append(newNode)
    }
    
    func append(_ path: Path) {
        let newNode = path
        if let lastNode = last {
            newNode.previous = lastNode
            lastNode.next = newNode
        } else {
            head = newNode
        }
    }
    
    var last: Path? {
        get {
            guard var node = head else {
                return nil
            }
            
            while let next = node.next {
                node = next
            }
            return node
        }
    }
    
    var empty: Bool {
        return head == nil
    }
    
    var first: Path? {
        get {
            return head
        }
    }
    
    var pop: Path? {
        get {
            return removeTop()
        }
    }
    
    private func removeTop() -> Path? {
        if let head = head {
            self.remove(path: head)
            return head
        }
        return nil
    }

    private func remove(path: Path) {
        let prev = path.previous
        let next = path.next
        
        if let prev = prev {
            prev.next = next
        } else {
            head = next
        }
        next?.previous = prev
        
        path.previous = nil
        path.next = nil
    }
}

