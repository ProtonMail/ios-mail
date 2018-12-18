//
//  PushData.swift
//  ProtonMail - Created on 12/13/17.
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

public struct PushData: Codable {
    let badge: Int
    let body: String
    let sender: Sender
    let messageId: String
    // Unused on iOS fields:
    //    let title: String
    //    let subtitle: String
    //    let vibrate: Int
    //    let sound: Int
    //    let largeIcon: String
    //    let smallIcon: String
    
    
    static func parse(with json: String) -> PushData? {
        guard let data = json.data(using: .utf8),
            let push = try? JSONDecoder().decode(Push.self, from: data) else
        {
            return nil
        }
        return push.data
    }
}

public struct Push: Codable {
    let data: PushData
    // Unused on iOS fields
    //    let type: String
    //    let version: Int
}
