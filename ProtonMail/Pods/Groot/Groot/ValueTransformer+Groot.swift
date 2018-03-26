// ValueTransformer+Groot.swift
//
// Copyright (c) 2014-2016 Guillermo Gonzalez
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

extension ValueTransformer {

    /// Registers a value transformer with a given name and transform function.
    ///
    /// - parameter name:      The name of the transformer.
    /// - parameter transform: The function that performs the transformation.
    public class func setValueTransformer<T, U>(withName name: String, transform: @escaping (T) -> (U?)) {
        grt_setValueTransformer(withName: name) { value in
            (value as? T).flatMap {
                transform($0)
            }
        }
    }

    /// Registers a reversible value transformer with a given name and transform functions.
    ///
    /// - parameter name:             The name of the transformer.
    /// - parameter transform:        The function that performs the forward transformation.
    /// - parameter reverseTransform: The function that performs the reverse transformation.
    public class func setValueTransformer<T, U>(withName name: String, transform: @escaping (T) -> (U?), reverseTransform: @escaping (U) -> (T?)) {
        grt_setValueTransformer(withName: name, transform: { value in
            return (value as? T).flatMap {
                transform($0)
            }
            }, reverseTransform: { value in
                return (value as? U).flatMap {
                    reverseTransform($0)
                }
        })
    }

    /// Registers a dictionary transformer with a given name and transform function.
    ///
    /// Dictionary transformers can be associated with Core Data entities in the user info
    /// dictionary by using the `JSONDictionaryTransformerName` key.
    ///
    /// - parameter name:      The name of the transformer.
    /// - parameter transform: The function that performs the transformation.
    public class func setDictionaryTransformer(withName name: String, transform: @escaping ([String: AnyObject]) -> ([String: AnyObject]?)) {
        grt_setDictionaryTransformer(withName: name) { value in
            if let dictionary = value as? [String: AnyObject] {
                return transform(dictionary)
            }
            return nil
        }
    }

    /// Registers an entity mapper with a given name and map block.
    ///
    /// An entity mapper maps a JSON dictionary to an entity name.
    ///
    /// Entity mappers can be associated with abstract core data entities in the user info
    /// dictionary by using the `entityMapperName` key.
    ///
    /// - parameter name: The name of the mapper.
    /// - parameter map:  The function that performs the mapping.
    public class func setEntityMapper(withName name: String, map: @escaping ([String: AnyObject]) -> (String?)) {
        grt_setEntityMapper(withName: name) { value in
            if let dictionary = value as? [String: AnyObject] {
                return map(dictionary)
            }
            return nil
        }
    }
}
