//
//  StringCryptoTransformer.swift
//  ProtonMail - Created on 14/11/2018.
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
import Keymaker


class StringCryptoTransformer: CryptoTransformer<String> { }

class CryptoTransformer<T: Codable>: ValueTransformer {
    private var key: Keymaker.Key
    init(key: Keymaker.Key) {
        self.key = key
    }
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    // String -> Data
    override func transformedValue(_ value: Any?) -> Any? {
        guard let string = value as? T else {
            return nil
        }
        
        do {
            let locked = try Locked<[T]>(clearValue: [string], with: key) // ugly wrap
            return locked.encryptedValue as NSData
        } catch let error {
            print(error)
            assert(false, "Wrong key")
        }
        
        return nil
    }
    
    // Data -> String
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? NSData else {
            return nil
        }
        
        let locked = Locked<[T]>(encryptedValue: data as Data)  // ugly wrap
        
        do {
            let string = try locked.unlock(with: key).first
            return string
        } catch let error {
            print(error)
            assert(false, "Wrong key")
        }
        
        return nil
    }
}
