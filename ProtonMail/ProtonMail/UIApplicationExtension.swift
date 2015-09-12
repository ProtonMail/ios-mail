//
//  UIApplicationExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/21/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation



public enum UIApplicationReleaseMode: Int {
    case Unknown = 0
    case Sim = 1
    case Dev = 2
    case AdHoc = 3
    case AppStore = 4
    case Enterprise = 5
};

extension UIApplication {
    
    func getMobileProvision() -> Dictionary<String, AnyObject>? {
        struct MP {
            static var mobileProvision : Dictionary<String, AnyObject>? = nil;
        }
        
        if MP.mobileProvision == nil {
            guard let provisioningPath = NSBundle.mainBundle().pathForResource("embedded", ofType: "mobileprovision") else {
                MP.mobileProvision = Dictionary<String, String>();
                return MP.mobileProvision;
            }
            
            do {
                let binaryString = try String(contentsOfFile: provisioningPath, encoding: NSISOLatin1StringEncoding)
                let scanner : NSScanner = NSScanner(string: binaryString)
                var ok : Bool = scanner.scanUpToString("<plist" , intoString: nil)
                if !ok {
                    PMLog.D("unable to find beginning of plist");
                    //return UIApplicationReleaseUnknown;
                }
                
                var plistString : NSString?
                ok = scanner.scanUpToString("</plist>" , intoString: &plistString)
                if !ok {
                    PMLog.D("unable to find end of plist");
                    //return UIApplicationReleaseUnknown;
                }
                
                let newStr = String("\(plistString!)</plist>")
                
                PMLog.D(newStr)
                // juggle latin1 back to utf-8!
                let plistdata_latin1 : NSData = newStr.dataUsingEncoding(NSISOLatin1StringEncoding, allowLossyConversion: false)!
                
                MP.mobileProvision = try NSPropertyListSerialization.propertyListWithData(plistdata_latin1, options: NSPropertyListReadOptions(rawValue: 0), format: nil) as? Dictionary<String, AnyObject>
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
            return .Unknown
        } else if mobileProvision?.count == 0 {
            #if (arch(i386) || arch(x86_64)) && os(iOS)
                return .Sim;
                #else
                return .AppStore;
            #endif
        }
        else if self.checkProvisionsAllDevices(mobileProvision!) {
            // enterprise distribution contains ProvisionsAllDevices - true
            return .Enterprise;
        } else if self.checkProvisionsDevices(mobileProvision!) {
            // development contains UDIDs and get-task-allow is true
            // ad hoc contains UDIDs and get-task-allow is false
            let entitlements : Dictionary<String, AnyObject>? = mobileProvision!["Entitlements"] as? Dictionary<String, AnyObject>
            if (entitlements == nil) {
                return .AdHoc
            }
            let getTaskAllow = entitlements!["get-task-allow"] as? Bool ?? false
            if (getTaskAllow) {
                return .Dev;
            } else {
                return .AdHoc;
            }
        } else {
            // app store contains no UDIDs (if the file exists at all?)
            return .AppStore
        }
    }
    
    func checkProvisionsAllDevices(dict : Dictionary<String, AnyObject>) -> Bool {
        if let check : Bool = dict["ProvisionsAllDevices"] as? Bool {
            return check
        } else {
            return false
        }
    }
    
    func checkProvisionsDevices(dict : Dictionary<String, AnyObject>) -> Bool {
        if let devices : [AnyObject] = dict["ProvisionedDevices"] as? [AnyObject] {
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