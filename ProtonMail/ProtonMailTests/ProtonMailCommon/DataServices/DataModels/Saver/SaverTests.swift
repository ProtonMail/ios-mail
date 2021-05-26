//
//  UserDefaultsSaverTests.swift
//  ProtonMail - Created on 12/18/18.
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
    

import XCTest
@testable import ProtonMail

class SaverTests: XCTestCase {
    
    private class StoreMock : KeyValueStoreProvider {        
        var log: String = ""
        func resetLog() {
            log = ""
        }
        var cachedData : [String: Any] = [:]
        func data(forKey key: String) -> Data? {
            log += "g-key"
            return cachedData[key] as? Data
        }
        
        func int(forKey key: String) -> Int? {
            log += "g-key"
            return cachedData[key] as? Int
        }

        func bool(forKey defaultName: String) -> Bool {
            log += "g-key"
            return cachedData[defaultName] as? Bool ?? false
        }
        
        func set(_ intValue: Int, forKey key: String) {
            log += "s-key"
            cachedData[key] = intValue
        }
        
        func set(_ data: Data, forKey key: String) {
            log += "s-key"
            cachedData[key] = data
        }

        func set(_ value: Bool, forKey defaultName: String) {
            log += "s-key"
            cachedData[defaultName] = value
        }
        
        func remove(forKey key: String) {
            log += "r-key"
            cachedData.removeValue(forKey: key)
        }
    }
    
    private class SaverTestsMock<T: Codable>: Saver<T> {
        convenience init(key: String, store: KeyValueStoreProvider, memory: Bool) {
            self.init(key: key, store: store, cachingInMemory: memory)
        }
    }
    private class CoableMockSub: Codable, Equatable {
        let sub1 : String
        let sub2 : Int
        let sub3 : Float
        var sub4 : Bool
        
        init(sub1 : String, sub2: Int, sub3: Float, sub4: Bool) {
            self.sub1 = sub1
            self.sub2 = sub2
            self.sub3 = sub3
            self.sub4 = sub4
        }
        public static func == (lhs: SaverTests.CoableMockSub, rhs: SaverTests.CoableMockSub) -> Bool {
            if lhs.sub1 != rhs.sub1 {
                return false
            }
            if lhs.sub2 != rhs.sub2 {
                return false
            }
            if lhs.sub3 != rhs.sub3 {
                return false
            }
            if lhs.sub4 != rhs.sub4 {
                return false
            }
            return true
        }
        
    }
    private class CoableMock: Codable, Equatable {
        let var1, var2: String
        let int1: Int
        var subObj : CoableMockSub

        init(var1: String, var2: String,
             int1: Int, subObj : CoableMockSub) {
            self.var1 = var1
            self.var2 = var2
            self.int1 = int1
            self.subObj = subObj
        }
        
        public static func == (lhs: SaverTests.CoableMock, rhs: SaverTests.CoableMock) -> Bool {
            if lhs.var2 != rhs.var2 {
                return false
            }
            if lhs.var1 != rhs.var1 {
                return false
            }
            if lhs.int1 != rhs.int1 {
                return false
            }
            if lhs.subObj != rhs.subObj {
                return false
            }
            return true
        }
    }
    
    
    func testCases() {
        let store = StoreMock()
        let saverCase1 = SaverTestsMock<Int>(key:"test-1", store: store, memory: true)
        saverCase1.set(newValue: 100)
        XCTAssert(saverCase1.get() == 100)
        XCTAssert(store.log == "s-key", store.log)
        saverCase1.set(newValue: nil)
        XCTAssert(saverCase1.get() == nil)
        XCTAssert(store.log == "s-keyr-keyg-key", store.log)
        saverCase1.set(newValue: 11)
        XCTAssert(saverCase1.get() == 11)
        XCTAssert(store.log == "s-keyr-keyg-keys-key", store.log)
        store.resetLog()
        let saverCase2 = SaverTestsMock<Int>(key:"test-2", store: store, memory: false)
        saverCase2.set(newValue: 1000)
        XCTAssert(saverCase2.get() == 1000)
        XCTAssert(store.log == "s-keyg-key", store.log)
        saverCase2.set(newValue: nil)
        XCTAssert(saverCase2.get() == nil)
        XCTAssert(store.log == "s-keyg-keyr-keyg-key", store.log)
        store.resetLog()
        let saverCase3 = SaverTestsMock<Int>(key:"test-1", store: store, memory: true)
        XCTAssert(saverCase3.get() == 11)
        XCTAssert(store.log == "g-key", store.log)
        XCTAssert(saverCase3.get() == 11)
        XCTAssert(store.log == "g-key", store.log)
        store.resetLog()
        
        let saverCase4 = SaverTestsMock<String>(key:"string-1", store: store, memory: true)
        saverCase4.set(newValue: "100")
        XCTAssert(saverCase4.get() == "100")
        XCTAssert(store.log == "s-key", store.log)
        saverCase4.set(newValue: nil)
        XCTAssert(saverCase4.get() == nil)
        XCTAssert(store.log == "s-keyr-keyg-key", store.log)
        saverCase4.set(newValue: "1001")
        XCTAssert(saverCase4.get() == "1001")
        XCTAssert(store.log == "s-keyr-keyg-keys-key", store.log)
        store.resetLog()
        let saverCase5 = SaverTestsMock<String>(key:"string-2", store: store, memory: false)
        saverCase5.set(newValue: "1000")
        XCTAssert(saverCase5.get() == "1000")
        XCTAssert(store.log == "s-keyg-key", store.log)
        saverCase5.set(newValue: nil)
        XCTAssert(saverCase5.get() == nil)
        XCTAssert(store.log == "s-keyg-keyr-keyg-key", store.log)
        store.resetLog()
        let saverCase6 = SaverTestsMock<String>(key:"string-1", store: store, memory: true)
        XCTAssert(saverCase6.get() == "1001")
        XCTAssert(store.log == "g-key", store.log)
        XCTAssert(saverCase6.get() == "1001")
        XCTAssert(store.log == "g-key", store.log)
        store.resetLog()

        let sub = CoableMockSub(sub1: "String1", sub2: 11, sub3: 0.4, sub4: true)
        let mock = CoableMock(var1: "String1", var2: "String2", int1: 100, subObj: sub)
        let saverCase7 = SaverTestsMock<CoableMock>(key:"object-1", store: store, memory: true)
        XCTAssert(saverCase7.get() == nil)
        XCTAssert(store.log == "g-key", store.log)
        saverCase7.set(newValue: mock)
        XCTAssert(saverCase7.get() == mock)
        XCTAssert(store.log == "g-keys-key", store.log)
        saverCase7.set(newValue: nil)
        XCTAssert(store.log == "g-keys-keyr-key", store.log)
        XCTAssert(saverCase7.get() == nil)
        XCTAssert(store.log == "g-keys-keyr-keyg-key", store.log)
        saverCase7.set(newValue: mock)
        XCTAssert(saverCase7.get() == mock)
        store.resetLog()
        
        mock.subObj.sub4 = false
        let saverCase8 = SaverTestsMock<CoableMock>(key:"object-1", store: store, memory: false)
        XCTAssert(saverCase8.get() != mock)
        XCTAssert(store.log == "g-key", store.log)
        XCTAssert(saverCase8.get() != mock)
        XCTAssert(store.log == "g-keyg-key", store.log)
        saverCase8.set(newValue: mock)
        XCTAssert(saverCase8.get() == mock)
        XCTAssert(store.log == "g-keyg-keys-keyg-key", store.log)
        saverCase8.set(newValue: nil)
        XCTAssert(saverCase8.get() == nil)
        XCTAssert(store.log == "g-keyg-keys-keyg-keyr-keyg-key", store.log)
        saverCase8.set(newValue: mock)
        XCTAssert(saverCase8.get() == mock)
        XCTAssert(store.log == "g-keyg-keys-keyg-keyr-keyg-keys-keyg-key", store.log)
        store.resetLog()
        
    }



}
