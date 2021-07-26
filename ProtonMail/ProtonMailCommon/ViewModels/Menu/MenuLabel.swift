//
//  MenuLabel.swift
//  ProtonMail
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
final class MenuLabel: NSObject {

    let location: LabelLocation
    let name: String
    private(set) var parentID: String?
    // To sort labels only
    let path: String
    let textColor: String
    let iconColor: String
    let type: PMLabelType
    let order: Int
    /// is sub labels expand?
    var expanded: Bool = true
    var subLabels = [MenuLabel]()
    /// The unread number that includes sub labels
    var aggreateUnread: Int = 0
    /// Unread number of the label
    var unread: Int = 0
    var isSelected: Bool = false
    let notify: Bool

    /// Level of the label
    /// ```
    /// .
    /// └── Label <= indentationLevel = 0
    ///     └── Child label 1 <= indentationLevel = 1
    ///         └── Child label 2 <= indentationLevel = 2
    /// ```
    var indentationLevel: Int = 0

    /// level include self
    /// ```
    /// .
    /// └── Label <= deep level = 3
    ///     └── Child label 1 <= deep level = 2
    ///         └── Child label 2 <= deep level = 1
    /// ```
    var deepLevel: Int {
        var level: Int = 1
        if !self.subLabels.isEmpty {
            level = 2
        }
        if self.subLabels.contains(where: { !$0.subLabels.isEmpty }) {
            level = 3
        }

        return level
    }

    init(id: String,
         name: String,
         parentID: String?,
         path: String,
         textColor: String,
         iconColor: String,
         type: Int,
         order: Int,
         notify: Bool) {
        self.location = LabelLocation(id: id)
        self.name = name
        self.path = path
        self.parentID = parentID
        self.textColor = textColor
        self.iconColor = iconColor
        self.type = PMLabelType(rawValue: type) ?? .unknown
        self.order = order
        self.notify = notify
    }

    init(location: LabelLocation) {
        self.location = location
        self.name = location.localizedTitle
        self.parentID = nil
        self.path = location.localizedTitle
        self.textColor = "#FFFFFF"
        self.iconColor = "#FFFFFF"
        self.type = .folder
        self.order = 1
        self.notify = true
    }

    func set(parentID: String) {
        self.parentID = parentID
    }

    func contain(item: MenuLabel) -> Bool {
        guard let parentID = item.parentID else {
            return false
        }

        if self.location.labelID == parentID {
            return true
        }

        for label in self.subLabels {
            if label.contain(item: item) {
                return true
            }
        }
        return false
    }

    /// Check if it exceeds indentation level constraint after inserting the item
    func canInsert(item: MenuLabel) -> Bool {
        if self.contain(item: item) { return false }

        let maxiumLevel: Int = 2
        let newLevel = self.indentationLevel + item.deepLevel
        return newLevel <= maxiumLevel
    }

    /// Shoud remove, use setupIndentationByPath()
    /// The folder drag function need this
    /// I don't have time to improve the functionality
    func increseIndentationLevel(diff: Int) {
        self.indentationLevel += diff
        for sub in self.subLabels {
            sub.increseIndentationLevel(diff: diff)
        }
    }

    func setupIndentationByPath() {
        let paths = path.split(separator: "/")
        var level = paths.count
        for path in paths {
            guard let char = path.last else { continue }
            if char == "\\" && path != paths.last {
                level -= 1
            }
        }
        self.indentationLevel = level - 1
    }

    /// Flatten all subfolders
    /// - Returns: all subfolders, no ordered, no contain the root label
    func flattenSubFolders() -> [MenuLabel] {
        self.subLabels.flatMap { $0.subLabels } + self.subLabels
    }
}

/* drag and drop related
extension MenuLabel: NSItemProviderReading {
    static var readableTypeIdentifiersForItemProvider: [String] {
        [kUTTypeData as String]
    }

    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> MenuLabel {
        let menu = MenuLabel(location: .inbox)
        
        return menu
    }
    
    
}

extension MenuLabel: NSItemProviderWriting {


    static var writableTypeIdentifiersForItemProvider: [String] {
        [kUTTypeData as String]
    }

    func loadData(withTypeIdentifier typeIdentifier: String,
                  forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {

        let dic: [String: Any] = [
            "id": location.labelID,
            "name": name,
            "parentID": parentID ?? "",
            "iconColor": iconColor,
            "indentationLevel": indentationLevel
        ]
        guard let data = dic.json().data(using: .utf8) else {
            let err = NSError(domain: "aa", code: -1, localizedDescription: "")
            completionHandler(nil, err)
            return nil
        }
        completionHandler(data, nil)
        return nil
    }
    
    
}
*/
extension Array where Element == MenuLabel {

    init(labels: [Label], previousRawData: [MenuLabel]) {
        var datas: [MenuLabel] = []
        for item in labels {
            let label = MenuLabel(id: item.labelID,
                                  name: item.name,
                                  parentID: item.parentID,
                                  path: item.path,
                                  textColor: "#FFFFFF",
                                  iconColor: item.color,
                                  type: item.type.intValue,
                                  order: item.order.intValue,
                                  notify: item.notify.boolValue)
            if let oldData = previousRawData.first(where: { $0.location.labelID == item.labelID }) {
                // retain state
                label.expanded = oldData.expanded
                label.isSelected = oldData.isSelected
            }
            datas.append(label)
        }
        self = datas
    }

    /// Get the total number of items in array, including subLabels
    /// - Returns: Total number of items
    func getNumberOfRows() -> Int {
        var num = 0
        for label in self {
            // self
            num += 1
            guard label.expanded else { continue }
            // sub labels
            num += label.subLabels.getNumberOfRows()
        }
        return num
    }

    /// Get the item by the given indexPath
    /// Works for any MenuLabel but this function is main for folder type
    /// Folder type has subLables, it needs extra work to get the item
    /// - Parameter indexPath: indexPath
    /// - Returns: MenuLabel
    func getFolderItem(by indexPath: IndexPath) -> MenuLabel? {
        let row = indexPath.row + 1
        var num = 0
        // DFS
        var queue: [MenuLabel] = self
        while !queue.isEmpty {
            let label = queue.remove(at: 0)
            num += 1
            if row == num {
                return label
            }
            guard label.expanded else { continue }
            for sub in label.subLabels.reversed() {
                queue.insert(sub, at: 0)
            }
        }
        return nil
    }

    func getRootItem(of label: MenuLabel) -> MenuLabel? {
        var root: MenuLabel? = label
        while true {
            guard let parentID = root?.parentID else {
                return root
            }
            if parentID.isEmpty {
                return root
            }
            root = self.getLabel(of: parentID)
        }
    }

    func getLabel(of labelID: String) -> MenuLabel? {
        // DFS
        var queue: [MenuLabel] = self
        while !queue.isEmpty {
            let label = queue.remove(at: 0)
            if label.location.labelID == labelID {
                return label
            }

            guard label.expanded else { continue }
            for sub in label.subLabels.reversed() {
                queue.insert(sub, at: 0)
            }
        }
        return nil
    }

    // Get the row of the given labelID
    func getRow(of labelID: String) -> Int? {
        var num = 0
        // DFS
        var queue: [MenuLabel] = self
        while !queue.isEmpty {
            let label = queue.remove(at: 0)
            if label.location.labelID == labelID {
                return num
            }
            num += 1
            guard label.expanded else { continue }
            for sub in label.subLabels.reversed() {
                queue.insert(sub, at: 0)
            }
        }
        return nil
    }

    /// Sort out menu data from raw datas
    /// - Returns: (LabelItems, FolderItems)
    func sortoutData() -> ([MenuLabel], [MenuLabel]) {
        let labelItems = self.filter { $0.type == .label }

        var rawFolders: [MenuLabel] = self.filter { $0.type == .folder }
        rawFolders.forEach { $0.setupIndentationByPath() }
        rawFolders.sort(by: { $0.indentationLevel <= $1.indentationLevel })

        let indexes: [Int] = [Int](0..<rawFolders.count)

        var folders = [MenuLabel]()
        for index in indexes.reversed() {
            let label = rawFolders[index]

            guard let parentID = label.parentID,
                  let parentIdx = rawFolders.firstIndex(where: { $0.location.labelID == parentID }) else {
                folders.insert(label, at: 0)
                continue
            }
            rawFolders[parentIdx].subLabels.insert(label, at: 0)
        }
        folders.folderSorted()
        return (labelItems, folders)
    }

    private mutating func folderSorted() {
        self.sort(by: { $0.order < $1.order })
        for label in self {
            label.subLabels.folderSorted()
        }
    }
}
