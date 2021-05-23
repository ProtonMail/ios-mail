//
//  DeepLink.swift
//  ProtonMail - Created on 12/12/18.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

public class DeepLink {

    class Node {
        //
        var next: Node?
        weak var previous: Node?

        //
        var name: String
        var value: String?

        init(name: String, value: String? = nil) {
            self.name = name
            self.value = value
        }

        convenience init<T>(name: String, value: T? = nil) where T: RawRepresentable, T.RawValue == String {
            self.init(name: name, value: value?.rawValue)
        }

        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .destination)
            self.value = try? container.decode(String.self, forKey: .sender)
        }
    }

    init(_ dest: String, sender: String? = nil) {
        let node = Node(name: dest, value: sender)
        self.append(node)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let elements = try container.decode(Array<Node>.self, forKey: .elements)

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
    private(set) var head: Node?

    func append(_ path: Node) {
        let newNode = path
        if let lastNode = last {
            newNode.previous = lastNode
            lastNode.next = newNode
        } else {
            head = newNode
        }
    }

    var last: Node? {
        guard var node = head else {
            return nil
        }

        while let next = node.next {
            node = next
        }
        return node
    }

    var empty: Bool {
        return head == nil
    }

    var first: Node? {
        return head
    }

    /// Removes one from head and returns it
    var popFirst: Node? {
        return removeTop()
    }

    /// Removes one from head and returns it
    var popLast: Node? {
        return removeBottom()
    }

    func cut(until path: Node) {
        guard self.contains(path) else { return }
        while self.last != path && self.head?.next != nil {
            _ = self.removeBottom()
        }
    }

    func contains(_ path: Node) -> Bool {
        var current = self.head
        while let next = current?.next {
            if current == path {
                return true
            }
            current = next
        }
        return current == path
    }

    private func removeTop() -> Node? {
        if let head = head {
            self.remove(path: head)
            return head
        }
        return nil
    }

    private func removeBottom() -> Node? {
        var current = self.head
        while let next = current?.next {
            current = next
        }
        current?.previous?.next = nil
        current?.previous = nil
        return current
    }

    private func remove(path: Node) {
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

extension DeepLink.Node: CustomDebugStringConvertible {
    var debugDescription: String {
        return "dest: \(self.name), sender: \(String(describing: self.value)))"
    }
}

extension DeepLink.Node: Equatable {
    static func == (lhs: DeepLink.Node, rhs: DeepLink.Node) -> Bool {
        return lhs.name == rhs.name
                && lhs.value?.hashValue == rhs.value?.hashValue
    }
}

extension DeepLink: CustomDebugStringConvertible {
    public var debugDescription: String {
        var steps: [String] = []

        var current = head
        while current != nil {
            steps.append(current!.debugDescription)
            current = current!.next
        }

        return "[HEAD] -> " + steps.joined(separator: "\n      -> ")
    }
}

extension DeepLink.Node: Codable {
    enum CodingKeys: CodingKey { case destination, sender }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .destination)
        if let sender = self.value {
            try container.encode(sender, forKey: .sender)
        }
    }
}

extension DeepLink: Codable {
    enum CodingKeys: CodingKey { case elements }
    enum Errors: Error { case empty }
    public func encode(to encoder: Encoder) throws {
        var containter = encoder.container(keyedBy: CodingKeys.self)
        guard let head = self.head else { throw Errors.empty }

        var elements: [Node] = [head]
        var current = head
        while let next = current.next {
            elements.append(next)
            current = next
        }

        try containter.encode(elements, forKey: .elements)
    }
}
