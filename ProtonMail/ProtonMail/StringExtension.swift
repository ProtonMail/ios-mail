//
//  StringExtension.swift
//  ProtonMail
//
//  Created by Diego Santiviago on 2/23/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

extension String {
    
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
        let data : NSData! = self.dataUsingEncoding(NSUTF8StringEncoding)
        let decoded = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error:  &error) as! [[String:String]]
        return decoded
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
}

