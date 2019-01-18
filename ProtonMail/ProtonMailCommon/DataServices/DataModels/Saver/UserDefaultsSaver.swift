//
//  UserDefaultsSaver.swift
//  ProtonMail - Created on 07/11/2018.
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

class UserDefaultsSaver<T>: Saver<T> where T: Codable {
    convenience init(key: String) {
        self.init(key: key, store: SharedCacheBase.getDefault())
    }
}

extension UserDefaults: KeyValueStoreProvider {
    func intager(forKey key: String) -> Int? {
        return self.object(forKey: key) as? Int
    }
    
    func data(forKey key: String) -> Data? {
        return self.object(forKey: key) as? Data
    }
    
    
    func set(_ data: Int, forKey key: String) {
        self.setValue(data, forKey: key)
    }

    func set(_ data: Data, forKey key: String) {
        self.setValue(data, forKey: key)
    }
    
    func removeItem(forKey key: String) {
        self.removeObject(forKey: key)
    }

}
