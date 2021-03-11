//
//  JKBCryptRandom.swift
//  JKBCrypt
//
//  Created by Joe Kramer on 6/19/2015.
//  Copyright (c) 2015 Joe Kramer. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

class JKBCryptRandom : NSObject {

    /**
     Generates a random number between low and high and places it into the receiver.

     :param: first   The first
     :param: second  The second

     :returns: Int32  Random 32-bit number
     */
    class func generateNumberBetween(_ first: Int32, _ second: Int32) -> Int32 {
        var low : Int32
        var high : Int32

        if first <= second {
            low  = first
            high = second
        }
        else {
            low  = second
            high = first
        }

        let modular = UInt32((high - low) + 1)
        let random : UInt32 = arc4random()

        return Int32(random % modular) + low
    }

    /**
     Generates an optionally unique sequence of random numbers between low and high and places them into the sequence.

     :param: length      The length of the sequence (must be at least 1)
     :param: low         The low number (must be lower or equal to high).
     :param: high        The high number (must be equal or higher than low).
     :param: onlyUnique  TRUE if only unique values are to be generated, FALSE otherwise.

     The condition is checked that if `onlyUnique` is TRUE the `length` cannot exceed the range of `low` to `high`.

     :returns: [Int32]
     */
    class func generateNumberSequenceBetween(_ first: Int32, _ second: Int32, ofLength length: Int, withUniqueValues unique: Bool) -> [Int32] {
        if length < 1 {
            return [Int32]()
        }

        var sequence : [Int32] = [Int32](repeating: 0, count: length)
        if unique {
            if (first <= second && (length > Int(second - first) + 1)) ||
                (first > second  && (length > Int(first - second) + 1)) {
                return [Int32]()
            }

            var loop : Int = 0
            while loop < length {
                let number = JKBCryptRandom.generateNumberBetween(first, second)

                // If the number is unique, add it to the sequence
                if !JKBCryptRandom.isNumber(number, inSequence: sequence, ofLength: loop) {
                    sequence[loop] = number
                    loop += 1
                }
            }
        }
        else {
            // Repetitive values are allowed
            for i in 0 ..< length {
                sequence[i] = JKBCryptRandom.generateNumberBetween(first, second)
            }
        }

        return sequence
    }

    /**
     Randomly chooses a number from the provided sequence and places it into the receiver.

     :param: sequence    The sequence selected from (must not be nil and must be of at least `length` elements)
     :param: length      The length of the sequence (must be at least 1)

     :returns: Int? Int if `length` is properly set and `sequence` is not nil; nil otherwise.
     */
    class func chooseNumberFromSequence(_ sequence: [Int32], ofLength length: Int) -> Int32? {
        if length < 1 || length > sequence.count {
            return nil
        }

        // Generate a random index into the sequence
        let number = JKBCryptRandom.generateNumberBetween(0, Int32(length - 1))

        return sequence[Int(number)]
    }

    /**
     Returns true if the provided number appears within the sequence.

     :param: number      The number to search for in the sequence.
     :param: sequence    The sequence to search in (must not be nil and must be of at least `length` elements)
     :param: length      The length of the sequence to test (must be at least 1)

     :returns: Bool      TRUE if `number` is found in sequence, FALSE if not found.
     */
    class func isNumber(_ number: Int32, inSequence sequence: [Int32], ofLength length: Int) -> Bool {
        if length < 1 || length > sequence.count {
            return false
        }

        for i in 0 ..< length {
            if sequence[i] == number {
                // The number was found, return true
                return true
            }
        }

        // The number was not found, return false
        return false
    }

    /**
     Returns an NSData populated with bytes whose values range from 0 to 255.

     :param: length  The length of the resulting NSData (must be at least 1)

     :returns: NSData   NSData containing random bytes.
     */
    class func generateRandomDataOfLength(_ length: Int) -> Data {
        if length < 1 {
            return Data()
        }

        var sequence = JKBCryptRandom.generateNumberSequenceBetween(0, 255, ofLength: length, withUniqueValues: false)
        var randomData : [UInt8] = [UInt8](repeating: 0, count: length)

        for i in 0 ..< length {
            randomData[i] = UInt8(sequence[i])
        }

        return Data(bytes: UnsafePointer<UInt8>(randomData), count:length)
    }

    /**
     Returns an NSData populated with bytes whose values range from -128 to 127.

     :param: length  The length of the resulting NSData (must be at least 1)

     :returns: NSData   NSData containing random signed bytes.
     */
    class func generateRandomSignedDataOfLength(_ length: Int) -> Data {
        if length < 1 {
            return Data()
        }

        var sequence = JKBCryptRandom.generateNumberSequenceBetween(-128, 127, ofLength: length, withUniqueValues: false)
        var randomData : [Int8] = [Int8](repeating: 0, count: length)

        for i in 0 ..< length {
            randomData[i] = Int8(sequence[i])
        }

        return Data(bytes:randomData, count:length)
    }

    /**
     Returns a String populated with random characters.

     :param: length  The length of the resulting String (must be at least 1)

     :returns: String   String containing random ASCII encoded characters.
     */
    class func generateRandomStringOfLength(_ length: Int) -> String {
        if length < 1 {
            return String()
        }

        var sequence = JKBCryptRandom.generateNumberSequenceBetween(0, 255, ofLength: length, withUniqueValues: false)
        var randomString : String = String()

        for i in 0 ..< length {
            let nextCharacter = UnicodeScalar(UInt8(sequence[i]))
            randomString.append(String(nextCharacter))
        }

        // init?<S : SequenceType where UInt8 == UInt8>(bytes: S, encoding: NSStringEncoding)

        return randomString
    }
}
