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
        var sender: String?
        
        init(dest: String, sender: String? = nil) {
            self.destination = dest
            self.sender = sender
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.destination = try container.decode(String.self, forKey: .destination)
            self.sender = try? container.decode(String.self, forKey: .sender)
        }
    }
    
    
    /// Description
    ///
    /// - Parameters:
    ///   - dest: dest description
    ///   - sender: sender descriptio
    init(_ dest: String, sender: String? = nil) {
        append(dest, sender: sender)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let elements = try container.decode(Array<Path>.self, forKey: .elements)
        
        self.head = elements.first
        for (index, element) in elements.enumerated() {
            if index - 1 >= 0 {
                element.previous = elements[index - 1]
            }
            if index + 1 < elements.count {
                element.next = elements[index + 1]
            }
        }
    }
    
    /// The head of the Linked List
    private(set) var head: Path?
    
    func append(_ dest: String, sender: String? = nil) {
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
    
    /// Removes one from head and returns it
    var popFirst: Path? {
        get {
            return removeTop()
        }
    }
    
    /// Removes one from head and returns it
    var popLast: Path? {
        get {
            return removeBottom()
        }
    }
    
    private func removeTop() -> Path? {
        if let head = head {
            self.remove(path: head)
            return head
        }
        return nil
    }
    
    private func removeBottom() -> Path? {
        var current = self.head
        while let next = current?.next {
            current = next
        }
        current?.previous?.next = nil
        current?.previous = nil
        return current
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

extension DeepLink.Path: CustomDebugStringConvertible {
    var debugDescription: String {
        return "dest: \(self.destination), sender: \(self.sender))"
    }
}

extension DeepLink.Path: Equatable {
    static func == (lhs: DeepLink.Path, rhs: DeepLink.Path) -> Bool {
        return lhs.destination == rhs.destination
                && lhs.sender?.hashValue == rhs.sender?.hashValue
    }
}

extension DeepLink: CustomDebugStringConvertible {
    var debugDescription: String {
        var steps: Array<String> = []
        
        var current = head
        while current != nil {
            steps.append(current!.debugDescription)
            current = current!.next
        }

        return "[HEAD] -> " + steps.joined(separator: "\n      -> ")
    }
}

extension DeepLink.Path: Codable {
    enum CodingKeys: CodingKey { case destination, sender }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.destination, forKey: .destination)
        if let sender = self.sender {
            try container.encode(sender, forKey: .sender)
        }
    }
}

extension DeepLink: Codable {
    enum CodingKeys: CodingKey { case elements }
    enum Errors: Error { case empty }
    func encode(to encoder: Encoder) throws {
        var containter = encoder.container(keyedBy: CodingKeys.self)
        guard let head = self.head else { throw Errors.empty }
        
        var elements: Array<Path> = [head]
        var current = head
        while let next = current.next {
            elements.append(next)
            current = next
        }
        
        try containter.encode(elements, forKey: .elements)
    }
}
