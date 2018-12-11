
//
//  CryptoTransformer.swift
//  ProtonMail - Created on 15/11/2018.
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
import CryptoSwift
import Crypto

public class StringCryptoTransformer: CryptoTransformer {
    // String -> Data
    public override func transformedValue(_ value: Any?) -> Any? {
        guard let string = value as? String else {
            return nil
        }
        
        do {
            let locked = try Locked<String>(clearValue: string, with: self.key)
            let result = locked.encryptedValue as NSData
            return result
        } catch let error {
            print(error)
            assert(false, "Error while encrypting value")
        }
        
        return nil
    }
    
    // Data -> String
    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            return nil
        }
        
        let locked = Locked<String>(encryptedValue: data)
        do {
            let string = try locked.unlock(with: self.key)
            return string
        } catch AES.Error.dataPaddingRequired {
            assert(false, "A bug in  CryptoSwift makes some LabelNames undecryptable")
        } catch let error {
            print(error)
            assert(false, "Error while decrypting value")
        }
        
        return nil
    }
}

public class CryptoTransformer: ValueTransformer {
    fileprivate var key: Keymaker.Key
    public init(key: Keymaker.Key) {
        self.key = key
    }
    
    public override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    public override class func allowsReverseTransformation() -> Bool {
        return true
    }
}
