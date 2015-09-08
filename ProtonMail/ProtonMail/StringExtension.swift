//
//  StringExtension.swift
//  ProtonMail
//
//  Created by Diego Santiviago on 2/23/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

extension String {
    
    func alertController() -> UIAlertController {
        var message = self
        return UIAlertController(title: "Alert", message: message, preferredStyle: .Alert)
    }

    
    func contains(s: String) -> Bool
    {
        return self.rangeOfString(s, options: NSStringCompareOptions.CaseInsensitiveSearch) != nil ? true : false
        //return (self.rangeOfString(s) != nil) ? true : false
    }
    
    func isMatch(regex: String, options: NSRegularExpressionOptions) -> Bool
    {
        var error: NSError?
        var exp = NSRegularExpression(pattern: regex, options: options, error: &error)
        
        if let error = error {
            println(error.description)
        }
        var matchCount = exp?.numberOfMatchesInString(self, options: nil, range: NSMakeRange(0, count(self)))
        return matchCount > 0
    }
    
    
    func hasRe () -> Bool {
        if count(self) < 3 {
            return false;
        }
        let myNSString = self as NSString
        let str = myNSString.substringWithRange(NSRange(location: 0, length: 3))
        return str.contains("Re:")
    }
    
    func hasFwd () -> Bool {
        if count(self) < 4 {
            return false;
        }
        let myNSString = self as NSString
        let str = myNSString.substringWithRange(NSRange(location: 0, length: 4))
        return str.contains("Fwd:")
    }

    
    /**
    String extension check is email valid use the basic regex
    
    :returns: true | false
    */
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        if let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx) as NSPredicate? {
            return emailTest.evaluateWithObject(self)
        }
        return false
    }
    
    /**
    String extension for remove the whitespaces begain&end
    
        Example: 
        " adsf " => "ads"
    
    :returns: trimed string value
    */
    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
    }
    
    
    /**
    String extension parse a json string to a list of dict
    
    :returns: [ [String:String] ]
    */
    func parseJson() -> [[String:String]]? {
        var error: NSError?
        if self.isEmpty {
            return [];
        }
        
        let data : NSData! = self.dataUsingEncoding(NSUTF8StringEncoding)
        let decoded = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error:  &error) as! [[String:String]]
        return decoded
    }
    
    
    /**
    get display address for message details
    
    :returns: parsed address
    */
    func getDisplayAddress() -> String {
        var lists: [String] = []
        let recipients : [[String : String]] = self.parseJson()!
        for dict:[String : String] in recipients {
            let to = dict.getDisplayName()
            if !to.isEmpty  {
                lists.append(to)
            }
        }
        return ",".join(lists)
    }
    

    
    /**
    String extension split a string by comma
        
    Example:
    "a,b,c,d" => ["a","b","c","d"]
    
    :returns: [String]
    */
    func splitByComma() -> [String] {
        return split(self) {$0 == ","}
    }
    
    
    func ln2br() -> String {
        return  self.stringByReplacingOccurrencesOfString("\n", withString:  "<br>") 
    }
    
    
    /**
    String extension formating the Json format contact for forwarding email.
    
    :returns: String
    */
    func formatJsonContact() -> String {
        var lists: [String] = []
        
        let recipients : [[String : String]] = self.parseJson()!
        for dict:[String : String] in recipients {
            let name = dict.getName()
            
            lists.append(dict.getName() + "&lt;\(dict.getAddress())&gt;")
        }
        return ",".join(lists)
    }
    
    /**
    String extension decode some encoded htme tags
    
    :returns: String
    */
    func decodeHtml() -> String {
        var result = self.stringByReplacingOccurrencesOfString("&amp;", withString: "&", options: nil, range: nil)
        result = result.stringByReplacingOccurrencesOfString("&quot;", withString: "\"", options: nil, range: nil)
        result = result.stringByReplacingOccurrencesOfString("&#039;", withString: "'", options: nil, range: nil)
        result = result.stringByReplacingOccurrencesOfString("&#39;", withString: "'", options: nil, range: nil)
        result = result.stringByReplacingOccurrencesOfString("&lt;", withString: "<", options: nil, range: nil)
        result = result.stringByReplacingOccurrencesOfString("&gt;", withString: ">", options: nil, range: nil)
        return result
//        let encodedData = self.dataUsingEncoding(NSUTF8StringEncoding)!
//        let attributedOptions : [String: AnyObject] = [
//            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
//            NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
//        ]
//        let attributedString = NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil, error: nil)!
//        return attributedString.string
    }
    
    func encodeHtml() -> String {
        var result = self.stringByReplacingOccurrencesOfString("&", withString: "&amp;", options: nil, range: nil)
        result = result.stringByReplacingOccurrencesOfString("\"", withString: "&quot;", options: nil, range: nil)
        result = result.stringByReplacingOccurrencesOfString("'", withString: "&#039;", options: nil, range: nil)
        result = result.stringByReplacingOccurrencesOfString("<", withString: "&lt;", options: nil, range: nil)
        result = result.stringByReplacingOccurrencesOfString(">", withString: "&gt;", options: nil, range: nil)
        return result
        
    }
    
    static func randomString(len:Int) -> String {
        let charSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var c = Array(charSet)
        var s:String = ""
        for n in (1...len) {
            
            let index : Int = Int(UInt32(arc4random()) % UInt32(c.count))
            
            s.append(c[index])
        }
        return s
    }
    
    func encodeBase64() -> String {
        
        //let utf8str: NSData = self.dataUsingEncoding(NSUTF8StringEncoding)
        let utf8str = self.dataUsingEncoding(NSUTF8StringEncoding)
        
        //let base64Encoded:NSString = utf8str.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.fromRaw(0)!)
        let base64Encoded = utf8str!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        
        return base64Encoded
//        let data: NSData = NSData(base64EncodedString: base64Encoded, options: NSDataBase64DecodingOptions.fromRaw(0)!)
//        let data = NSData(base64EncodedString: base64Encoded, options: NSDataBase64DecodingOptions.fromRaw(0)!)
//        
//        let base64Decoded: NSString = NSString(data: data, encoding: NSUTF8StringEncoding)
//        let base64Decoded = NSString(data: data, encoding: NSUTF8StringEncoding)
    }
}

