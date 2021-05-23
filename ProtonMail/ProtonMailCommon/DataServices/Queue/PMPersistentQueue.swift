//
//  PMPersistentQueue.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

protocol PMPersistentQueueProtocol {
    var count: Int { get }
    func queueArray() -> [Any]
    func add(_ uuid: UUID, object: NSCoding) -> UUID
    func add(_ object: NSCoding) -> UUID
    func insert(uuid: UUID, object: NSCoding, index: Int) -> UUID
    func update(uuid: UUID, object: NSCoding)
    func clearAll()
    func next() -> (elementID: UUID, object: Any)?
    func remove(_ elementID: UUID) -> Bool
    func removeAllObject<T>(of target: [String: T]) where T: Equatable
    func remove<T>(key: String, value: T) where T: Equatable
    func contains(_ uuid: UUID) -> Bool
}

protocol DataSaverProtocol {
    func save(data: Data, url: URL) throws
}

class DataSaver: DataSaverProtocol {

    func save(data: Data, url: URL) throws {
        try data.write(to: url, options: [.atomic])
    }
}


protocol BackupExcluderProtocol {
    func excludeFromBackup(url: inout URL)
}

class BackupExcluder: BackupExcluderProtocol {

    func excludeFromBackup(url: inout URL) {
        url.excludeFromBackup()
    }

}

@objcMembers class PMPersistentQueue: NSObject, PMPersistentQueueProtocol {
    struct Constant {
        static let name = "writeQueue"
        static let miscName = "miscQueue"
    }
    
    struct Key {
        static let elementID = "elementID"
        static let object = "object"
    }
    
    fileprivate var queueURL: URL
    fileprivate let queueName: String

    private let dataSaver: DataSaverProtocol
    private let backupExcluder: BackupExcluderProtocol
    
    private var serialQueue = DispatchQueue(label: "PMPersistentQueue.serialQueue")
    
    dynamic fileprivate(set) var queue: [Any] {
        didSet {
            let data = NSKeyedArchiver.archivedData(withRootObject: self.queue)
            do {
                try dataSaver.save(data: data, url: self.queueURL)
                backupExcluder.excludeFromBackup(url: &queueURL)
            } catch {
                PMLog.D("Unable to save queue: \(self.queue as NSArray)\n to \(self.queueURL.absoluteString)")
            }
        }
    }
    
    var count: Int {
        return self.queue.count
    }
    
    func queueArray() -> [Any] {
        return self.queue
    }
    
    init(queueName: String,
         dataSaver: DataSaverProtocol = DataSaver(),
         backupExcluder: BackupExcluderProtocol = BackupExcluder()) {
        self.queueName = "\(QueueConstant.queueIdentifer).\(queueName)"
        self.dataSaver = dataSaver
        self.backupExcluder = backupExcluder
        #if APP_EXTENSION
        // we do not want to persist queue in Extensions so far, cuz if queue contains some crashy/memory abusing operation it will continue crashing forever. We'll just put the url outside our sandbox to OS will not let us save the file
        // TODO: persist queue in CoreData so the app will have access to all the queues, but every Extension process - only to his own
        self.queueURL = URL(string: "/")!
        #else
        self.queueURL = FileManager.default.applicationSupportDirectoryURL.appendingPathComponent(self.queueName)
        #endif
        if let data = try? Data(contentsOf: queueURL) {
            self.queue = (NSKeyedUnarchiver.unarchiveObject(with: data) ?? []) as! [Any]
        }
        else {
            self.queue = []
        }
        super.init()
    }
    
    func add(_ uuid: UUID, object: NSCoding) -> UUID {
        self.serialQueue.sync {
            let element = [Key.elementID : uuid, Key.object : object] as [String : Any]
            self.queue.append(element)
        }
        return uuid
    }
    
    /// Adds an object to the persistent queue.
    func add(_ object: NSCoding) -> UUID {
        let uuid = UUID()
        return self.add(uuid, object: object)
    }
    
    func insert(uuid: UUID, object: NSCoding, index: Int) -> UUID {
        self.serialQueue.sync {
            let element = [Key.elementID : uuid, Key.object : object] as [String : Any]
            self.queue.insert(element, at: index)
        }
        return uuid
    }
    
    func update(uuid: UUID, object: NSCoding) {
        self.serialQueue.sync {
            let indexOfQueueToUpdate = self.queue.compactMap { $0 as? [String: Any] }
                .firstIndex(where: { element in
                    let id = element[Key.elementID] as? UUID
                    return id == uuid
                })
            if let index = indexOfQueueToUpdate {
                let element = [Key.elementID : uuid, Key.object : object] as [String : Any]
                self.queue[index] = element
            }
        }
    }
    
    func clearAll() {
        self.serialQueue.sync {
            queue.removeAll()
        }
    }
    
    /// Returns the next item in the persistent queue or nil, if the queue is empty.
    func next() -> (elementID: UUID, object: Any)? {
        var result: (elementID: UUID, object: Any)? = nil
        self.serialQueue.sync {
            if let element = queue.first as? [String : Any] {
                result = (element[Key.elementID] as! UUID, element[Key.object]!)
            }
        }
        return result
    }
    
    /// Removes an element from the persistent queue
    func remove(_ elementID: UUID) -> Bool {
        var isFound = false
        self.serialQueue.sync {
            let index = self.queue
                .compactMap { $0 as? [String: Any] }
                .compactMap { $0[Key.elementID] as? UUID }
                .firstIndex(where: { $0 == elementID })
            if let idx = index {
                queue.remove(at: idx)
                isFound = true
            }
        }
        return isFound
    }
    
    func removeAllObject<T>(of target: [String: T]) where T: Equatable {
        self.serialQueue.sync {
            self.queue.removeAll { (element) -> Bool in
                if let elementDict = element as? [String: Any] {
                    var result = true
                    if let dict = elementDict[Key.object] as? [String: Any] {
                        for (key, value) in target {
                            if let v = dict[key] as? T, v == value {
                                break
                            } else {
                                result = false
                            }
                        }
                    }
                    return result
                }
                return false
            }
        }
    }
    
    func remove<T>(key: String, value: T) where T: Equatable {
        self.serialQueue.sync {
            self.queue.removeAll { (element) -> Bool in
                if let elementDict = element as? [String : Any],
                    let object = elementDict[Key.object] as? [String : Any],
                    let found = object[key] as? T,
                    found == value {
                    return true
                }
                return false
            }
        }
    }
    
    func contains(_ uuid: UUID) -> Bool {
        self.serialQueue.sync {
            return self.queue.contains { (element) -> Bool in
                if let elementDict = element as? [String: Any],
                   let id = elementDict[Key.elementID] as? UUID {
                    return id == uuid
                }
                return false
            }
        }
    }
    
    func moveToFirst(of uuid: UUID) -> Bool {
        self.serialQueue.sync {
            if let index = self.queue.firstIndex(where: { (element) -> Bool in
                if let elementDict = element as? [String: Any],
                   let id = elementDict[Key.elementID] as? UUID {
                    return id == uuid
                }
                return false
            }) {
                guard index < self.queue.endIndex else {
                    return false
                }
                let element = self.queue.remove(at: index)
                self.queue.insert(element, at: 0)
                return true
            }
            return false
        }
    }
}
