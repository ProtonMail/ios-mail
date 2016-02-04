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
            PMLog.D(error.description)
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
        return  self.stringByReplacingOccurrencesOfString("\n", withString:  "<br />")
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
    
    func plainText() -> String {
        
        return self;
        //        -(NSString *)convertHTML:(NSString *)html {
        //
        //            NSScanner *myScanner;
        //            NSString *text = nil;
        //            myScanner = [NSScanner scannerWithString:html];
        //
        //            while ([myScanner isAtEnd] == NO) {
        //
        //                [myScanner scanUpToString:@"<" intoString:NULL] ;
        //
        //                [myScanner scanUpToString:@">" intoString:&text] ;
        //
        //                html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];
        //            }
        //            //
        //            html = [html stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //
        //            return html;
        //        }
    }
    
    
    func stringByStrippingStyleHTML() -> String {
        
        var options = NSRegularExpressionOptions.allZeros
        options |= NSRegularExpressionOptions.CaseInsensitive
        options |= NSRegularExpressionOptions.DotMatchesLineSeparators
        
        var error:NSError?
        if let regex = NSRegularExpression(pattern: "<style[^>]*?>.*?</style>", options:options, error:&error) {
            if error == nil {
                let replacedString = regex.stringByReplacingMatchesInString(self, options: nil, range: NSRange(location: 0, length: count(self)), withTemplate: "")
                if !replacedString.isEmpty && count(replacedString) > 0 {
                    return replacedString;
                }
            }
        }
        return self
    }
    
    func preg_replace (partten: String, replaceto:String) -> String {
        var options = NSRegularExpressionOptions.allZeros
        options |= NSRegularExpressionOptions.CaseInsensitive
        options |= NSRegularExpressionOptions.DotMatchesLineSeparators
        
        var error:NSError?
        if let regex = NSRegularExpression(pattern: partten, options:options, error:&error) {
            if error == nil {
                let replacedString = regex.stringByReplacingMatchesInString(self, options: nil, range: NSRange(location: 0, length: count(self)), withTemplate: replaceto)
                if !replacedString.isEmpty && count(replacedString) > 0 {
                    return replacedString;
                }
            }
        }
        return self
    }
    
    func stringByPurifyHTML() -> String {
        var out = self.preg_replace("<script(.*?)<\\/script>", replaceto: "")
        
        out = out.preg_replace("<(\\/?meta.*?)>", replaceto: "");
        out = out.preg_replace("<(object.*?)>(.*?)<(\\/object.*?)>", replaceto: "");
        out = out.preg_replace("<(\\/?objec.*?)>", replaceto: "");
        
        //remove inline style optinal later
        out = out.preg_replace("(<[a-z ]*)(style=(\"|\')(.*?)(\"|\'))([a-z ]*>)", replaceto: "");
        out = out.preg_replace("<(\\/?link.*?)>", replaceto: "");
        
        out = out.preg_replace("<iframe(.*?)<\\/iframe>", replaceto: "");
        out = out.preg_replace("<style(.*?)<\\/style>", replaceto: "");
        out = out.preg_replace("\\s+", replaceto:" ")
        out = out.preg_replace("<[ ]+", replaceto:"<")
        out = out.preg_replace("<(style.*?)>(.*?)<(\\/style.*?)>", replaceto: "");
        out = out.preg_replace("<(\\/?style.*?)>", replaceto: "");
        out = out.preg_replace("<(script.*?)>(.*?)<(\\/script.*?)>", replaceto: "")
        out = out.preg_replace("<(\\/?script.*?)>", replaceto: "")
        out = out.preg_replace("javascript", replaceto: "Javascript")
        out = out.preg_replace("vbscript", replaceto: "Vbscript")
        out = out.preg_replace("&#", replaceto: "&＃")
        out = out.preg_replace("<(noframes.*?)>(.*?)<(\\/noframes.*?)>", replaceto: "")
        out = out.preg_replace("<(\\/?noframes.*?)>", replaceto: "")
        out = out.preg_replace("<(i?frame.*?)>(.*?)<(\\/i?frame.*?)>", replaceto: "")
        out = out.preg_replace("<(\\/?i?frame.*?)>", replaceto: "")
        
        //optional later
        out = out.preg_replace("<video(.*?)<\\/video>", replaceto: "")
        out = out.preg_replace("<audio(.*?)<\\/audio>", replaceto: "")
        
        return out;
//        function htmltotxt($str){
//            $str = preg_replace( "@<script(.*?)</script>@is", "", $str );  //过滤js
//            $str = preg_replace( "@<iframe(.*?)</iframe>@is", "", $str ); //过滤frame
//            $str = preg_replace( "@<style(.*?)</style>@is", "", $str ); //过滤css
//            $str = preg_replace( "@<(.*?)>@is", "", $str ); //过滤标签
//            $str=preg_replace("/\s+/", " ", $str); //过滤多余回车
//            $str=preg_replace("/<[ ]+/si","<",$str); //过滤<__("<"号后面带空格)
//            $str=preg_replace("/<\!–.*?–>/si","",$str); //注释
//            $str=preg_replace("/<(\!.*?)>/si","",$str); //过滤DOCTYPE
//            $str=preg_replace("/<(\/?html.*?)>/si","",$str); //过滤html标签
//            $str=preg_replace("/<(\/?head.*?)>/si","",$str); //过滤head标签
//            $str=preg_replace("/<(\/?meta.*?)>/si","",$str); //过滤meta标签
//            $str=preg_replace("/<(\/?body.*?)>/si","",$str); //过滤body标签
//            $str=preg_replace("/<(\/?link.*?)>/si","",$str); //过滤link标签
//            $str=preg_replace("/<(\/?form.*?)>/si","",$str); //过滤form标签
//            $str=preg_replace("/cookie/si","COOKIE",$str); //过滤COOKIE标签
//            $str=preg_replace("/<(applet.*?)>(.*?)<(\/applet.*?)>/si","",$str); //过滤applet标签
//            $str=preg_replace("/<(\/?applet.*?)>/si","",$str); //过滤applet标签
//            $str=preg_replace("/<(style.*?)>(.*?)<(\/style.*?)>/si","",$str); //过滤style标签
//            $str=preg_replace("/<(\/?style.*?)>/si","",$str); //过滤style标签
//            $str=preg_replace("/<(title.*?)>(.*?)<(\/title.*?)>/si","",$str); //过滤title标签
//            $str=preg_replace("/<(\/?title.*?)>/si","",$str); //过滤title标签
//            $str=preg_replace("/<(object.*?)>(.*?)<(\/object.*?)>/si","",$str); //过滤object标签
//            $str=preg_replace("/<(\/?objec.*?)>/si","",$str); //过滤object标签
//            $str=preg_replace("/<(noframes.*?)>(.*?)<(\/noframes.*?)>/si","",$str); //过滤noframes标签
//            $str=preg_replace("/<(\/?noframes.*?)>/si","",$str); //过滤noframes标签
//            $str=preg_replace("/<(i?frame.*?)>(.*?)<(\/i?frame.*?)>/si","",$str); //过滤frame标签
//            $str=preg_replace("/<(\/?i?frame.*?)>/si","",$str); //过滤frame标签
//            $str=preg_replace("/<(script.*?)>(.*?)<(\/script.*?)>/si","",$str); //过滤script标签
//            $str=preg_replace("/<(\/?script.*?)>/si","",$str); //过滤script标签
//            $str=preg_replace("/javascript/si","Javascript",$str); //过滤script标签 
//            $str=preg_replace("/vbscript/si","Vbscript",$str); //过滤script标签 
//            $str=preg_replace("/on([a-z]+)\s*=/si","On\\1=",$str); //过滤script标签 
//            $str=preg_replace("/&#/si","&＃",$str); //过滤script标签，如javAsCript:alert(
//            return $str;
//        }
    }
    
    func stringByStrippingBodyStyle() -> String {
        var options = NSRegularExpressionOptions.allZeros
        options |= NSRegularExpressionOptions.CaseInsensitive
        options |= NSRegularExpressionOptions.DotMatchesLineSeparators
        
        var error:NSError?
        if let regexBody = NSRegularExpression(pattern: "<body[^>]*>", options:options, error:&error) {
            if error == nil {
                let matches = regexBody.matchesInString(self, options: nil, range: NSRange(location: 0, length: count(self))) as! [NSTextCheckingResult]
                if let first = matches.first {
                    if first.numberOfRanges > 0 {
                        let range = first.rangeAtIndex(0)
                        if let nRange = self.rangeFromNSRange(range) {
                            var bodyTag = self.substringWithRange(nRange)
                            if !bodyTag.isEmpty && count(bodyTag) > 0  {
                                if let regexStyle = NSRegularExpression(pattern: "style=\"[^\"]*\"", options:options, error:&error) {
                                    if error == nil {
                                        bodyTag = regexStyle.stringByReplacingMatchesInString(bodyTag, options: nil, range: NSRange(location: 0, length: count(bodyTag)), withTemplate: "")
                                        if !bodyTag.isEmpty && count(bodyTag) > 0  {
                                            let newBody = self.stringByReplacingCharactersInRange(nRange, withString: bodyTag);
                                            if !newBody.isEmpty && count(newBody) > 0  {
                                                return newBody
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
        }
        return self
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
    
    func rangeFromNSRange(nsRange : NSRange) -> Range<String.Index>? {
        let from16 = advance(utf16.startIndex, nsRange.location, utf16.endIndex)
        let to16 = advance(from16, nsRange.length, utf16.endIndex)
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
                return from ..< to
        }
        return nil
    }
    
    func NSRangeFromRange(range : Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = String.UTF16View.Index(range.startIndex, within: utf16view)
        let to = String.UTF16View.Index(range.endIndex, within: utf16view)
        return NSMakeRange(from - utf16view.startIndex, to - from)
    }
    
    func RangeFromNSRange(range: Range<Int>) -> Range<String.Index> {
        let startIndex = advance(self.startIndex, range.startIndex)
        let endIndex = advance(startIndex, range.endIndex - range.startIndex)
        return Range<String.Index>(start: startIndex, end: endIndex)
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
    
    //
    func toContacts() -> [ContactVO] {
        var out : [ContactVO] = [ContactVO]();
        let recipients : [[String : String]] = self.parseJson()!
        for dict:[String : String] in recipients {
            out.append(ContactVO(id: "", name: dict["Name"], email: dict["Address"]))
        }
        return out
    }
    
}


extension String {
    
    subscript (i: Int) -> Character {
        return self[advance( self.startIndex, i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: advance(startIndex, r.endIndex), end: advance(startIndex, r.endIndex)))
    }
}
