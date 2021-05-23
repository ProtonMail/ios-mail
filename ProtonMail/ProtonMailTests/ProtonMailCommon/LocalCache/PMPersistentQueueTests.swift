//
//  PMPersistentQueueTests.swift
//  ProtonMailTests
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

import XCTest

@testable import ProtonMail

class PMPersistentQueueTests: XCTestCase {
    var sut: PMPersistentQueue!
    var dataSaverSpy: MockDiskSaver!
    var backupExcluderDumb: MockBackupExcluder!
    let queueName = "TestQueue"
    
    override func setUp() {
        super.setUp()
        self.backupExcluderDumb = MockBackupExcluder()
        self.dataSaverSpy = MockDiskSaver()
        self.sut = PMPersistentQueue(queueName: self.queueName,
                                     dataSaver: dataSaverSpy,
                                     backupExcluder: backupExcluderDumb)
    }
    
    override func tearDown() {
        super.tearDown()
        self.backupExcluderDumb = nil
        self.dataSaverSpy = nil
        self.sut = nil
    }
    
    func testSaver() {
        let numberOfTestQueues = 3
        createTestQueues(numberOfQueues: numberOfTestQueues)
        
        XCTAssertEqual(self.dataSaverSpy.invokedSave.count, numberOfTestQueues)
        XCTAssertEqual(self.backupExcluderDumb.triggerTime, numberOfTestQueues)
    }

    func testAddingObjectToQueue() {
        let numberOfQueues = 10
        createTestQueues(numberOfQueues: numberOfQueues)

        XCTAssertEqual(sut.count, numberOfQueues)
        
        let queue = sut.queueArray()
        XCTAssertEqual(queue.count, numberOfQueues)

        let queuesNumbers = queue.getQueuesNumbers()
        let queuesUUIDs = queue.getQueuesUUIDs()

        XCTAssertEqual(queuesNumbers, (0..<numberOfQueues).map { $0 })
        XCTAssertEqual(queuesUUIDs.count, numberOfQueues)
    }
    
    func testAddingObjectConcurrentlyToQueue() {
        let numberOfQueues = 20
        DispatchQueue.concurrentPerform(iterations: numberOfQueues) { number in
            createTestQueue(number: number)
        }

        XCTAssertEqual(sut.count, numberOfQueues)
        
        let queue = sut.queueArray()
        XCTAssertEqual(queue.count, numberOfQueues)
        let queuesNumbers = queue.getQueuesNumbers()
        let queuesUUIDs = queue.getQueuesUUIDs()

        XCTAssertEqual(queuesNumbers.count, numberOfQueues)
        XCTAssertEqual(queuesUUIDs.count, numberOfQueues)
    }
    
    func testClearAllObjectInQueue() {
        let numberOfQueues = 20
        createTestQueues(numberOfQueues: numberOfQueues)
        
        XCTAssertEqual(sut.count, numberOfQueues)
        sut.clearAll()
        XCTAssertEqual(sut.count, 0)
    }
    
    func testGetNilWhileCallingNextInEmptyQueue() {
        XCTAssertEqual(sut.count, 0)
        XCTAssertNil(sut.next())
    }
    
    func testGetFirstObjectInQueue() {
        let numberOfQueues = 10
        createTestQueues(numberOfQueues: numberOfQueues)
        XCTAssertEqual(sut.count, numberOfQueues)

        let object = sut.next()
        XCTAssertNotNil(object)
        let dic = object?.1 as? NSDictionary
        XCTAssertNotNil(dic)

        let num = dic?["Test"] as? NSNumber
        XCTAssertNotNil(num)
        XCTAssertEqual(num?.intValue, 0)

        XCTAssertEqual(sut.count, numberOfQueues)
    }
    
    func testUpdateObjectInQueue() {
        let numberOfQueues = 10
        createTestQueues(numberOfQueues: numberOfQueues)
        XCTAssertEqual(sut.count, numberOfQueues)
        
        let object = sut.next()
        XCTAssertNotNil(object)
        
        let dic: [String: String] = ["Test": "updated"]
        self.sut.update(uuid: object?.elementID ?? UUID(), object: dic as NSCoding)
        
        let newObj = sut.next()
        let data = newObj?.object as? [String: String]
        XCTAssertEqual(dic["Test"], data?["Test"])
        
    }
    
    func testInsertObjectInQueue() {
        let numberOfQueues = 10
        createTestQueues(numberOfQueues: numberOfQueues)
        XCTAssertEqual(sut.count, numberOfQueues)
        
        let dic: [String: String] = ["Test": "updated"]
        let uuid = UUID()
        _ = self.sut.insert(uuid: uuid, object: dic as NSCoding, index: 0)
        
        let object = sut.next()
        XCTAssertEqual(uuid, object?.elementID)
        
        let data = object?.object as? [String: String]
        XCTAssertEqual(dic["Test"], data?["Test"])
        
    }
    
    func testRemoveSpecificObject() {
        let numberOfQueues = 10
        createTestQueues(numberOfQueues: numberOfQueues)
        XCTAssertEqual(sut.count, numberOfQueues)
        
        let object = sut.next()
        let uuid = object?.0
        XCTAssertNotNil(uuid)
        
        XCTAssertTrue(sut.remove(uuid ?? UUID()))
        XCTAssertEqual(sut.count, 9)
        
        let queue = sut.queueArray()
        XCTAssertEqual(queue.count, 9)
        let queueusNumbers = queue.getQueuesNumbers()
        let queueUUIDs = queue.getQueuesUUIDs()

        XCTAssertEqual(queueusNumbers.count, 9)
        XCTAssertEqual(queueUUIDs.count, 9)
        
        XCTAssertFalse(queueusNumbers.contains(0))
        XCTAssertFalse(queueUUIDs.contains(uuid ?? UUID()))
    }
    
    func testRemoveAllSameObjectsFromQueue() {
        let initialNumberOfQueues = 10
        createTestQueues(numberOfQueues: initialNumberOfQueues)
        XCTAssertEqual(sut.count, initialNumberOfQueues)

        createTestQueue(number: 5)
        
        XCTAssertEqual(sut.count, initialNumberOfQueues + 1)
        
        sut.remove(key: "Test", value: NSNumber(value: 5))
        
        XCTAssertEqual(sut.count, initialNumberOfQueues - 1)
        
        let queue = sut.queueArray()
        XCTAssertEqual(queue.count, initialNumberOfQueues - 1)
        let queuesNumbers = queue.getQueuesNumbers()

        XCTAssertEqual(queuesNumbers.count, initialNumberOfQueues - 1)
        
        XCTAssertFalse(queuesNumbers.contains(5))
    }
    
    func testRemoveByDictionaryTarget() {
        let numberOfQueues = 10
        createTestQueues(numberOfQueues: numberOfQueues)
        XCTAssertEqual(sut.count, numberOfQueues)
        
        let target = ["Test": NSNumber(value: 5)]
        sut.removeAllObject(of: target)
        
        XCTAssertEqual(sut.count, numberOfQueues - 1)
    }
    
    func testRemoveByWrongTarget() {
        let numberOfQueues = 10
        createTestQueues(numberOfQueues: numberOfQueues)

        XCTAssertEqual(sut.count, numberOfQueues)

        let target = ["Test": NSNumber(value: 11)]
        sut.removeAllObject(of: target)

        XCTAssertEqual(sut.count, numberOfQueues)
    }
    
    func testContains() {
        let numberOfQueues = 10
        createTestQueues(numberOfQueues: numberOfQueues)
        XCTAssertEqual(sut.count, numberOfQueues)
        
        let dict = NSMutableDictionary()
        dict["Test"] = NSNumber(value: 11)
        let id = sut.add(dict)
        
        XCTAssertTrue(sut.contains(id))
    }
    
    func testDoNotContain() {
        let numberOfQueues = 10
        createTestQueues(numberOfQueues: numberOfQueues)
        XCTAssertEqual(sut.count, numberOfQueues)
        
        XCTAssertFalse(sut.contains(UUID()))
    }
    
    func testMoveToFirst() {
        let numberOfQueues = 10
        createTestQueues(numberOfQueues: numberOfQueues)
        XCTAssertEqual(sut.count, numberOfQueues)
        
        let dict = NSMutableDictionary()
        dict["Test"] = NSNumber(value: 11)
        let id = sut.add(dict)
        
        XCTAssertNotEqual(sut.next()?.elementID, id)
        XCTAssertTrue(sut.moveToFirst(of: id))
        XCTAssertEqual(sut.next()?.elementID, id)
    }
    
    func testMoveToFirstWithUnknownID() {
        let dict = NSMutableDictionary()
        dict["Test"] = NSNumber(value: 11)
        let id = sut.add(dict)

        let numberOfQueues = 10
        createTestQueues(numberOfQueues: numberOfQueues)
        XCTAssertEqual(sut.count, numberOfQueues + 1)
        
        XCTAssertEqual(sut.next()?.elementID, id)
        XCTAssertFalse(sut.moveToFirst(of: UUID()))
        XCTAssertEqual(sut.next()?.elementID, id)
    }
}

extension PMPersistentQueueTests {
    fileprivate func createTestData(numOfData: Int) -> Int {
        for i in 0..<numOfData {
            let dict = NSMutableDictionary()
            dict["Test"] = NSNumber(value: i)
            _ = sut.add(dict)
        }
        return numOfData
    }
}

private extension PMPersistentQueueTests {

    func createTestQueues(numberOfQueues: Int) {
        (0..<numberOfQueues)
            .map { ["Test": NSNumber(value: $0)] as NSCoding }
            .forEach { _ = sut.add($0) }
    }

    func createTestQueue(number: Int) {
        _ = sut.add(["Test": NSNumber(value: number)] as NSCoding)
    }

}

private extension Array where Element == Any {

    func getQueuesNumbers() -> [Int] {
        compactMap {
            guard let dict = $0 as? [String: Any],
                  let object = dict["object"] as? [String: Any],
                  let number = object["Test"] as? NSNumber else { return nil }
            return number.intValue
        }
    }

    func getQueuesUUIDs() -> [UUID] {
        compactMap {
            guard let dict = $0 as? [String: Any], let uuid = dict["elementID"] as? UUID else { return nil }
            return uuid
        }
    }

}
