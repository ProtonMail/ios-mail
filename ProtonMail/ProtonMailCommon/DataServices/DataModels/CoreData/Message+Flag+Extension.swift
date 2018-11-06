//
//  Message+Flag+Extension.swift
//  ProtonMail - Created on 11/5/18.
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


extension Message {
    /// Flags
    struct Flag : OptionSet {
        let rawValue: Int
        
        static let received    = Flag(rawValue: 1 << 0 ) //const FLAG_RECEIVED = 1;
        static let sent        = Flag(rawValue: 1 << 1 ) //const FLAG_SENT = 2;
        static let `internal`  = Flag(rawValue: 1 << 2 ) //const FLAG_INTERNAL = 4;
        static let e2e         = Flag(rawValue: 1 << 3 ) //const FLAG_E2E = 8;
        
        static let auto        = Flag(rawValue: 1 << 4 ) //const FLAG_AUTO = 16;
        static let replied     = Flag(rawValue: 1 << 5 ) //const FLAG_REPLIED = 32;
        static let repliedAll  = Flag(rawValue: 1 << 6 ) //const FLAG_REPLIEDALL = 64;
        static let forwarded   = Flag(rawValue: 1 << 7 ) //const FLAG_FORWARDED = 128;
        
        static let autoReplied = Flag(rawValue: 1 << 8 ) //const FLAG_AUTOREPLIED = 256;
        static let imported    = Flag(rawValue: 1 << 9 ) //const FLAG_IMPORTED = 512;
        static let opened      = Flag(rawValue: 1 << 10) //const FLAG_OPENED = 1024;
        static let receipt     = Flag(rawValue: 1 << 11) //const FLAG_RECEIPT = 2048;
        static let spam        = Flag(rawValue: 1 << 12) //const FLAG_SPAM = 4096;
        static let phishing    = Flag(rawValue: 1 << 13) //const FLAG_PHISHING = 8192;
        
        var description : String {
            var out = "Raw: \(rawValue)\n"
            if self.contains(.received) {
                out += "FLAG_RECEIVED = 1\n"
            }
            if self.contains(.sent) {
                out += "FLAG_SENT = 2\n"
            }
            if self.contains(.internal) {
                out += "FLAG_INTERNAL = 4\n"
            }
            if self.contains(.e2e) {
                out += "FLAG_E2E = 8\n"
            }
            
            if self.contains(.auto) {
                out += "FLAG_AUTO = 16\n"
            }
            if self.contains(.replied) {
                out += "FLAG_REPLIED = 32\n"
            }
            if self.contains(.repliedAll) {
                out += "FLAG_REPLIEDALL = 64\n"
            }
            if self.contains(.forwarded) {
                out += "FLAG_FORWARDED = 128\n"
            }
            
            if self.contains(.autoReplied) {
                out += "FLAG_AUTOREPLIED = 256\n"
            }
            if self.contains(.imported) {
                out += "FLAG_IMPORTED = 512\n"
            }
            if self.contains(.opened) {
                out += "FLAG_OPENED = 1024\n"
            }
            if self.contains(.receipt) {
                out += "FLAG_RECEIPT = 2048\n"
            }
            if self.contains(.spam) {
                out += "FLAG_SPAM = 4096\n"
            }
            if self.contains(.phishing) {
                out += "FLAG_PHISHING = 8192\n"
            }
            return out
        }
    }
    var flag : Flag {
        return Flag(rawValue: self.flags.intValue)
    }
}
