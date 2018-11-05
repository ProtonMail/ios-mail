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
        
        static let received    = RefreshStatus(rawValue: 1 << 0 ) //const FLAG_RECEIVED = 1;
        static let sent        = RefreshStatus(rawValue: 1 << 1 ) //const FLAG_SENT = 2;
        static let `internal`  = RefreshStatus(rawValue: 1 << 2 ) //const FLAG_INTERNAL = 4;
        static let e2e         = RefreshStatus(rawValue: 1 << 3 ) //const FLAG_E2E = 8;
        
        static let auto        = RefreshStatus(rawValue: 1 << 4 ) //const FLAG_AUTO = 16;
        static let replied     = RefreshStatus(rawValue: 1 << 5 ) //const FLAG_REPLIED = 32;
        static let repliedAll  = RefreshStatus(rawValue: 1 << 6 ) //const FLAG_REPLIEDALL = 64;
        static let forwarded   = RefreshStatus(rawValue: 1 << 7 ) //const FLAG_FORWARDED = 128;
        
        static let autoReplied = RefreshStatus(rawValue: 1 << 8 ) //const FLAG_AUTOREPLIED = 256;
        static let imported    = RefreshStatus(rawValue: 1 << 9 ) //const FLAG_IMPORTED = 512;
        static let opened      = RefreshStatus(rawValue: 1 << 10) //const FLAG_OPENED = 1024;
        static let receipt     = RefreshStatus(rawValue: 1 << 11) //const FLAG_RECEIPT = 2048;
        static let spam        = RefreshStatus(rawValue: 1 << 12) //const FLAG_SPAM = 4096;
        static let phishing    = RefreshStatus(rawValue: 1 << 13) //const FLAG_PHISHING = 8192;
    }
    
    
    var flag : Flag {
        return Flag(rawValue: 0)
    }

}
