//
//  UIApplication+InfoExtension.swift
//  ProtonMail - Created on 8/21/15.
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

enum UIApplicationReleaseMode: Int {
    case unknown = 0
    case sim = 1
    case dev = 2
    case adHoc = 3
    case appStore = 4
    case enterprise = 5
};

extension UIApplication {
    
    func getMobileProvision() -> [String : Any]? {
        struct MP {
            static var mobileProvision : [String : Any]? = nil;
        }
        
        if MP.mobileProvision == nil {
            guard let provisioningPath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") else {
                MP.mobileProvision = [String : String]() as [String : Any]?;
                return MP.mobileProvision;
            }
            
            do {
                let binaryString = try String(contentsOfFile: provisioningPath, encoding: String.Encoding.isoLatin1)
                let scanner : Scanner = Scanner(string: binaryString)
                var ok : Bool = scanner.scanUpTo("<plist" , into: nil)
                if !ok {
                    PMLog.D("unable to find beginning of plist");
                    //return UIApplicationReleaseUnknown;
                }
                
                var plistString : NSString?
                ok = scanner.scanUpTo("</plist>" , into: &plistString)
                if !ok {
                    PMLog.D("unable to find end of plist");
                    //return UIApplicationReleaseUnknown;
                }
                let newStr = String("\(plistString!)</plist>")
                // juggle latin1 back to utf-8!
                let plistdata_latin1 : Data = newStr.data(using: String.Encoding.isoLatin1, allowLossyConversion: false)!
                
                MP.mobileProvision = try PropertyListSerialization.propertyList(from: plistdata_latin1, options: PropertyListSerialization.ReadOptions(rawValue: 0), format: nil) as? [String : Any]
            } catch {
                PMLog.D("error parsing extracted plist — \(error)");
                MP.mobileProvision = nil;
                return nil;
            }
        }
        return MP.mobileProvision
    }
    
    
    func releaseMode() -> UIApplicationReleaseMode {
    
        let mobileProvision = self.getMobileProvision()
        if mobileProvision == nil {
            // failure to read other than it simply not existing
            return .unknown
        } else if mobileProvision?.count == 0 {
            #if targetEnvironment(simulator)
                return .sim;
            #else
                return .appStore;
            #endif
        }
        else if self.checkProvisionsAllDevices(mobileProvision!) {
            // enterprise distribution contains ProvisionsAllDevices - true
            return .enterprise;
        } else if self.checkProvisionsDevices(mobileProvision!) {
            // development contains UDIDs and get-task-allow is true
            // ad hoc contains UDIDs and get-task-allow is false
            let entitlements : [String : Any]? = mobileProvision!["Entitlements"] as? [String : Any]
            if (entitlements == nil) {
                return .adHoc
            }
            let getTaskAllow = entitlements!["get-task-allow"] as? Bool ?? false
            if (getTaskAllow) {
                return .dev;
            } else {
                return .adHoc;
            }
        } else {
            // app store contains no UDIDs (if the file exists at all?)
            return .appStore
        }
    }
    
    func checkProvisionsAllDevices(_ dict : [String : Any]) -> Bool {
        if let check : Bool = dict["ProvisionsAllDevices"] as? Bool {
            return check
        } else {
            return false
        }
    }
    
    func checkProvisionsDevices(_ dict : [String : Any]) -> Bool {
        if let devices : [Any] = dict["ProvisionedDevices"] as? [Any] {
            if devices.count > 0 {
                return true
            } else {
                return false;
            }
        } else {
            return false
        }
    }
}
