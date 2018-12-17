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
    internal func contains(label: Location) -> Bool {
        return self.contains(label: label.rawValue)
    }
    
    internal func contains(label labelID : String) -> Bool {
        let labels = self.labels
        for l in labels {
            if let label = l as? Label, labelID == label.labelID {
                return true
            }
        }
        return false
    }
    
    var starred : Bool {
        get {
            return self.contains(label: Location.starred)
        }
    }
    
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
    
    var draft : Bool {
        get {
            return self.contains(label: Location.draft)
        }
    }
    
    
    //    var sendOrDraft : Bool {
    //        get {
    //            if self.flag.contains(.rece) || self.flag.contains(.sent) {
    //                return true
    //            }
    //            return false
    //        }
    //
    //    }
    //    func hasDraftLabel() -> Bool {
    //        let labels = self.labels
    //        for l in labels {
    //            if let label = l as? Label {
    //                if let l_id = Int(label.labelID) {
    //                    if let new_loc = MessageLocation(rawValue: l_id), new_loc == .draft {
    //                        return true
    //                    }
    //                }
    //
    //            }
    //        }
    //        return false
    //    }
    //
    //    func hasLocation(location : MessageLocation) -> Bool {
    //        for l in getLocationFromLabels() {
    //            if l == location {
    //                return true
    //            }
    //        }
    //        return false
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
