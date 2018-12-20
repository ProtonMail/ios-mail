//
//  Message+Var+Extension.swift
//  ProtonMail - Created on 11/6/18.
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
    
    /// wrappers
    var cachedPassphrase: String? {
        get {
            guard let raw = self.cachedPassphraseRaw as Data? else { return nil }
            return String(data: raw, encoding: .utf8)
        }
        set { self.cachedPassphraseRaw = newValue?.data(using: .utf8) as NSData? }
    }
    
    var cachedAuthCredential: AuthCredential? {
        get { return AuthCredential.unarchive(data: self.cachedAuthCredentialRaw) }
        set { self.cachedAuthCredentialRaw = newValue?.archive() as NSData? }
    }
    var cachedPrivateKeys: Data? {
        get { return self.cachedPrivateKeysRaw as Data? }
        set { self.cachedPrivateKeysRaw = newValue as NSData? }
    }
    var cachedAddress: Address? {
        get { return Address.unarchive(self.cachedAddressRaw as Data?) }
        set { self.cachedAddressRaw = newValue?.archive() as NSData? }
    }
    
    
    
    /// check if contains exclusive lable
    ///
    /// - Parameter label: Location
    /// - Returns: yes or no
    internal func contains(label: Location) -> Bool {
        return self.contains(label: label.rawValue)
    }
    
    /// check if contains the lable
    ///
    /// - Parameter labelID: label id
    /// - Returns: yes or no
    internal func contains(label labelID : String) -> Bool {
        let labels = self.labels
        for l in labels {
            if let label = l as? Label, labelID == label.labelID {
                return true
            }
        }
        return false
    }
    
    /// check if message starred
    var starred : Bool {
        get {
            return self.contains(label: Location.starred)
        }
    }
    
    /// check if message forwarded
    var forwarded : Bool {
        get {
            return self.flag.contains(.forwarded)
        }
        set {
            var flag = self.flag
            if newValue {
                flag.remove(.forwarded)
            } else {
                flag.insert(.forwarded)
            }
            self.flag = flag
        }
    }
    
    /// check if message contains a draft label
    var draft : Bool {
        get {
            return self.contains(label: Location.draft)
        }
    }
    
    /// get all labelIDs for moving messages
    var labelIDs : [String] {
        var labelIDs = [String]()
        let labels = self.labels
        for l in labels {
            if let label = l as? Label {
                labelIDs.append(label.labelID)
            }
        }
        return labelIDs
    }
    
    /// check if message replied
    var replied : Bool {
        get {
            return self.flag.contains(.replied)
        }
        set {
            var flag = self.flag
            if newValue {
                flag.remove(.replied)
            } else {
                flag.insert(.replied)
            }
            self.flag = flag
        }
    }
    
    /// check if message replied to all
    var repliedAll : Bool {
        get {
            return self.flag.contains(.repliedAll)
        }
        set {
            var flag = self.flag
            if newValue {
                flag.remove(.repliedAll)
            } else {
                flag.insert(.repliedAll)
            }
            self.flag = flag
        }
    }

    
}







//    var sendOrDraft : Bool {
//        get {
//            if self.flag.contains(.rece) || self.flag.contains(.sent) {
//                return true
//            }
//            return false
//        }
//    }
//
//    func getLocationFromLabels() ->  [MessageLocation] {
//        var locations = [MessageLocation]()
//        let labels = self.labels
//        for l in labels {
//            if let label = l as? Label {
//                if let l_id = Int(label.labelID) {
//                    if let new_loc = MessageLocation(rawValue: l_id), new_loc != .starred && new_loc != .allmail {
//                        locations.append(new_loc)
//                    }
//                }
//
//            }
//        }
//        return locations
//    }

