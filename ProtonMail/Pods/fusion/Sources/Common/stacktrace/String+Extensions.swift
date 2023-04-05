//
//  Created by Georgiy Malyukov on 26.05.2018.
//  Copyright © 2022 Georgiy Malyukov. All rights reserved.
//
//  The MIT License
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
//
//  String+Extensions.swift
//
//  https://stackoverflow.com/questions/24092884/get-nth-character-of-a-string-in-swift-programming-language/38215613#38215613
//  Copyright © 2020 Leo Dabus. All rights reserved.
//

import Foundation

public extension StringProtocol {

    subscript(_ offset: Int) -> Element {
        self[index(startIndex, offsetBy: offset)]
    }

    subscript(_ range: Range<Int>) -> SubSequence {
        prefix(range.lowerBound + range.count).suffix(range.count)
    }

    subscript(_ range: ClosedRange<Int>) -> SubSequence {
        prefix(range.lowerBound + range.count).suffix(range.count)
    }

    subscript(_ range: PartialRangeThrough<Int>) -> SubSequence {
        prefix(range.upperBound.advanced(by: 1))
    }

    subscript(_ range: PartialRangeUpTo<Int>) -> SubSequence {
        prefix(range.upperBound)
    }

    subscript(_ range: PartialRangeFrom<Int>) -> SubSequence {
        suffix(Swift.max(0, count - range.lowerBound))
    }
}

public extension LosslessStringConvertible {

    var string: String {
        .init(self)
    }
}

public extension BidirectionalCollection {

    // swiftlint:disable all
    subscript(safe offset: Int) -> Element? {
        guard !isEmpty, let i = index(startIndex, offsetBy: offset, limitedBy: index(before: endIndex)) else {
            return nil
        }
        return self[i]
    }
    // swiftlint:enable all
}
