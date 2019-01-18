//
//  Colors.swift
//  ProtonMail - Created on 2018/8/23.
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


struct ColorManager {
    static let forLabel = [
        "#7272a7", "#cf5858", "#c26cc7", "#7569d1", "#69a9d1",
        "#5ec7b7", "#72bb75", "#c3d261", "#e6c04c", "#e6984c",
        "#8989ac", "#cf7e7e", "#c793ca", "#9b94d1", "#a8c4d5",
        "#97c9c1", "#9db99f", "#c6cd97", "#e7d292", "#dfb286"
    ]
    
    static let defaultColor = ColorManager.forLabel[0]
        
    static func getRandomColor() -> String {
        return forLabel[Int.random(in: 0..<forLabel.count)]
    }
}
